// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req: Request) => {
  try {
    // Verify JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const { limit = 20, offset = 0, home_id, category, unread_only = false } = await req.json();

    // Build query
    let query = supabase
      .from("notifications")
      .select("*", { count: "exact" })
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (home_id) {
      query = query.eq("home_id", home_id);
    }

    if (category) {
      query = query.eq("category", category);
    }

    if (unread_only) {
      query = query.eq("is_read", false);
    }

    const { data: notifications, error: queryError, count } = await query;

    if (queryError) {
      console.error(JSON.stringify({ event: "notification_query_failed", userId: user.id, error: queryError.message }));
      return new Response(
        JSON.stringify({ error: "Failed to fetch notifications" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Get unread count
    const { count: unreadCount } = await supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("is_read", false);

    return new Response(
      JSON.stringify({
        notifications: notifications || [],
        total_count: count || 0,
        unread_count: unreadCount || 0,
        has_more: (offset + limit) < (count || 0),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error(JSON.stringify({ event: "get_history_unhandled", error: error instanceof Error ? error.message : String(error) }));
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
