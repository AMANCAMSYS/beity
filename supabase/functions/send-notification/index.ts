// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5.0.1";
import { templates } from "../_shared/templates.ts";

declare const Deno: any;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const firebaseServiceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function requireUser(req: Request, supabaseAdmin: SupabaseClient) {
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "");

  if (!token) {
    return {
      response: new Response(
        JSON.stringify({ error: "Missing authorization token" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      ),
    };
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    return {
      response: new Response(
        JSON.stringify({ error: "Invalid authorization token" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      ),
    };
  }

  return { user: data.user };
}

async function requireActiveHomeMember(
  supabaseAdmin: SupabaseClient,
  homeId: string,
  userId: string,
): Promise<Response | null> {
  const { data, error } = await supabaseAdmin
    .from("home_members")
    .select("role")
    .eq("home_id", homeId)
    .eq("user_id", userId)
    .eq("status", "active")
    .is("deleted_at", null)
    .maybeSingle();

  if (error || !data) {
    return new Response(
      JSON.stringify({ error: "Access denied" }),
      { status: 403, headers: { "Content-Type": "application/json" } },
    );
  }

  return null;
}

// Notification content templates imported from shared folder

function getPreferenceColumnForEvent(eventType: string): string | null {
  switch (eventType) {
    case "item_added":
      return "item_added";
    case "item_completed":
    case "item_uncompleted":
    case "list_completed":
      return "item_completed";
    case "item_updated":
      return "item_added";
    case "task_assigned":
      return "task_assigned";
    case "task_due":
      return "task_due";
    case "expense_added":
    case "expense_updated":
    case "expense_deleted":
    case "expense_settled":
      return "expense_added";
    case "inventory_low_stock":
    case "inventory_out_of_stock":
      return "low_stock";
    case "inventory_expiring":
    case "inventory_expired":
      return "expiry_alert";
    case "member_joined":
      return null;
    case "invitation_received":
    case "invitation_accepted":
    case "invitation_declined":
    case "invitation_cancelled":
      return null;
    default:
      return null;
  }
}

function getCategoryForEvent(eventType: string): string {
  switch (eventType) {
    case "item_added":
    case "item_completed":
    case "item_uncompleted":
    case "item_updated":
    case "list_completed":
      return "shopping_list";
    case "task_assigned":
    case "task_due":
      return "task";
    case "expense_added":
    case "expense_updated":
    case "expense_deleted":
    case "expense_settled":
      return "expense";
    case "inventory_low_stock":
    case "inventory_out_of_stock":
    case "inventory_expiring":
    case "inventory_expired":
      return "inventory";
    case "member_joined":
      return "home_activity";
    case "invitation_received":
    case "invitation_accepted":
    case "invitation_declined":
    case "invitation_cancelled":
      return "invitation";
    default:
      return "home_activity";
  }
}

function getRouteForEvent(eventType: string, referenceId: string, referenceType: string, homeId: string): string {
  switch (referenceType) {
    case "shopping_list":
      return `/shopping-list/${referenceId}?homeId=${homeId}`;
    case "expense":
      return `/expenses/${referenceId}?homeId=${homeId}`;
    case "settlement":
      return `/expenses?homeId=${homeId}`;
    case "inventory_item":
      return `/inventory/${referenceId}`;
    case "task":
      return `/home/${homeId}/tasks/${referenceId}`;
    case "invitation":
      return `/invitations`;
    case "home":
      return `/homes/${referenceId}/members`;
    default:
      return `/`;
  }
}

function shouldSendPushForEvent(eventType: string): boolean {
  switch (eventType) {
    case "item_updated":
    case "item_uncompleted":
      return false;
    default:
      return true;
  }
}

function shouldSendQuietPushForEvent(eventType: string): boolean {
  switch (eventType) {
    case "item_added":
    case "member_joined":
    case "inventory_low_stock":
    case "inventory_expiring":
      return true;
    default:
      return false;
  }
}

function renderTemplate(
  template: { title: string; body: string },
  context: Record<string, string>
): { title: string; body: string } {
  let title = template.title;
  let body = template.body;
  for (const [key, value] of Object.entries(context)) {
    title = title.split(`{${key}}`).join(value);
    body = body.split(`{${key}}`).join(value);
  }
  return { title, body };
}

// Get Firebase access token for FCM v1 API
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
      body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
    });

    if (!response.ok) {
      console.error("Failed to get Firebase access token:", await response.text());
      return null;
    }

    const data = await response.json();
    return data.access_token;
  } catch (e) {
    console.error("Error parsing service account or signing JWT:", e);
    return null;
  }
}

