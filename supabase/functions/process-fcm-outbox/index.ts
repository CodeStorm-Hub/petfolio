import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { sendFcmToUser } from "../_shared/fcm_send.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-fcm-dispatch-secret",
};

const MAX_RETRIES = 3;

function assertDispatchAuth(req: Request): boolean {
  const expected = Deno.env.get("FCM_DISPATCH_SECRET");
  if (!expected) return false;
  return req.headers.get("x-fcm-dispatch-secret") === expected;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (!assertDispatchAuth(req)) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: rows, error } = await supabase
      .from("fcm_push_outbox")
      .select("id, user_id, title, body, data, retry_count")
      .is("processed_at", null)
      .is("failed_at", null)
      .lt("retry_count", MAX_RETRIES)
      .order("created_at", { ascending: true })
      .limit(40);

    if (error) throw error;

    let processed = 0;
    let sentTotal = 0;
    let deadLettered = 0;

    for (const row of rows ?? []) {
      const raw = (row.data ?? {}) as Record<string, unknown>;
      const data: Record<string, string> = {};
      for (const [k, v] of Object.entries(raw)) {
        data[k] = typeof v === "string" ? v : JSON.stringify(v);
      }

      try {
        const result = await sendFcmToUser(
          row.user_id as string,
          row.title as string,
          (row.body as string) ?? "",
          data,
        );
        sentTotal += result.sent;
        await supabase
          .from("fcm_push_outbox")
          .update({ processed_at: new Date().toISOString() })
          .eq("id", row.id);
        processed += 1;
      } catch (err) {
        const newCount = (row.retry_count as number) + 1;
        const isDeadLetter = newCount >= MAX_RETRIES;
        await supabase
          .from("fcm_push_outbox")
          .update({
            retry_count: newCount,
            last_error: String(err),
            ...(isDeadLetter ? { failed_at: new Date().toISOString() } : {}),
          })
          .eq("id", row.id);
        if (isDeadLetter) deadLettered += 1;
      }
    }

    return new Response(JSON.stringify({ processed, sentTotal, deadLettered }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
