// Supabase Edge Function — stripe-webhook
//
// Receives and verifies Stripe webhook events. No Supabase JWT — Stripe HMAC only.
//
// Two Stripe Dashboard endpoints should point at this URL:
//   • Platform: payment_intent.succeeded, payment_intent.payment_failed
//     → signed with STRIPE_WEBHOOK_SECRET
//   • Connect: account.updated (Listen to events on Connected accounts)
//     → signed with STRIPE_CONNECT_WEBHOOK_SECRET
//
// Deploy: npx supabase functions deploy stripe-webhook
// Secrets: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_CONNECT_WEBHOOK_SECRET

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2024-04-10',
  httpClient: Stripe.createFetchHttpClient(),
});

const CONNECT_EVENT_TYPES = new Set([
  'account.updated',
  'account.application.authorized',
  'account.application.deauthorized',
  'account.external_account.created',
  'account.external_account.updated',
  'account.external_account.deleted',
  'capability.updated',
]);

const PLATFORM_EVENT_TYPES = new Set([
  'payment_intent.succeeded',
  'payment_intent.payment_failed',
]);

type WebhookRoute = 'connect' | 'platform';

function routeWebhook(payload: Record<string, unknown>): WebhookRoute {
  const type = typeof payload.type === 'string' ? payload.type : '';

  if (CONNECT_EVENT_TYPES.has(type)) return 'connect';
  if (PLATFORM_EVENT_TYPES.has(type)) return 'platform';

  if (typeof payload.account === 'string' && payload.account.startsWith('acct_')) {
    return 'connect';
  }

  return 'platform';
}

async function constructVerifiedEvent(
  body: string,
  signature: string,
  route: WebhookRoute,
): Promise<Stripe.Event> {
  const platformSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';
  const connectSecret = Deno.env.get('STRIPE_CONNECT_WEBHOOK_SECRET') ?? '';

  const primary = route === 'connect' ? connectSecret : platformSecret;
  const fallback = route === 'connect' ? platformSecret : connectSecret;

  if (!primary) {
    throw new Error(
      route === 'connect'
        ? 'STRIPE_CONNECT_WEBHOOK_SECRET is not configured'
        : 'STRIPE_WEBHOOK_SECRET is not configured',
    );
  }

  try {
    return await stripe.webhooks.constructEventAsync(body, signature, primary);
  } catch (primaryErr) {
    if (!fallback) throw primaryErr;
    try {
      console.warn(
        `Primary ${route} secret failed for routed event; trying alternate secret`,
      );
      return await stripe.webhooks.constructEventAsync(body, signature, fallback);
    } catch {
      throw primaryErr;
    }
  }
}

serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature') ?? '';

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(body) as Record<string, unknown>;
  } catch {
    return new Response('Invalid JSON body', { status: 400 });
  }

  const route = routeWebhook(payload);

  let event: Stripe.Event;
  try {
    event = await constructVerifiedEvent(body, sig, route);
  } catch (err) {
    console.error(`Webhook signature verification failed (${route}):`, err);
    return new Response('Webhook signature invalid', { status: 400 });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  try {
    switch (event.type) {
      case 'account.updated': {
        if (route !== 'connect') {
          console.warn(
            `account.updated verified as ${route}; expected connect route`,
          );
        }

        const account = event.data.object as Stripe.Account;
        const connectAccountId =
          (typeof event.account === 'string' && event.account) || account.id;

        const ready =
          account.charges_enabled === true &&
          account.payouts_enabled === true;

        if (!ready) {
          console.log(
            `account.updated ${connectAccountId}: not ready (charges=${account.charges_enabled}, payouts=${account.payouts_enabled})`,
          );
          break;
        }

        const { data, error } = await admin
          .from('shops')
          .update({
            is_verified: true,
            stripe_onboarding_complete: true,
            updated_at: new Date().toISOString(),
          })
          .eq('stripe_connect_account_id', connectAccountId)
          .select('id');

        if (error) {
          console.error('account.updated: DB update failed', error);
          return new Response('DB update failed', { status: 500 });
        }

        if (!data?.length) {
          console.warn(
            `account.updated: no shop row for stripe_connect_account_id=${connectAccountId}`,
          );
        } else {
          console.log(
            `account.updated: verified shop(s) ${data.map((r) => r.id).join(', ')}`,
          );
        }
        break;
      }

      case 'payment_intent.succeeded': {
        const pi = event.data.object as Stripe.PaymentIntent;
        const orderId = pi.metadata?.order_id;
        if (!orderId) break;

        const { error } = await admin
          .from('marketplace_orders')
          .update({ status: 'processing' })
          .eq('id', orderId)
          .eq('status', 'pending');

        if (error) {
          console.error('payment_intent.succeeded: DB update failed', error);
          return new Response('DB update failed', { status: 500 });
        }
        break;
      }

      case 'payment_intent.payment_failed': {
        const pi = event.data.object as Stripe.PaymentIntent;
        const orderId = pi.metadata?.order_id;
        if (!orderId) break;

        const { error } = await admin
          .from('marketplace_orders')
          .update({ status: 'cancelled' })
          .eq('id', orderId)
          .eq('status', 'pending');

        if (error) {
          console.error('payment_intent.payment_failed: DB update failed', error);
          return new Response('DB update failed', { status: 500 });
        }
        break;
      }

      default:
        break;
    }
  } catch (err) {
    console.error('Webhook handler error:', err);
    return new Response('Handler error', { status: 500 });
  }

  return new Response(JSON.stringify({ received: true, route }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
