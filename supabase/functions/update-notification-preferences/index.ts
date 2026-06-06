// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

declare const Deno: any;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

type PreferenceColumn =
  | "item_added"
  | "item_completed"
  | "low_stock"
  | "expiry_alert"
  | "expense_added"
  | "task_assigned"
  | "task_due";

const VALID_COLUMNS: PreferenceColumn[] = [
  "item_added",
  "item_completed",
  "low_stock",
  "expiry_alert",
  "expense_added",
  "task_assigned",
  "task_due",
];

function assignPreferenceValue(
  updateData: Partial<Record<PreferenceColumn, boolean>>,
  column: PreferenceColumn,
  value: boolean,
) {
  switch (column) {
    case "item_added":
      updateData.item_added = value;
      break;
    case "item_completed":
      updateData.item_completed = value;
      break;
    case "low_stock":
      updateData.low_stock = value;
      break;
    case "expiry_alert":
      updateData.expiry_alert = value;
      break;
    case "expense_added":
      updateData.expense_added = value;
      break;
    case "task_assigned":
      updateData.task_assigned = value;
      break;
    case "task_due":
      updateData.task_due = value;
      break;
  }
}

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
    const updateData: Partial<Record<PreferenceColumn, boolean>> = {};
    for (const col of VALID_COLUMNS) {
      const descriptor = Object.getOwnPropertyDescriptor(preferences, col);
      if (descriptor && typeof descriptor.value === "boolean") {
        assignPreferenceValue(updateData, col, descriptor.value);
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
        { onConflict: "user_id,home_id" },
      )
      .select()
      .single();

    if (error) {
      console.error(JSON.stringify({ event: "preferences_upsert_failed", userId: user.id, homeId: home_id, error: error.message }));
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
    console.error(JSON.stringify({ event: "update_preferences_unhandled", error: error instanceof Error ? error.message : String(error) }));
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
