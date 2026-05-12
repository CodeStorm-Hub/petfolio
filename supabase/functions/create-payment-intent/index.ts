// Supabase Edge Function — create-payment-intent
//
// Called by Flutter CheckoutNotifier after a pending order row is inserted.
// Returns a Stripe PaymentIntent client_secret so the Flutter SDK can present
// the Payment Sheet.
//
// Idempotency: if the order already has a stripe_payment_intent_id, we fetch
// that PaymentIntent from Stripe and return the existing client_secret instead
// of creating a duplicate charge.
//
// Deploy: supabase functions deploy create-payment-intent
// Secret: supabase secrets set STRIPE_SECRET_KEY=sk_live_...

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

serve(async (req) => {
  // CORS preflight
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
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Parse request body ───────────────────────────────────────────────────
    const { orderId } = await req.json() as { orderId: string };
    if (!orderId) {
      return new Response(JSON.stringify({ error: 'orderId is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Load order (use service role to bypass RLS) ──────────────────────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: order, error: orderErr } = await admin
      .from('marketplace_orders')
      .select('id, amount_cents, currency, buyer_id, stripe_payment_intent_id')
      .eq('id', orderId)
      .single();

    if (orderErr || !order) {
      return new Response(JSON.stringify({ error: 'Order not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Security: caller must own this order ────────────────────────────────
    if (order.buyer_id !== user.id) {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // ── Idempotency: return existing PI if one already exists ────────────────
    if (order.stripe_payment_intent_id) {
      const existing = await stripe.paymentIntents.retrieve(order.stripe_payment_intent_id);
      return new Response(
        JSON.stringify({ clientSecret: existing.client_secret }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Create a new PaymentIntent ───────────────────────────────────────────
    // amount_cents is stored as bigint integer cents — pass directly to Stripe.
    const pi = await stripe.paymentIntents.create({
      amount: order.amount_cents,
      currency: order.currency ?? 'usd',
      metadata: {
        order_id: order.id,
        buyer_id: order.buyer_id,
      },
      // Idempotency key = orderId so network retries won't double-charge.
    }, {
      idempotencyKey: `pi-${orderId}`,
    });

    // ── Persist PI id on the order ───────────────────────────────────────────
    await admin
      .from('marketplace_orders')
      .update({ stripe_payment_intent_id: pi.id })
      .eq('id', orderId);

    return new Response(
      JSON.stringify({ clientSecret: pi.client_secret }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('create-payment-intent error:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : 'Internal error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
