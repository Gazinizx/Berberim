import { createClient } from "npm:@supabase/supabase-js@2";

type NotificationRow = {
  id: string;
  user_id: string;
  appointment_id: string | null;
  title: string;
  body: string;
};

type PushTokenRow = {
  id: string;
  fid: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "content-type, x-berberim-push-secret",
  "Content-Type": "application/json",
};

let cachedAccessToken = "";
let cachedAccessTokenExpiresAt = 0;

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function base64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function encodeJson(value: Record<string, unknown>): string {
  return base64Url(new TextEncoder().encode(JSON.stringify(value)));
}

function pemToBytes(pem: string): Uint8Array {
  const normalized = pem.replace(/\\n/g, "\n");
  const body = normalized
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = atob(body);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

async function getFcmAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessTokenExpiresAt > now + 60) {
    return cachedAccessToken;
  }

  const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL") ?? "";
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY") ?? "";
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error("FCM_PROJECT_ID, FCM_CLIENT_EMAIL and FCM_PRIVATE_KEY secrets are required");
  }

  const header = encodeJson({ alg: "RS256", typ: "JWT" });
  const claims = encodeJson({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });
  const unsignedToken = header + "." + claims;

  const signingKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      signingKey,
      new TextEncoder().encode(unsignedToken),
    ),
  );
  const assertion = unsignedToken + "." + base64Url(signature);

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  const tokenPayload = await tokenResponse.json();
  if (!tokenResponse.ok || typeof tokenPayload.access_token !== "string") {
    throw new Error("Google OAuth token request failed (" + tokenResponse.status + ")");
  }

  cachedAccessToken = tokenPayload.access_token;
  cachedAccessTokenExpiresAt = now + Number(tokenPayload.expires_in ?? 3600);
  return cachedAccessToken;
}

function getSupabaseSecretKey(): string {
  const secretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (secretKeys) {
    try {
      const parsed = JSON.parse(secretKeys);
      if (typeof parsed.default === "string") return parsed.default;
    } catch {
      // Fall back to the legacy injected environment variable.
    }
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceKey = getSupabaseSecretKey();
    if (!supabaseUrl || !serviceKey) {
      return jsonResponse({ error: "Supabase server credentials are unavailable" }, 503);
    }

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const suppliedSecret = request.headers.get("x-berberim-push-secret") ?? "";
    if (!suppliedSecret) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
    const { data: secretIsValid, error: secretError } = await admin.rpc(
      "verify_berberim_push_secret",
      { p_candidate: suppliedSecret },
    );
    if (secretError || secretIsValid !== true) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const body = await request.json().catch(() => ({}));
    const notificationId = typeof body.notification_id === "string"
      ? body.notification_id
      : "";
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(notificationId)) {
      return jsonResponse({ error: "Invalid notification_id" }, 400);
    }

    const { data: notification, error: notificationError } = await admin
      .from("notifications")
      .select("id,user_id,appointment_id,title,body")
      .eq("id", notificationId)
      .maybeSingle();

    if (notificationError) throw notificationError;
    if (!notification) return jsonResponse({ error: "Notification not found" }, 404);

    const row = notification as NotificationRow;
    const { data: tokenRows, error: tokenError } = await admin
      .from("push_tokens")
      .select("id,fid")
      .eq("user_id", row.user_id);

    if (tokenError) throw tokenError;
    const tokens = (tokenRows ?? []) as PushTokenRow[];
    if (tokens.length === 0) {
      return jsonResponse({ ok: true, sent: 0, message: "No registered devices" });
    }

    const projectId = Deno.env.get("FCM_PROJECT_ID") ?? "";
    const accessToken = await getFcmAccessToken();
    const endpoint = "https://fcm.googleapis.com/v1/projects/" + projectId + "/messages:send";

    const results = await Promise.all(tokens.map(async (device) => {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: "Bearer " + accessToken,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            fid: device.fid,
            notification: {
              title: row.title,
              body: row.body,
            },
            data: {
              notification_id: row.id,
              appointment_id: row.appointment_id ?? "",
              route: "notifications",
            },
            android: {
              priority: "HIGH",
              notification: {
                channel_id: "berberim_notifications",
                sound: "default",
              },
            },
          },
        }),
      });

      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        const details = Array.isArray(payload?.error?.details)
          ? payload.error.details
          : [];
        const unregistered = payload?.error?.status === "NOT_FOUND" ||
          details.some((detail: Record<string, unknown>) =>
            detail.errorCode === "UNREGISTERED"
          );

        if (unregistered) {
          await admin.from("push_tokens").delete().eq("id", device.id);
        }
      }
      return response.ok;
    }));

    const sent = results.filter(Boolean).length;
    return jsonResponse({
      ok: sent > 0,
      sent,
      failed: results.length - sent,
    });
  } catch (error) {
    console.error("Berberim push send failed:", error);
    return jsonResponse({ error: "Push notification could not be sent" }, 500);
  }
});