// Send FCM notification using HTTP v1 API
async function sendFCMNotification(
  token: string,
  platform: string | null,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const accessToken = await getFirebaseAccessToken();
  
  if (!accessToken) {
    console.warn("Could not get Firebase access token, skipping FCM push");
    return false;
  }

  if (!firebaseProjectId) {
    console.warn("FIREBASE_PROJECT_ID not set, skipping FCM push");
    return false;
  }

  const notificationCategory = data.category || data.event_type || "general";
  const groupKey = `sawa_${notificationCategory}_${data.home_id || "default"}`;
  const isAndroid = platform === "android";
  const isQuiet = data.quiet === "true";

  const message: Record<string, unknown> = {
    token: token,
    data: {
      ...data,
      title: title,
      body: body,
      group: groupKey,
      category: notificationCategory,
    },
  };

  if (isAndroid) {
    message.android = {
      priority: isQuiet ? "normal" : "high",
    };
  } else {
    message.notification = {
      title: title,
      body: body,
    };
    message.apns = {
      headers: {
        "apns-priority": isQuiet ? "5" : "10",
        "apns-collapse-id": groupKey,
      },
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          ...(isQuiet ? {} : { sound: "default" }),
          "content-available": 1,
          "thread-id": groupKey,
        },
      },
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
        body: JSON.stringify({ message }),
      },
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error("FCM send failed:", errorText);
      
      // If token is invalid, remove it from database
      if (errorText.includes("UNREGISTERED") || errorText.includes("INVALID_ARGUMENT")) {
        await supabase.from("device_tokens").delete().eq("token", token);
      }
      
      return false;
    }

    const result = await response.json();
    console.log("FCM sent successfully:", result);
    return true;
  } catch (e) {
    console.error("Error sending FCM:", e);
    return false;
  }
}

