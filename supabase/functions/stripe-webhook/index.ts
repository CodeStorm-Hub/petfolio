// Supabase Edge Function — stripe-webhook
//
// Receives and verifies Stripe webhook events. This endpoint has NO Supabase
// JWT auth — Stripe's HMAC signature is the authentication mechanism.
//
// Events handled:
//   account.updated          → sets shops.is_verified = true when a Connect
//                              Express account completes KYC
//   payment_intent.succeeded → updates marketplace_orders.status to 'processing'
//   payment_intent.payment_failed → updates status to 'cancelled'
//
// Stripe registration:
//   1. Platform webhook (payment events):
//      URL: https://<project>.supabase.co/functions/v1/stripe-webhook
//      Events: payment_intent.succeeded, payment_intent.payment_failed
//
//   2. Connect webhook (vendor account events):
//      Same URL, but registered as a "Connect" endpoint in the Stripe Dashboard
//      under Connect > Webhooks > "Listen to events on connected accounts".
//      Events: account.updated
//      Stripe sends a top-level `account` field on Connect events; this
//      function handles both platform and Connect events at the same URL.
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

serve(async (req) => {
  // ── Step 1: Verify Stripe signature — NEVER skip this ────────────────────
  // Two secrets because platform and Connect webhooks are separate endpoints
  // and Stripe signs each with a different secret. We try the platform secret
  // first; if it fails we try the Connect secret so both endpoint types are
  // handled at this single URL.
  const body = await req.text();
  const sig = req.headers.get('stripe-signature') ?? '';
  const platformSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';
  const connectSecret  = Deno.env.get('STRIPE_CONNECT_WEBHOOK_SECRET') ?? '';

  let event: Stripe.Event;
  try {
    try {
      event = await stripe.webhooks.constructEventAsync(body, sig, platformSecret);
    } catch {
      event = await stripe.webhooks.constructEventAsync(body, sig, connectSecret);
    }
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return new Response('Webhook signature invalid', { status: 400 });
  }

  // ── Step 2: Service role client for all DB writes ─────────────────────────
  // Webhook runs without a user JWT so we use the service role to bypass RLS.
  // is_verified and status fields are intentionally NOT writable by end users
  // via RLS — only service role (i.e. this webhook) can set them.
  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  // ── Step 3: Handle events ─────────────────────────────────────────────────
  try {
    switch (event.type) {

      case 'account.updated': {
        // Fired when a Connect Express account's KYC state changes.
        // Only flip is_verified when Stripe confirms both:
        //   details_submitted — user completed all required fields
        //   charges_enabled   — account is cleared to accept payments
        const account = event.data.object as Stripe.Account;
        if (account.details_submitted && account.charges_enabled) {
          const { error } = await admin
            .from('shops')
            .update({
              is_verified: true,
              stripe_onboarding_complete: true,
              updated_at: new Date().toISOString(),
            })
            .eq('stripe_connect_account_id', account.id);

          if (error) {
            console.error('account.updated: DB update failed', error);
            // Return 500 so Stripe retries this event.
            return new Response('DB update failed', { status: 500 });
          }
        }
        break;
      }

      case 'payment_intent.succeeded': {
        // Fired after a buyer's payment is captured. Move the order from
        // 'pending' to 'processing' (paid, awaiting vendor fulfillment).
        // The .eq('status', 'pending') guard makes this idempotent — if the
        // webhook fires more than once the second UPDATE is a no-op.
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
        // Fired when a payment attempt fails (card declined, insufficient funds, etc.).
        // Cancel the pending order row so the buyer can see it failed.
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
        // Acknowledge all other event types without processing them.
        // Returning 2xx prevents Stripe from retrying unhandled events.
        break;
    }
  } catch (err) {
    console.error('Webhook handler error:', err);
    // Return 500 for unexpected errors so Stripe retries.
    return new Response('Handler error', { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
