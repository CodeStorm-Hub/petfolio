import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const ANDROID_CHANNEL_PUSH = "petfolio_push";
const ANDROID_CHANNEL_CHAT = "petfolio_chat";
const CHAT_SOUND = "chat_message";

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function base64UrlEncodeJson(value: unknown): string {
  return base64UrlEncode(new TextEncoder().encode(JSON.stringify(value)));
}

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64UrlEncodeJson({ alg: "RS256", typ: "JWT" });
  const claim = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };
  const payload = base64UrlEncodeJson(claim);
  const unsigned = `${header}.${payload}`;

  const pem = serviceAccount.private_key.replace(/\\n/g, "\n");
  const keyData = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const signature = base64UrlEncode(new Uint8Array(sig));
  const jwt = `${unsigned}.${signature}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const tokenJson = await tokenRes.json();
  if (!tokenRes.ok) {
    throw new Error(
      (tokenJson as { error_description?: string }).error_description ??
        "OAuth token failed",
    );
  }
  return (tokenJson as { access_token: string }).access_token;
}

function parseServiceAccount(): {
  client_email: string;
  private_key: string;
  project_id: string;
} {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!raw?.trim()) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON not set");
  }
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is invalid JSON");
  }
  const client_email = parsed.client_email as string | undefined;
  const private_key = parsed.private_key as string | undefined;
  const project_id = parsed.project_id as string | undefined;
  if (!client_email || !private_key || !project_id) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT_JSON missing client_email, private_key, or project_id",
    );
  }
  return { client_email, private_key, project_id };
}

function stringifyData(data?: Record<string, string>): Record<string, string> {
  if (!data) return {};
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) {
    out[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  return out;
}

function isUnregisteredTokenError(body: unknown): boolean {
  if (!body || typeof body !== "object") return false;
  const err = body as { error?: { details?: Array<{ errorCode?: string }> } };
  return (err.error?.details ?? []).some((d) => d.errorCode === "UNREGISTERED");
}

export async function sendFcmToUser(
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<{ sent: number; total: number; errors: string[] }> {
  const serviceAccount = parseServiceAccount();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: devices, error } = await supabase
    .from("user_fcm_devices")
    .select("fcm_token")
    .eq("user_id", userId);

  if (error) throw error;
  const tokens = (devices ?? []).map((d) => d.fcm_token as string).filter(Boolean);
  if (tokens.length === 0) return { sent: 0, total: 0, errors: [] };

  const accessToken = await getAccessToken(serviceAccount);
  const projectId = serviceAccount.project_id;
  const fcmData = stringifyData(data);
  const isChat = fcmData.type === "chat_message";
  const androidChannelId = isChat ? ANDROID_CHANNEL_CHAT : ANDROID_CHANNEL_PUSH;
  const androidSound = isChat ? CHAT_SOUND : "default";
  const apnsSound = isChat ? "chat_message.wav" : "default";

  let sent = 0;
  const errors: string[] = [];

  for (const token of tokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: fcmData,
            android: {
              priority: "HIGH",
              notification: {
                channel_id: androidChannelId,
                sound: androidSound,
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: apnsSound,
                  badge: 1,
                },
              },
            },
          },
        }),
      },
    );
    if (res.ok) {
      sent += 1;
      continue;
    }

    const errBody = await res.json().catch(() => ({}));
    const message =
      (errBody as { error?: { message?: string } })?.error?.message ??
      `FCM HTTP ${res.status}`;
    errors.push(message);

    if (isUnregisteredTokenError(errBody)) {
      await supabase
        .from("user_fcm_devices")
        .delete()
        .eq("fcm_token", token);
    }
  }

  if (sent === 0 && errors.length > 0) {
    throw new Error(errors[0]);
  }

  return { sent, total: tokens.length, errors };
}
