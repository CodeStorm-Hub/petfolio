import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { sendFcmToUser } from "../_shared/fcm_send.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-fcm-dispatch-secret",
};

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

    const now = new Date().toISOString();
    const { data: due, error } = await supabase
      .from("care_web_reminders")
      .select("id, user_id, task_id, title, repeating, remind_at")
      .lte("remind_at", now)
      .is("fcm_sent_at", null)
      .limit(50);

    if (error) throw error;

    let sent = 0;
    for (const row of due ?? []) {
      try {
        const result = await sendFcmToUser(
          row.user_id as string,
          "Care reminder",
          row.title as string,
          {
            type: "care_reminder",
            task_id: String(row.task_id),
            route: "/care",
          },
        );
        if (result.sent > 0) {
          if (row.repeating) {
            const next = new Date(row.remind_at as string);
            next.setUTCDate(next.getUTCDate() + 1);
            await supabase
              .from("care_web_reminders")
              .update({
                remind_at: next.toISOString(),
                fcm_sent_at: null,
                updated_at: now,
              })
              .eq("id", row.id);
          } else {
            await supabase
              .from("care_web_reminders")
              .update({ fcm_sent_at: now })
              .eq("id", row.id);
          }
          sent += result.sent;
        }
      } catch (_) {
        continue;
      }
    }

    return new Response(JSON.stringify({ due: due?.length ?? 0, sent }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
