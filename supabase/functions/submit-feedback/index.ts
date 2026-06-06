// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
// @ts-ignore: VS Code's TypeScript service does not resolve Deno JSR imports; Deno/Supabase resolves this at runtime.
import { createClient } from "jsr:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_WINDOW_MINUTES = 5;

async function checkRateLimit(userId: string, endpoint: string): Promise<Response | null> {
  const windowStart = new Date();
  windowStart.setSeconds(0, 0);

  const { data, error } = await supabase.rpc("check_and_increment_rate_limit", {
    p_user_id: userId,
    p_endpoint: endpoint,
    p_window_start: windowStart.toISOString(),
    p_max_requests: RATE_LIMIT_MAX,
  });

  if (error) {
    console.error(JSON.stringify({ event: "rate_limit_rpc_failed", endpoint, error: error.message }));
    return null;
  }

  if (data === false) {
    return new Response(
      JSON.stringify({ error: "Rate limit exceeded. Try again later." }),
      { status: 429, headers: { "Content-Type": "application/json", "Retry-After": String(RATE_LIMIT_WINDOW_MINUTES * 60) } },
    );
  }
  return null;
}

Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const rateLimitResponse = await checkRateLimit(user.id, "submit-feedback");
    if (rateLimitResponse) return rateLimitResponse;

    // Parse request body
    const body = await req.json();
    const { feedback_type, description, star_rating, device_info, screen_route, app_logs } = body;

    // Validate feedback_type
    if (!feedback_type || !["bug", "survey"].includes(feedback_type)) {
      return new Response(
        JSON.stringify({ error: "Invalid feedback_type" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate description
    if (!description || typeof description !== "string" || description.trim().length < 1 || description.length > 2000) {
      return new Response(
        JSON.stringify({ error: "description is required (1-2000 characters)" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate star_rating for surveys
    if (feedback_type === "survey") {
      if (star_rating === undefined || star_rating === null) {
        return new Response(
          JSON.stringify({ error: "star_rating required for surveys" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }
      if (typeof star_rating !== "number" || star_rating < 1 || star_rating > 5) {
        return new Response(
          JSON.stringify({ error: "star_rating must be 1-5" }),
          { status: 400, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    // Validate star_rating not present for bugs
    if (feedback_type === "bug" && star_rating !== undefined && star_rating !== null) {
      return new Response(
        JSON.stringify({ error: "star_rating must be null for bug reports" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate device_info
    if (!device_info || typeof device_info !== "object") {
      return new Response(
        JSON.stringify({ error: "device_info is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate app_logs (optional, max 50 entries)
    let sanitizedLogs: string[] | null = null;
    if (app_logs && Array.isArray(app_logs)) {
      sanitizedLogs = app_logs.slice(0, 50).map((log: unknown) => String(log));
    }

    // Insert feedback
    const { data, error: insertError } = await supabase
      .from("beta_feedback")
      .insert({
        user_id: user.id,
        feedback_type,
        description: description.trim(),
        star_rating: feedback_type === "survey" ? star_rating : null,
        device_info,
        screen_route: screen_route || null,
        app_logs: sanitizedLogs,
      })
      .select("id")
      .single();

    if (insertError) {
      console.error(JSON.stringify({ event: "feedback_insert_failed", userId: user.id, error: insertError.message }));
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(JSON.stringify({ event: "feedback_submitted", feedbackId: data.id, userId: user.id, feedbackType: feedback_type }));

    return new Response(
      JSON.stringify({ id: data.id, status: "received" }),
      { status: 201, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error(JSON.stringify({ event: "submit_feedback_unhandled", error: error instanceof Error ? error.message : String(error) }));
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
