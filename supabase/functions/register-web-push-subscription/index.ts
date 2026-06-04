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
      endpoint?: string;
      p256dh?: string;
      auth?: string;
    };

    const { endpoint, p256dh, auth } = body;
    if (!endpoint || !p256dh || !auth) {
      return json({ error: 'endpoint, p256dh, and auth are required' }, 400);
    }

    const admin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { error } = await admin.from('user_web_push_subscriptions').upsert(
      {
        user_id: user.id,
        endpoint,
        p256dh,
        auth,
      },
      { onConflict: 'endpoint' },
    );

    if (error) {
      console.error('register-web-push-subscription:', error);
      return json({ error: 'Failed to save subscription' }, 500);
    }

    return json({ ok: true });
  } catch (err) {
    console.error('register-web-push-subscription error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
