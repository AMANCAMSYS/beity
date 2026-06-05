// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient } from "jsr:@supabase/supabase-js@2";

declare const Deno: any;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${supabaseServiceKey}`) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    });
  }

  try {
    const { data, error } = await supabase
      .from("notifications")
      .delete()
      .lt("created_at", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString())
      .select("id");

    if (error) {
      console.error("Error deleting old notifications:", error);
      return new Response(
        JSON.stringify({ error: "Failed to delete old notifications" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const deletedCount = data?.length || 0;
    console.log(`Deleted ${deletedCount} old notifications`);

    return new Response(
      JSON.stringify({ success: true, deleted_count: deletedCount }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in cleanup-old-notifications:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
