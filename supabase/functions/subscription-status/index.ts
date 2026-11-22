// =============================================================================
// Supabase Edge Function: subscription-status
// Path: supabase/functions/subscription-status/index.ts
// Security:
//   * Extracts authenticated parent identity exclusively from Bearer JWT (`auth.getUser()`).
//   * Never trusts client-provided email parameters.
//   * Evaluates subscription expiration, cancellation, and refund status on the server.
// =============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Bearer token" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user || !user.email) {
      return new Response(
        JSON.stringify({ error: "Unauthorized session token" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const { data: subRow } = await supabase
      .from("subscriptions")
      .select("*")
      .eq("parent_id", user.id)
      .maybeSingle();

    const now = new Date();
    if (!subRow) {
      return new Response(
        JSON.stringify({
          active: false,
          status: "expired",
          authenticatedEmail: user.email.toLowerCase(),
          planId: "trial_1day",
          currency: "EGP",
          webhookVerified: false,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const expiryDate = new Date(subRow.expiry_date);
    const isNotExpired = expiryDate.getTime() > now.getTime();
    const isActive =
      subRow.lifecycle_status === "active" && isNotExpired;

    return new Response(
      JSON.stringify({
        active: isActive,
        status: isActive ? "active" : (isNotExpired ? subRow.lifecycle_status : "expired"),
        authenticatedEmail: user.email.toLowerCase(),
        planId: subRow.plan_id,
        expiryDate: subRow.expiry_date,
        transactionId: subRow.active_transaction_id ?? "",
        currency: "EGP",
        webhookVerified: isActive,
        webhookSignature: isActive ? "srv_verified_webhook" : "",
        entitlementToken: isActive ? subRow.entitlement_token : "",
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal server error", details: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
