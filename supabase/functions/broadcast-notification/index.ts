// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5.0.1";

declare const Deno: any;

type DeviceTokenRow = {
  user_id: string;
  token: string;
};

type SendResult = {
  sent: boolean;
  invalidToken: boolean;
  error?: string;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const broadcastSecret = Deno.env.get("BROADCAST_NOTIFICATION_SECRET") ?? "";
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const firebaseServiceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

const supabase = createClient(supabaseUrl, supabaseServiceKey);

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function isServiceRoleRequest(req: Request): boolean {
  const authHeader = req.headers.get("Authorization") ?? "";
  const bearerToken = authHeader.replace(/^Bearer\s+/i, "");
  const apiKey = req.headers.get("apikey") ?? "";
  const requestSecret = req.headers.get("x-broadcast-secret") ?? "";

  return bearerToken === supabaseServiceKey ||
    apiKey === supabaseServiceKey ||
    (broadcastSecret.length >= 32 && requestSecret === broadcastSecret);
}

function sanitizeRoute(route: unknown): string {
  if (typeof route !== "string" || route.trim().length === 0) {
    return "/notifications";
  }

  return route.startsWith("/") ? route : "/notifications";
}

function toStringData(
  data: unknown,
  defaults: Record<string, string>,
): Record<string, string> {
  const result = { ...defaults };
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return result;
  }

  for (const [key, value] of Object.entries(data as Record<string, unknown>)) {
    if (value === null || value === undefined) continue;
    result[key] = String(value);
  }

  return result;
}

async function getFirebaseAccessToken(): Promise<string | null> {
  if (!firebaseServiceAccountJson) {
    console.warn("FIREBASE_SERVICE_ACCOUNT_JSON not set, skipping FCM push");
    return null;
  }

  try {
    const serviceAccount = JSON.parse(firebaseServiceAccountJson);
    const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");
    const jwt = await new SignJWT({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
    })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuedAt()
      .setExpirationTime("1h")
      .sign(privateKey);

    const response = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }).toString(),
    });

    if (!response.ok) {
      console.error("Failed to get Firebase access token:", await response.text());
      return null;
    }

    const tokenResponse = await response.json();
    return tokenResponse.access_token;
  } catch (error) {
    console.error("Error creating Firebase access token:", error);
    return null;
  }
}

async function fetchActiveDeviceTokens(): Promise<DeviceTokenRow[]> {
  const pageSize = 500;
  const tokens: DeviceTokenRow[] = [];

  for (let from = 0; ; from += pageSize) {
    const to = from + pageSize - 1;
    const { data, error } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .eq("is_active", true)
      .range(from, to);

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) break;
    tokens.push(...data);
    if (data.length < pageSize) break;
  }

  return tokens;
}

async function sendFCMNotification(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<SendResult> {
  if (!firebaseProjectId) {
    return {
      sent: false,
      invalidToken: false,
      error: "FIREBASE_PROJECT_ID is not set",
    };
  }

  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data,
            android: {
              priority: "high",
              notification: {
                channel_id: "sawa_notifications",
              },
            },
            apns: {
              headers: {
                "apns-priority": "10",
              },
              payload: {
                aps: {
                  sound: "default",
                },
              },
            },
          },
        }),
      },
    );

    if (response.ok) {
      return { sent: true, invalidToken: false };
    }

    const errorText = await response.text();
    return {
      sent: false,
      invalidToken: errorText.includes("UNREGISTERED"),
      error: errorText,
    };
  } catch (error) {
    return {
      sent: false,
      invalidToken: false,
      error: String(error),
    };
  }
}

Deno.serve(async (req: Request) => {
  if (!isServiceRoleRequest(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  try {
    const payload = await req.json().catch(() => ({}));
    const title = typeof payload.title === "string" && payload.title.trim()
      ? payload.title.trim()
      : "SAWA";
    const body = typeof payload.body === "string" && payload.body.trim()
      ? payload.body.trim()
      : "تم إرسال إشعار";
    const route = sanitizeRoute(payload.route);
    const dryRun = payload.dry_run === true;
    const now = new Date().toISOString();
    const data = toStringData(payload.data, {
      event_type: "broadcast",
      type: "broadcast",
      route,
      sent_at: now,
    });

    const tokens = await fetchActiveDeviceTokens();
    if (dryRun) {
      return jsonResponse({
        success: true,
        dry_run: true,
        active_tokens: tokens.length,
      });
    }

    if (tokens.length === 0) {
      return jsonResponse({
        success: true,
        active_tokens: 0,
        fcm_tokens_sent: 0,
        invalid_tokens_deactivated: 0,
        failed_tokens: 0,
      });
    }

    const accessToken = await getFirebaseAccessToken();
    if (!accessToken) {
      return jsonResponse(
        { error: "Could not get Firebase access token" },
        500,
      );
    }

    let sentCount = 0;
    let invalidCount = 0;
    let failedCount = 0;
    const concurrency = 20;

    for (let index = 0; index < tokens.length; index += concurrency) {
      const batch = tokens.slice(index, index + concurrency);
      const results = await Promise.all(
        batch.map((row) =>
          sendFCMNotification(accessToken, row.token, title, body, data)
        ),
      );

      for (let i = 0; i < results.length; i++) {
        const result = results[i];
        const row = batch[i];

        if (result.sent) {
          sentCount++;
          continue;
        }

        failedCount++;
        if (result.invalidToken) {
          invalidCount++;
          await supabase
            .from("device_tokens")
            .update({
              is_active: false,
              updated_by: row.user_id,
              updated_at: now,
            })
            .eq("user_id", row.user_id)
            .eq("token", row.token);
        } else {
          console.error("Broadcast FCM send failed:", result.error);
        }
      }
    }

    return jsonResponse({
      success: true,
      active_tokens: tokens.length,
      fcm_tokens_sent: sentCount,
      invalid_tokens_deactivated: invalidCount,
      failed_tokens: failedCount,
    });
  } catch (error) {
    console.error("Error in broadcast-notification:", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