Deno.serve(async (req: Request) => {
  try {
    // Verify JWT
    const authResult = await requireUser(req, supabase);
    if ("response" in authResult) {
      return authResult.response;
    }
    const authenticatedUser = authResult.user;

    const {
      event_type,
      home_id,
      reference_id,
      reference_type,
      context,
      target_user_id,
      target_user_ids,
    } = await req.json();
    const actor_id = authenticatedUser.id;

    if (!event_type || !home_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: event_type, home_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Verify the caller is an active member of this home
    const membershipError = await requireActiveHomeMember(supabase, home_id, authenticatedUser.id);
    if (membershipError) {
      return membershipError;
    }

    const category = getCategoryForEvent(event_type);
    const targetRoute = getRouteForEvent(event_type, reference_id, reference_type, home_id);
    const preferenceColumn = getPreferenceColumnForEvent(event_type);

    let members: { user_id: string }[] = [];

    if (event_type === "task_assigned") {
      if (!target_user_id) {
        return new Response(
          JSON.stringify({ error: "Missing required field: target_user_id" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }

      if (target_user_id === actor_id) {
        return new Response(
          JSON.stringify({ success: true, notifications_sent: 0, recipients: [] }),
          { status: 200, headers: { "Content-Type": "application/json" } }
        );
      }

      const targetMembershipError = await requireActiveHomeMember(supabase, home_id, target_user_id);
      if (targetMembershipError) {
        return targetMembershipError;
      }

      members = [{ user_id: target_user_id }];
    } else if (event_type === "invitation_received") {
      // For invitations, we only notify the invited user, NOT the home members.
      const { data: invitation } = await supabase
        .from("invitations")
        .select("email")
        .eq("id", reference_id)
        .single();
      
      if (invitation?.email) {
        // Find if this email belongs to a registered user
        const { data: invitee } = await supabase
          .from("users")
          .select("id")
          .eq("email", invitation.email)
          .single();

        if (invitee) {
          members = [{ user_id: invitee.id }];
        }
      }
    } else if (Array.isArray(target_user_ids) && target_user_ids.length > 0) {
      const uniqueTargetIds = [...new Set(
        target_user_ids.filter((id: unknown) => typeof id === "string" && id !== actor_id),
      )] as string[];

      for (const targetUserId of uniqueTargetIds) {
        const targetMembershipError = await requireActiveHomeMember(supabase, home_id, targetUserId);
        if (targetMembershipError) {
          continue;
        }
        members.push({ user_id: targetUserId });
      }
    } else {
      // 1. Get home members (exclude actor)
      const { data: homeMembers, error: membersError } = await supabase
        .from("home_members")
        .select("user_id")
        .eq("home_id", home_id)
        .eq("status", "active")
        .is("deleted_at", null)
        .neq("user_id", actor_id);

      if (membersError) {
        console.error("Error fetching members:", membersError);
        return new Response(
          JSON.stringify({ error: "Failed to fetch home members" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }
      
      if (homeMembers) {
        members = homeMembers;
      }
    }

    if (members.length === 0) {
      return new Response(
        JSON.stringify({ success: true, notifications_sent: 0, recipients: [] }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Get actor name
    const { data: actorUser } = await supabase
      .from("users")
      .select("full_name")
      .eq("id", actor_id)
      .single();

    const actorName = actorUser?.full_name || "Someone";

    // 3. Get home name
    const { data: home } = await supabase
      .from("homes")
      .select("name")
      .eq("id", home_id)
      .single();

    const homeName = home?.name || "Home";

    const notificationsSent: string[] = [];
    const notificationsBatched: string[] = [];
    const fcmTokensSent: string[] = [];

    for (const member of members) {
      const userId = member.user_id;

      // 4. Check notification preferences (column-based schema)
      if (preferenceColumn) {
        const { data: pref } = await supabase
          .from("notification_preferences")
          .select(preferenceColumn)
          .eq("user_id", userId)
          .eq("home_id", home_id)
          .maybeSingle();

        if (pref && pref[preferenceColumn] === false) {
          continue; // User has disabled this notification type
        }
      }

      // 5. Check throttling (2-minute window)
      const batchKey = `${userId}:${home_id}:${category}`;
      const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();

      const { data: recentNotification } = await supabase
        .from("notifications")
        .select("id, title, body")
        .eq("batch_key", batchKey)
        .gte("created_at", twoMinutesAgo)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      // 6. Get user locale preference
      const { data: targetUser } = await supabase
        .from("users")
        .select("locale")
        .eq("id", userId)
        .single();

      const locale = targetUser?.locale || "en";
      const templatesRecord = templates as Record<string, any>;
      const safeLocale = Object.prototype.hasOwnProperty.call(templatesRecord, locale) ? locale : "en";
      const localeTemplates = templatesRecord[safeLocale] || templates.en;
      const safeEventType = Object.prototype.hasOwnProperty.call(localeTemplates, event_type) ? event_type : "item_added";
      const template = localeTemplates[safeEventType] || templates.en.item_added;

      const rendered = renderTemplate(template, {
        actor: actorName,
        item: context?.item_name || "item",
        list: context?.list_name || "list",
        expense: context?.expense_description || context?.expense || "expense",
        amount: context?.amount || "",
        quantity: context?.quantity || "",
        days: context?.days || "",
        task: context?.task_title || "task",
        home: homeName,
        member: context?.member_name || actorName,
      });
      const shouldSendPush = shouldSendPushForEvent(event_type);
      const shouldSendQuietPush = shouldSendQuietPushForEvent(event_type);

      if (recentNotification) {
        // Update existing notification (batch)
        const { error: updateError } = await supabase
          .from("notifications")
          .update({
            title: rendered.title,
            body: rendered.body,
            is_read: false,
            updated_at: new Date().toISOString(),
          })
          .eq("id", recentNotification.id);

        if (updateError) {
          console.error("Error batching notification:", updateError);
          continue;
        }

        notificationsBatched.push(userId);

        const { data: tokens } = await supabase
          .from("device_tokens")
          .select("token, platform")
          .eq("user_id", userId)
          .eq("is_active", true);

        if (shouldSendPush && tokens && tokens.length > 0) {
          for (const tokenData of tokens) {
            const sent = await sendFCMNotification(
              tokenData.token,
              tokenData.platform,
              rendered.title,
              rendered.body,
              {
                route: targetRoute,
                notification_id: recentNotification.id,
                event_type: event_type,
                category: category,
                home_id: home_id,
                quiet: shouldSendQuietPush ? "true" : "false",
              },
            );

            if (sent) {
              fcmTokensSent.push(tokenData.token);
            }
          }
        }
      } else {
        // Create new notification
        const { data: newNotification, error: insertError } = await supabase
          .from("notifications")
          .insert({
            user_id: userId,
            home_id: home_id,
            category: category,
            type: event_type,
            title: rendered.title,
            body: rendered.body,
            actor_id: actor_id,
            target_route: targetRoute,
            reference_id: reference_id,
            reference_type: reference_type,
            batch_key: batchKey,
          })
          .select("id")
          .single();

        if (insertError || !newNotification) {
          console.error("Error creating notification:", insertError);
          continue;
        }

        notificationsSent.push(userId);

        // 7. Get FCM tokens and send push notification
        const { data: tokens } = await supabase
          .from("device_tokens")
          .select("token, platform")
          .eq("user_id", userId)
          .eq("is_active", true);

        if (shouldSendPush && tokens && tokens.length > 0) {
          for (const tokenData of tokens) {
            const sent = await sendFCMNotification(
              tokenData.token,
              tokenData.platform,
              rendered.title,
              rendered.body,
              {
                route: targetRoute,
                notification_id: newNotification.id,
                event_type: event_type,
                category: category,
                home_id: home_id,
                quiet: shouldSendQuietPush ? "true" : "false",
              },
            );

            if (sent) {
              fcmTokensSent.push(tokenData.token);
            }
          }
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        notifications_sent: notificationsSent.length,
        notifications_batched: notificationsBatched.length,
        fcm_tokens_sent: fcmTokensSent.length,
        recipients: [...notificationsSent, ...notificationsBatched],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in send-notification:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
