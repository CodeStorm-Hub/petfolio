// Supabase Edge Function — stripe-onboard-vendor
//
// Called by Flutter SellerDashboardScreen when a vendor taps "Set up payments".
// Creates (or reuses) a Stripe Connect Express account for the shop, then
// generates a one-time account_link URL that opens Stripe's hosted KYC flow
// in the user's native browser.
//
// Idempotency: if the shop already has a stripe_connect_account_id we skip
// account creation and just generate a fresh account_link — account_links
// are single-use and expire after a few minutes.
//
// After the user completes KYC, Stripe fires an `account.updated` webhook
// that sets shops.is_verified = true via the stripe-webhook function.
//
// Flutter side: open the returned accountLinkUrl via url_launcher, then
// poll shops.is_verified on AppLifecycleState.resumed.
//
// Deploy: npx supabase functions deploy stripe-onboard-vendor
// Secrets: STRIPE_SECRET_KEY, APP_RETURN_URL (optional, defaults to project URL)

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

    // ── Parse body ───────────────────────────────────────────────────────────
    const { shopId } = await req.json() as { shopId: string };
    if (!shopId) {
      return json({ error: 'shopId is required' }, 400);
    }

    // ── Load shop via service role, verify ownership ──────────────────────────
    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: shop, error: shopErr } = await admin
      .from('shops')
      .select('id, owner_id, stripe_connect_account_id')
      .eq('id', shopId)
      .single();

    if (shopErr || !shop) {
      return json({ error: 'Shop not found' }, 404);
    }

    if (shop.owner_id !== user.id) {
      return json({ error: 'Forbidden' }, 403);
    }

    // ── Create Connect Express account if none exists ─────────────────────────
    let connectAccountId: string = shop.stripe_connect_account_id;

    if (!connectAccountId) {
      const account = await stripe.accounts.create({
        type: 'express',
        metadata: {
          shop_id: shopId,
          owner_id: user.id,
        },
      });
      connectAccountId = account.id;

      await admin
        .from('shops')
        .update({ stripe_connect_account_id: connectAccountId })
        .eq('id', shopId);
    }

    // ── Generate account_link for hosted KYC ─────────────────────────────────
    // return_url: where Stripe redirects after KYC is submitted.
    //   Using the Supabase project URL as a neutral landing page since deep
    //   links require native config (AndroidManifest / Info.plist) that is
    //   set up in a later phase. The Flutter app detects completion via
    //   AppLifecycleState.resumed + a re-fetch of the shop row.
    //
    // refresh_url: called when the account_link URL expires before the user
    //   completes the flow. Points to the same Edge Function so Stripe can
    //   get a fresh link automatically.
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const appReturnUrl = Deno.env.get('APP_RETURN_URL') ?? supabaseUrl;

    const accountLink = await stripe.accountLinks.create({
      account: connectAccountId,
      // refresh_url is called if the link expires; we re-invoke this function
      // to generate a new link, passing the shopId as a query param.
      refresh_url: `${supabaseUrl}/functions/v1/stripe-onboard-vendor-refresh?shopId=${shopId}`,
      return_url: `${appReturnUrl}`,
      type: 'account_onboarding',
    });

    return json({ accountLinkUrl: accountLink.url });

  } catch (err) {
    console.error('stripe-onboard-vendor error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
