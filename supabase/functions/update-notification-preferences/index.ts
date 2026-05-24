import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const VALID_COLUMNS = [
  "item_added",
  "item_completed",
  "low_stock",
  "expiry_alert",
  "expense_added",
  "task_due",
];

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

Deno.serve(async (req: Request) => {
  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Verify JWT
    const authResult = await requireUser(req, supabase);
    if ("response" in authResult) {
      return authResult.response;
    }
    const user = authResult.user;

    const { home_id, preferences } = await req.json();

    if (!home_id) {
      return new Response(
        JSON.stringify({ error: "Missing home_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!preferences || typeof preferences !== "object") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid preferences object" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Build update object with only valid columns
    const updateData: Record<string, boolean> = {};
    for (const col of VALID_COLUMNS) {
      if (col in preferences && typeof preferences[col] === "boolean") {
        updateData[col] = preferences[col];
      }
    }

    if (Object.keys(updateData).length === 0) {
      return new Response(
        JSON.stringify({ error: "No valid preference fields provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Verify user is an active member of this home
    const { data: membership, error: memberError } = await supabase
      .from("home_members")
      .select("role")
      .eq("home_id", home_id)
      .eq("user_id", user.id)
      .eq("status", "active")
      .is("deleted_at", null)
      .maybeSingle();

    if (memberError || !membership) {
      return new Response(
        JSON.stringify({ error: "Access denied: not an active member of this home" }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

    // Upsert notification preferences
    const { data, error } = await supabase
      .from("notification_preferences")
      .upsert(
        {
          user_id: user.id,
          home_id: home_id,
          ...updateData,
        },
        { onConflict: "user_id, home_id" },
      )
      .select()
      .single();

    if (error) {
      console.error("Error upserting preferences:", error);
      return new Response(
        JSON.stringify({ error: "Failed to update preferences" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, preferences: data }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Error in update-notification-preferences:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
