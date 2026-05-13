import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID") || "beity-ad796";
const firebaseServiceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

const supabase = createClient(supabaseUrl, supabaseServiceKey);

// Notification content templates
const templates: Record<string, Record<string, { title: string; body: string }>> = {
  en: {
    item_added: { title: "{actor} added {item}", body: "{actor} added {item} to {list}" },
    item_completed: { title: "{actor} purchased {item}", body: "{actor} marked {item} as purchased in {list}" },
    item_updated: { title: "{actor} updated {item}", body: "{actor} updated {item} in {list}" },
    member_joined: { title: "New member joined", body: "{actor} joined {home}" },
    invitation_received: { title: "Invitation", body: "You've been invited to {home} by {actor}" },
  },
  ar: {
    item_added: { title: "{actor} أضاف {item}", body: "{actor} أضاف {item} إلى {list}" },
    item_completed: { title: "{actor} اشترى {item}", body: "{actor} وضع علامة شراء على {item} في {list}" },
    item_updated: { title: "{actor} حدّث {item}", body: "{actor} حدّث {item} في {list}" },
    member_joined: { title: "عضو جديد", body: "{actor} انضم إلى {home}" },
    invitation_received: { title: "دعوة", body: "تمت دعوتك إلى {home} من قبل {actor}" },
  },
};

function getCategoryForEvent(eventType: string): string {
  switch (eventType) {
    case "item_added":
    case "item_completed":
    case "item_updated":
      return "shopping_list";
    case "member_joined":
      return "home_activity";
    case "invitation_received":
      return "invitation";
    default:
      return "home_activity";
  }
}

function getRouteForEvent(eventType: string, referenceId: string, referenceType: string): string {
  switch (referenceType) {
    case "shopping_list":
      return `/shopping-list/${referenceId}`;
    case "invitation":
      return `/invitations`;
    case "home":
      return `/homes/${referenceId}/members`;
    default:
      return `/`;
  }
}

function renderTemplate(
  template: { title: string; body: string },
  context: Record<string, string>
): { title: string; body: string } {
  let title = template.title;
  let body = template.body;
  for (const [key, value] of Object.entries(context)) {
    title = title.replace(`{${key}}`, value);
    body = body.replace(`{${key}}`, value);
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
    
    // Create JWT for Google OAuth2
    const now = Math.floor(Date.now() / 1000);
    const header = { alg: "RS256", typ: "JWT" };
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    };

    // For simplicity, use the service account key directly
    // In production, use proper JWT signing with RS256
    return null;
  } catch (e) {
    console.error("Error parsing service account:", e);
    return null;
  }
}

// Send FCM notification using legacy API (simpler, uses server key)
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<boolean> {
  const firebaseServerKey = Deno.env.get("FIREBASE_SERVER_KEY");
  
  if (!firebaseServerKey) {
    console.warn("FIREBASE_SERVER_KEY not set, skipping FCM push");
    return false;
  }

  try {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${firebaseServerKey}`,
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: title,
          body: body,
          sound: "default",
          badge: "1",
        },
        data: data,
        priority: "high",
        content_available: true,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("FCM send failed:", errorText);
      
      // If token is invalid, remove it from database
      if (errorText.includes("InvalidRegistration") || errorText.includes("NotRegistered")) {
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
    const { event_type, home_id, actor_id, reference_id, reference_type, context } = await req.json();

    if (!event_type || !home_id || !actor_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: event_type, home_id, actor_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const category = getCategoryForEvent(event_type);
    const targetRoute = getRouteForEvent(event_type, reference_id, reference_type);

    // 1. Get home members (exclude actor)
    const { data: members, error: membersError } = await supabase
      .from("home_members")
      .select("user_id")
      .eq("home_id", home_id)
      .eq("status", "active")
      .isFilter("deleted_at", null)
      .neq("user_id", actor_id);

    if (membersError) {
      console.error("Error fetching members:", membersError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch home members" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!members || members.length === 0) {
      return new Response(
        JSON.stringify({ success: true, notifications_sent: 0, recipients: [] }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 2. Get actor name
    const { data: actorProfile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", actor_id)
      .single();

    const actorName = actorProfile?.full_name || "Someone";

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

      // 4. Check notification preferences
      const { data: pref } = await supabase
        .from("notification_preferences")
        .select("enabled")
        .eq("user_id", userId)
        .eq("category", category)
        .single();

      if (pref && !pref.enabled) {
        continue; // User has disabled this category
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
      const { data: userProfile } = await supabase
        .from("profiles")
        .select("locale")
        .eq("id", userId)
        .single();

      const locale = userProfile?.locale || "en";
      const template = templates[locale]?.[event_type] || templates.en[event_type] || templates.en.item_added;

      const rendered = renderTemplate(template, {
        actor: actorName,
        item: context?.item_name || "item",
        list: context?.list_name || "list",
        home: homeName,
        member: context?.member_name || actorName,
      });

      if (recentNotification) {
        // Update existing notification (batch)
        await supabase
          .from("notifications")
          .update({
            title: rendered.title,
            body: rendered.body,
          })
          .eq("id", recentNotification.id);

        notificationsBatched.push(userId);
      } else {
        // Create new notification
        const { data: newNotification } = await supabase.from("notifications").insert({
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
        }).select("id").single();

        notificationsSent.push(userId);

        // 7. Get FCM tokens and send push notification
        const { data: tokens } = await supabase
          .from("device_tokens")
          .select("token")
          .eq("user_id", userId);

        if (tokens && tokens.length > 0) {
          for (const tokenData of tokens) {
            const sent = await sendFCMNotification(
              tokenData.token,
              rendered.title,
              rendered.body,
              {
                route: targetRoute,
                notification_id: newNotification?.id || "",
                event_type: event_type,
                home_id: home_id,
              }
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
