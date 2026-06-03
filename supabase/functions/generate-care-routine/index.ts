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
    const { prompt, model, guidedSchema } = await req.json() as {
      prompt: string;
      model?: string;
      guidedSchema?: Record<string, unknown>;
    };

    if (!prompt) {
      return json({ error: 'prompt is required' }, 400);
    }

    const nvidiaApiKey = Deno.env.get('NVIDIA_API_KEY');
    if (!nvidiaApiKey) {
      return json({ error: 'NVIDIA_API_KEY is not configured in Supabase secrets.' }, 500);
    }

    // Call the NVIDIA API
    const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${nvidiaApiKey}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        model: model || 'google/gemma-3n-e4b-it',
        messages: [
          { role: 'user', content: prompt }
        ],
        max_tokens: 1500,
        temperature: 0.25,
        top_p: 0.75,
        stream: false,
        nvext: guidedSchema ? { guided_json: guidedSchema } : undefined,
      }),
    });

    const responseText = await response.text();
    if (!response.ok) {
      return json({
        error: `NVIDIA API error: ${response.status}`,
        details: responseText,
      }, 502);
    }

    const body = JSON.parse(responseText);
    return json(body);

  } catch (err) {
    console.error('generate-care-routine error:', err);
    return json(
      { error: err instanceof Error ? err.message : 'Internal error' },
      500,
    );
  }
});
