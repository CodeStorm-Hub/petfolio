// Supabase Edge Function — create-sslcommerz-session
//
// Accepts { orderId, payment_method, success_url, fail_url, cancel_url }
// where payment_method is 'bkash' | 'nagad'.
//
// Calls the SSLCommerz init API, stores the session key on the order row,
// and returns { gatewayUrl, transactionId } for the Flutter client to
// open in an external browser.
//
// Env secrets: SSLCOMMERZ_STORE_ID, SSLCOMMERZ_STORE_PASSWD, SSLCOMMERZ_API_BASE
// Deploy: npx supabase functions deploy create-sslcommerz-session

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

function isAllowedRedirectUrl(url: string): boolean {
  const raw =
    Deno.env.get('ALLOWED_REDIRECT_ORIGINS') ?? Deno.env.get('PUBLIC_APP_ORIGIN') ?? '';
  const origins = raw.split(',').map((s: string) => s.trim()).filter(Boolean);
  if (origins.length === 0) return false;
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  if (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1') return true;
  return origins.some((origin: string) => {
    try {
      return parsed.origin === new URL(origin).origin;
    } catch {
      return false;
    }
  });
}

const PAYMENT_OPTIONS: Record<string, string> = {
  bkash: 'bKash',
  nagad: 'Nagad',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } } },
    );

    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const body = await req.json() as {
      orderId?: string;
      payment_method?: string;
      success_url?: string;
      fail_url?: string;
      cancel_url?: string;
    };

    const { orderId, payment_method, success_url, fail_url, cancel_url } = body;

    if (!orderId) return json({ error: 'orderId is required' }, 400);
    if (!payment_method || !PAYMENT_OPTIONS[payment_method]) {
      return json({ error: 'payment_method must be "bkash" or "nagad"' }, 400);
    }
    if (!success_url || !fail_url || !cancel_url) {
      return json({ error: 'success_url, fail_url, and cancel_url are required' }, 400);
    }
    if (!isAllowedRedirectUrl(success_url) || !isAllowedRedirectUrl(fail_url) || !isAllowedRedirectUrl(cancel_url)) {
      return json({ error: 'Redirect URL origin is not allowed' }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: order, error: orderErr } = await admin
      .from('marketplace_orders')
      .select('id, amount_cents, currency, buyer_id, shop_id, status, sslcommerz_transaction_id, line_items')
      .eq('id', orderId)
      .single();

    if (orderErr || !order) return json({ error: 'Order not found' }, 404);
    if (order.buyer_id !== user.id) return json({ error: 'Forbidden' }, 403);
    if (order.status !== 'pending') {
      return json({ error: 'Order is no longer pending', code: 'ORDER_NOT_PENDING' }, 409);
    }

    const { data: shop, error: shopErr } = await admin
      .from('shops')
      .select('id, is_verified, is_active')
      .eq('id', order.shop_id)
      .single();

    if (shopErr || !shop) return json({ error: 'Shop not found' }, 404);
    if (!shop.is_active) {
      return json({ error: 'This shop is currently inactive', code: 'SHOP_INACTIVE' }, 422);
    }
    if (!shop.is_verified) {
      return json({ error: 'This seller has not completed payment setup', code: 'SHOP_NOT_VERIFIED' }, 422);
    }

    const { data: reservations, error: resErr } = await admin
      .from('inventory_reservations')
      .select('id')
      .eq('order_id', orderId)
      .eq('status', 'active')
      .gt('expires_at', new Date().toISOString())
      .limit(1);

    if (resErr) return json({ error: 'Failed to validate reservation' }, 500);
    if (!reservations?.length) {
      return json(
        { error: 'Reservation expired. Please restart checkout.', code: 'RESERVATION_EXPIRED' },
        422,
      );
    }

    // Idempotency: return existing session if one was already created for this order.
    if (order.sslcommerz_transaction_id) {
      const existingKey = order.sslcommerz_transaction_id;
      const apiBase = Deno.env.get('SSLCOMMERZ_API_BASE') ?? 'https://sandbox.sslcommerz.com';
      const storeId = Deno.env.get('SSLCOMMERZ_STORE_ID') ?? '';
      const storePasswd = Deno.env.get('SSLCOMMERZ_STORE_PASSWD') ?? '';
      const queryUrl = `${apiBase}/validator/api/merchantTransIDvalidationAPI.php?merchant_id=${storeId}&store_passwd=${storePasswd}&tran_id=${orderId}&format=json`;
      try {
        const checkRes = await fetch(queryUrl);
        if (checkRes.ok) {
          const checkData = await checkRes.json() as { element?: Array<{ GatewayPageURL?: string }> };
          const existingGatewayUrl = checkData.element?.[0]?.GatewayPageURL;
          if (existingGatewayUrl) {
            return json({ gatewayUrl: existingGatewayUrl, transactionId: existingKey });
          }
        }
      } catch {
        // Fall through to create a new session
      }
    }

    const storeId = Deno.env.get('SSLCOMMERZ_STORE_ID') ?? '';
    const storePasswd = Deno.env.get('SSLCOMMERZ_STORE_PASSWD') ?? '';
    const apiBase = Deno.env.get('SSLCOMMERZ_API_BASE') ?? 'https://sandbox.sslcommerz.com';
    const ipnUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/sslcommerz-webhook`;

    const lineItems = (order.line_items as Array<{ quantity: number }>) ?? [];
    const numOfItem = lineItems.reduce((s: number, i: { quantity: number }) => s + i.quantity, 0) || 1;

    const amountBdt = (order.amount_cents / 100).toFixed(2);

    const formParams = new URLSearchParams({
      store_id:         storeId,
      store_passwd:     storePasswd,
      total_amount:     amountBdt,
      currency:         'BDT',
      tran_id:          orderId,
      success_url:      success_url,
      fail_url:         fail_url,
      cancel_url:       cancel_url,
      ipn_url:          ipnUrl,
      payment_option:   PAYMENT_OPTIONS[payment_method],
      product_name:     'PetFolio Pet Supplies',
      product_category: 'Pet Supplies',
      product_profile:  'general',
      cus_name:         user.email?.split('@')[0] ?? 'Customer',
      cus_email:        user.email ?? 'customer@petfolio.app',
      cus_phone:        '01700000000',
      cus_add1:         'Dhaka',
      cus_city:         'Dhaka',
      cus_country:      'Bangladesh',
      ship_name:        user.email?.split('@')[0] ?? 'Customer',
      ship_add1:        'Dhaka',
      ship_city:        'Dhaka',
      ship_country:     'Bangladesh',
      shipping_method:  'NO',
      num_of_item:      String(numOfItem),
      emi_option:       '0',
    });

    const sslRes = await fetch(`${apiBase}/gwprocess/v4/api.php`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formParams.toString(),
    });

    if (!sslRes.ok) {
      console.error('SSLCommerz init failed:', sslRes.status, await sslRes.text());
      return json({ error: 'SSLCommerz gateway error', code: 'SSLCOMMERZ_ERROR' }, 502);
    }

    const sslData = await sslRes.json() as {
      status?: string;
      GatewayPageURL?: string;
      sessionkey?: string;
      failedreason?: string;
    };

    if (sslData.status !== 'SUCCESS' || !sslData.GatewayPageURL || !sslData.sessionkey) {
      console.error('SSLCommerz init error:', sslData);
      return json(
        { error: sslData.failedreason ?? 'SSLCommerz session creation failed', code: 'SSLCOMMERZ_ERROR' },
        502,
      );
    }

    await admin
      .from('marketplace_orders')
      .update({
        sslcommerz_transaction_id: sslData.sessionkey,
        payment_method: payment_method,
      })
      .eq('id', orderId);

    return json({
      gatewayUrl:    sslData.GatewayPageURL,
      transactionId: sslData.sessionkey,
    });

  } catch (err) {
    console.error('create-sslcommerz-session error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
