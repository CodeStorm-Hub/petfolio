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

    const now = new Date();
    // Calculate 23-hour and 24-hour target window
    const rangeStart = new Date(now.getTime() + 23 * 60 * 60 * 1000).toISOString();
    const rangeEnd = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

    const { data: appointments, error } = await supabase
      .from("appointments")
      .select("id, owner_id, title, scheduled_at, location")
      .gte("scheduled_at", rangeStart)
      .lte("scheduled_at", rangeEnd)
      .in("status", ["confirmed", "pending"]);

    if (error) throw error;

    let sentCount = 0;
    const errors: string[] = [];

    for (const appt of appointments ?? []) {
      try {
        const scheduledTime = new Date(appt.scheduled_at);
        const timeStr = scheduledTime.toLocaleTimeString([], {
          hour: "numeric",
          minute: "2-digit",
        });
        const locationStr = appt.location ? ` at ${appt.location}` : "";
        const body = `Reminder: You have an appointment "${appt.title}" scheduled for tomorrow at ${timeStr}${locationStr}.`;

        const result = await sendFcmToUser(
          appt.owner_id as string,
          "Upcoming Appointment 📅",
          body,
          {
            type: "appointment_reminder",
            appointment_id: String(appt.id),
            route: "/care/appointments",
          },
        );
        sentCount += result.sent;
      } catch (err) {
        errors.push(`Failed for appointment ${appt.id}: ${String(err)}`);
      }
    }

    return new Response(
      JSON.stringify({
        checked: appointments?.length ?? 0,
        sent: sentCount,
        errors,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
