// =============================================================================
// Supabase Edge Function: submit-beta-feedback
// Path: supabase/functions/submit-beta-feedback/index.ts
// Purpose:
//   * Collects developer feedback from parents during Beta testing.
//   * Strict Data Minimization: collects device, OS, app version, language,
//     and feedback description ONLY. Strictly NO children PII.
// =============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
    }

    const body = await req.json();
    const category = String(body.category ?? "feedback").trim();
    const description = String(body.description ?? "").trim();
    const appVersion = String(body.appVersion ?? "1.0.0").trim();
    const environment = String(body.environment ?? "staging").trim();
    const uiLanguage = String(body.uiLanguage ?? "ar").trim();
    const devicePlatform = String(body.devicePlatform ?? "mobile").trim();

    if (!description) {
      return new Response(JSON.stringify({ error: "Feedback description is required" }), { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    );

    // Save to beta_feedback table if it exists
    await supabase.from("beta_feedback").insert({
      category,
      description,
      app_version: appVersion,
      environment,
      ui_language: uiLanguage,
      device_platform: devicePlatform,
      created_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({ status: "success", message: "Feedback recorded successfully" }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
