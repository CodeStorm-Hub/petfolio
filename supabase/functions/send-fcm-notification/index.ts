import { sendFcmToUser } from "../_shared/fcm_send.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-fcm-dispatch-secret",
};

type SendBody = {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
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
    const body = (await req.json()) as SendBody;
    if (!body.userId || !body.title) {
      return new Response(JSON.stringify({ error: "userId and title required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await sendFcmToUser(
      body.userId,
      body.title,
      body.body ?? "",
      body.data,
    );

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
