import "jsr:@supabase/functions-js/edge-runtime.d.ts";
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

    const { preferences } = await req.json();

    if (!preferences || !Array.isArray(preferences)) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid preferences array" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const validCategories = ["shopping_list", "home_activity", "invitation"];
    const results = [];

    for (const pref of preferences) {
      if (!validCategories.includes(pref.category)) {
        continue; // Skip invalid categories
      }

      const { data, error } = await supabase
        .from("notification_preferences")
        .upsert(
          {
            user_id: user.id,
            category: pref.category,
            enabled: pref.enabled,
            created_by: user.id,
          },
          { onConflict: "user_id, category" }
        )
        .select()
        .single();

      if (!error && data) {
        results.push({
          category: data.category,
          enabled: data.enabled,
        });
      }
    }

    return new Response(
      JSON.stringify({ success: true, preferences: results }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in update-notification-preferences:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
