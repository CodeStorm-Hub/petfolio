// Supabase Edge Function — sslcommerz-webhook
//
// IPN (Instant Payment Notification) handler for SSLCommerz.
// SSLCommerz POSTs form-encoded data to this endpoint after a transaction.
//
// Flow:
//  1. Parse IPN form POST
//  2. Validate via SSLCommerz validation API (GET)
//  3. Look up order by tran_id (= orderId)
//  4. Idempotency check — skip if already paid
//  5. Call confirm_order_inventory RPC + mark order paid
//
// Env secrets: SSLCOMMERZ_STORE_ID, SSLCOMMERZ_STORE_PASSWD, SSLCOMMERZ_API_BASE
// Deploy: npx supabase functions deploy sslcommerz-webhook

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  try {
    const text = await req.text();
    const params = new URLSearchParams(text);

    const valId   = params.get('val_id');
    const tranId  = params.get('tran_id');
    const status  = params.get('status');

    if (!valId || !tranId || !status) {
      return json({ error: 'Missing required IPN fields' }, 400);
    }

    // Only process successful/validated transactions
    if (status !== 'VALID' && status !== 'VALIDATED') {
      console.log(`SSLCommerz IPN received with status=${status} for tran_id=${tranId}`);
      return json({ received: true, action: 'ignored', status });
    }

    const storeId    = Deno.env.get('SSLCOMMERZ_STORE_ID') ?? '';
    const storePasswd = Deno.env.get('SSLCOMMERZ_STORE_PASSWD') ?? '';
    const apiBase    = Deno.env.get('SSLCOMMERZ_API_BASE') ?? 'https://sandbox.sslcommerz.com';

    // Validate the transaction with SSLCommerz
    const validateUrl =
      `${apiBase}/validator/api/validationserverAPI.php` +
      `?val_id=${encodeURIComponent(valId)}` +
      `&store_id=${encodeURIComponent(storeId)}` +
      `&store_passwd=${encodeURIComponent(storePasswd)}` +
      `&format=json`;

    const validateRes = await fetch(validateUrl);
    if (!validateRes.ok) {
      console.error('SSLCommerz validation fetch failed:', validateRes.status);
      return json({ error: 'Validation fetch failed' }, 502);
    }

    const validation = await validateRes.json() as {
      status?: string;
      tran_id?: string;
      store_id?: string;
      amount?: string;
      currency?: string;
    };

    if (
      validation.status !== 'VALID' && validation.status !== 'VALIDATED' ||
      validation.tran_id !== tranId ||
      validation.store_id !== storeId
    ) {
      console.error('SSLCommerz validation failed:', validation);
      return json({ error: 'Invalid transaction' }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // tran_id is the orderId (set during session creation)
    const orderId = tranId;

    const { data: order, error: orderErr } = await admin
      .from('marketplace_orders')
      .select('id, status, payment_status, payment_method')
      .eq('id', orderId)
      .single();

    if (orderErr || !order) {
      console.error(`Order not found for tran_id=${orderId}:`, orderErr);
      return json({ error: 'Order not found' }, 404);
    }

    // Idempotency: skip if already processed
    if (order.payment_status === 'paid' || order.status === 'processing') {
      console.log(`Order ${orderId} already confirmed, skipping duplicate IPN`);
      return json({ received: true, action: 'already_confirmed' });
    }

    const { error: confirmErr } = await admin.rpc('confirm_order_inventory', {
      p_order_id: orderId,
    });

    if (confirmErr) {
      console.error('confirm_order_inventory error:', confirmErr);
      return json({ error: 'Inventory confirmation failed' }, 500);
    }

    const { error: updateErr } = await admin
      .from('marketplace_orders')
      .update({
        payment_status: 'paid',
        status: 'processing',
      })
      .eq('id', orderId);

    if (updateErr) {
      console.error('Order update error:', updateErr);
      return json({ error: 'Order update failed' }, 500);
    }

    console.log(`SSLCommerz: order ${orderId} confirmed via IPN (val_id=${valId})`);
    return json({ received: true, action: 'confirmed', orderId });

  } catch (err) {
    console.error('sslcommerz-webhook error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
