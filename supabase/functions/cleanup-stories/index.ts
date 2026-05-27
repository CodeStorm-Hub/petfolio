// Supabase Edge Function — cleanup-stories
//
// Calls cleanup_expired_stories() to delete story rows older than 24 hours.
// Designed to be triggered by pg_cron on an hourly schedule, or manually
// via HTTP for testing / one-off runs.
//
// No Supabase JWT verification — this function is intended for internal
// invocation only (pg_cron HTTP call or admin curl). If exposed publicly,
// re-enable JWT verification and restrict to service_role.
//
// Deploy: npx supabase functions deploy cleanup-stories --no-verify-jwt

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (_req) => {
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')              ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );

  const { error } = await admin.rpc('cleanup_expired_stories');

  if (error) {
    console.error('cleanup_expired_stories failed:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status:  500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  console.log('cleanup_expired_stories completed');
  return new Response(JSON.stringify({ success: true }), {
    status:  200,
    headers: { 'Content-Type': 'application/json' },
  });
});
