// Supabase Edge Function — create-payment-intent
//
// Accepts { orderId, payment_method } where payment_method is 'stripe' | 'cod'.
//
// stripe — runs existing Destination Charge logic and returns a Stripe
//          PaymentIntent client_secret for the Flutter Payment Sheet.
//
// cod    — bypasses Stripe entirely. Validates the order, shop, and per-item
//          inventory, stamps the order with payment_method='cod', and returns
//          a confirmation payload so the Flutter client can proceed.
//
// payment_method defaults to 'stripe' when omitted (backwards compat).
//
// Deploy: npx supabase functions deploy create-payment-intent
// Secrets: STRIPE_SECRET_KEY

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
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    );

    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    // ── Parse request body ───────────────────────────────────────────────────
    const body = await req.json() as {
      orderId?: string;
      payment_method?: string;
    };

    const { orderId, payment_method = 'stripe' } = body;

    if (!orderId) {
      return json({ error: 'orderId is required' }, 400);
    }

    if (payment_method !== 'stripe' && payment_method !== 'cod') {
      return json({ error: 'payment_method must be "stripe" or "cod"' }, 400);
    }

    // ── Load order via service role (bypasses RLS) ───────────────────────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: order, error: orderErr } = await admin
      .from('marketplace_orders')
      .select('id, amount_cents, currency, buyer_id, shop_id, stripe_payment_intent_id, line_items, status')
      .eq('id', orderId)
      .single();

    if (orderErr || !order) {
      return json({ error: 'Order not found' }, 404);
    }

    // ── Security: caller must own this order ─────────────────────────────────
    if (order.buyer_id !== user.id) {
      return json({ error: 'Forbidden' }, 403);
    }

    // ── Guard: order must still be pending ───────────────────────────────────
    if (order.status !== 'pending') {
      return json({ error: 'Order is no longer pending', code: 'ORDER_NOT_PENDING' }, 409);
    }

    // ── Load shop ─────────────────────────────────────────────────────────────
    const { data: shop, error: shopErr } = await admin
      .from('shops')
      .select('id, stripe_connect_account_id, platform_fee_percent, is_verified, is_active, payout_method')
      .eq('id', order.shop_id)
      .single();

    if (shopErr || !shop) {
      return json({ error: 'Shop not found for this order' }, 404);
    }

    if (!shop.is_active) {
      return json({ error: 'This shop is currently inactive', code: 'SHOP_INACTIVE' }, 422);
    }

    // ── Reservation validity check (shared by both paths) ────────────────────
    // Inventory was locked at checkout time via inventory_reservations.
    // Confirm a non-expired active reservation exists before proceeding.
    const { data: reservations, error: resErr } = await admin
      .from('inventory_reservations')
      .select('id')
      .eq('order_id', orderId)
      .eq('status', 'active')
      .gt('expires_at', new Date().toISOString())
      .limit(1);

    if (resErr) {
      console.error('reservation check error:', resErr);
      return json({ error: 'Failed to validate reservation' }, 500);
    }

    if (!reservations?.length) {
      return json(
        { error: 'Reservation expired. Please restart checkout.', code: 'RESERVATION_EXPIRED' },
        422,
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // CoD path
    // ════════════════════════════════════════════════════════════════════════
    if (payment_method === 'cod') {
      // Confirm the reservation immediately — CoD has no async payment step.
      const { error: confirmErr } = await admin.rpc('confirm_order_inventory', {
        p_order_id: orderId,
      });
      if (confirmErr) {
        console.error('cod confirm_order_inventory error:', confirmErr);
        return json({ error: 'Failed to confirm CoD inventory', code: 'INVENTORY_CONFIRM_FAILED' }, 500);
      }

      const { error: updateErr } = await admin
        .from('marketplace_orders')
        .update({ payment_method: 'cod', payment_status: 'pending' })
        .eq('id', orderId);

      if (updateErr) {
        console.error('cod order update error:', updateErr);
        return json({ error: 'Failed to confirm CoD order' }, 500);
      }

      return json({
        paymentMethod: 'cod',
        orderId: order.id,
        amountCents: order.amount_cents,
        currency: order.currency ?? 'usd',
      });
    }

    // ════════════════════════════════════════════════════════════════════════
    // Stripe path
    // ════════════════════════════════════════════════════════════════════════

    // Third-party vendor shops must have a connected Stripe account.
    // PetFolio Official has is_verified=true but no stripe_connect_account_id
    // (platform-only charge, no transfer) — that branch is intentional.
    const isVendorShop = shop.stripe_connect_account_id !== null;
    if (isVendorShop && !shop.is_verified) {
      return json(
        { error: 'This seller has not completed payment setup', code: 'SHOP_NOT_VERIFIED' },
        422,
      );
    }

    // Idempotency: return existing PI if one already exists.
    if (order.stripe_payment_intent_id) {
      const existing = await stripe.paymentIntents.retrieve(order.stripe_payment_intent_id);
      return json({ clientSecret: existing.client_secret });
    }

    // Build PaymentIntent parameters.
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
      const applicationFeeAmount = Math.floor(
        (order.amount_cents * Number(shop.platform_fee_percent)) / 100,
      );
      piParams.transfer_data = { destination: shop.stripe_connect_account_id! };
      piParams.application_fee_amount = applicationFeeAmount;
    }

    const pi = await stripe.paymentIntents.create(piParams, {
      idempotencyKey: `pi-${orderId}`,
    });

    await admin
      .from('marketplace_orders')
      .update({ stripe_payment_intent_id: pi.id, payment_method: 'stripe' })
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
