// Supabase Edge Function — create-payment-intent
//
// Called by Flutter CheckoutNotifier after a pending order row is inserted.
// Returns a Stripe PaymentIntent client_secret so the Flutter SDK can present
// the Payment Sheet.
//
// For vendor orders (order.shop_id is set) the PaymentIntent uses Stripe
// Destination Charges: the platform collects the full amount, retains
// application_fee_amount, and Stripe automatically transfers the remainder
// to the vendor's Connected Express account.
//
// For the PetFolio Official shop (platform_fee_percent = 0 and no
// stripe_connect_account_id) the PaymentIntent is created as a standard
// platform charge with no transfer.
//
// Idempotency: if the order already has a stripe_payment_intent_id we fetch
// that PaymentIntent and return the existing client_secret instead of
// creating a duplicate charge.
//
// Deploy: npx supabase functions deploy create-payment-intent
// Secrets: STRIPE_SECRET_KEY  (set via `npx supabase secrets set`)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Stripe from 'https://esm.sh/stripe@14?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2024-04-10',
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── Auth: require a valid Supabase JWT ──────────────────────────────────
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
      },
    );

    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    // ── Parse request body ───────────────────────────────────────────────────
    const { orderId } = await req.json() as { orderId: string };
    if (!orderId) {
      return json({ error: 'orderId is required' }, 400);
    }

    // ── Load order via service role (bypasses RLS) ───────────────────────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: order, error: orderErr } = await admin
      .from('marketplace_orders')
      .select('id, amount_cents, currency, buyer_id, shop_id, stripe_payment_intent_id')
      .eq('id', orderId)
      .single();

    if (orderErr || !order) {
      return json({ error: 'Order not found' }, 404);
    }

    // ── Security: caller must own this order ─────────────────────────────────
    if (order.buyer_id !== user.id) {
      return json({ error: 'Forbidden' }, 403);
    }

    // ── Load shop via service role ────────────────────────────────────────────
    // stripe_connect_account_id and platform_fee_percent are read here
    // server-side and never sent back to the Flutter client.
    const { data: shop, error: shopErr } = await admin
      .from('shops')
      .select('id, stripe_connect_account_id, platform_fee_percent, is_verified')
      .eq('id', order.shop_id)
      .single();

    if (shopErr || !shop) {
      return json({ error: 'Shop not found for this order' }, 404);
    }

    // ── Verify the shop can receive payments ─────────────────────────────────
    // PetFolio Official has is_verified=true but no stripe_connect_account_id —
    // that branch is intentional (platform-only charge, no transfer).
    // Third-party vendor shops must have both is_verified=true AND a connected
    // account before we can route funds to them.
    const isVendorShop = shop.stripe_connect_account_id !== null;
    if (isVendorShop && !shop.is_verified) {
      return json(
        { error: 'This seller has not completed payment setup', code: 'SHOP_NOT_VERIFIED' },
        422,
      );
    }

    // ── Idempotency: return existing PI if one already exists ─────────────────
    if (order.stripe_payment_intent_id) {
      const existing = await stripe.paymentIntents.retrieve(order.stripe_payment_intent_id);
      return json({ clientSecret: existing.client_secret });
    }

    // ── Build PaymentIntent parameters ───────────────────────────────────────
    type PiParams = Parameters<typeof stripe.paymentIntents.create>[0];

    const piParams: PiParams = {
      amount: order.amount_cents,
      currency: order.currency ?? 'usd',
      metadata: {
        order_id: order.id,
        buyer_id: order.buyer_id,
        shop_id: order.shop_id,
      },
    };

    if (isVendorShop) {
      // Destination Charge: platform retains application_fee_amount and Stripe
      // automatically transfers the remainder to the vendor's connected account.
      const applicationFeeAmount = Math.floor(
        (order.amount_cents * Number(shop.platform_fee_percent)) / 100,
      );
      piParams.transfer_data = { destination: shop.stripe_connect_account_id! };
      piParams.application_fee_amount = applicationFeeAmount;
    }

    // ── Create PaymentIntent ──────────────────────────────────────────────────
    const pi = await stripe.paymentIntents.create(piParams, {
      idempotencyKey: `pi-${orderId}`,
    });

    // ── Persist PI id on the order row ────────────────────────────────────────
    await admin
      .from('marketplace_orders')
      .update({ stripe_payment_intent_id: pi.id })
      .eq('id', orderId);

    return json({ clientSecret: pi.client_secret });

  } catch (err) {
    console.error('create-payment-intent error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
