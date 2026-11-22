// =============================================================================
// Supabase Edge Function: payment-webhook-receiver
// Path: supabase/functions/payment-webhook-receiver/index.ts
// Purpose:
//   * Ready-to-connect Webhook endpoint for Egyptian payment gateways (Paymob / Fawry / Kashier).
//   * Verifies HMAC-SHA256 webhook signature, currency === 'EGP', exact plan price,
//     and idempotency (`webhook_event_id` & `reference_code`).
//   * Uses `SUPABASE_SERVICE_ROLE_KEY` on the server to write to `payment_transactions`
//     and `subscriptions` (since client roles are blocked by RLS from writing to them).
// =============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const PLAN_PRICES_EGP: Record<string, { price: number; days: number; title: string }> = {
  weekly_flex: { price: 45, days: 7, title: "باقة الأسبوع المرنة" },
  monthly_family: { price: 120, days: 30, title: "الباقة الشهرية الذكية" },
  quarterly_plus: { price: 280, days: 90, title: "باقة الـ ٣ شهور التوفيرية" },
  annual_vip: { price: 799, days: 365, title: "باقة العائلة السنوية VIP" },
};

async function verifyWebhookHmac(rawBody: string, signatureHex: string, secret: string): Promise<boolean> {
  if (!secret || !signatureHex) return false;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign("HMAC", key, encoder.encode(rawBody));
  const computedHex = Array.from(new Uint8Array(sigBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return computedHex === signatureHex.toLowerCase();
}

serve(async (req: Request) => {
  try {
    const rawBody = await req.text();
    const webhookSig = req.headers.get("x-webhook-signature") ?? "";
    const webhookSecret = Deno.env.get("PAYMENT_WEBHOOK_SECRET") ?? "";

    const isSigValid = await verifyWebhookHmac(rawBody, webhookSig, webhookSecret);
    if (!isSigValid) {
      return new Response(
        JSON.stringify({ verified: false, error: "Invalid webhook HMAC signature" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    const payload = JSON.parse(rawBody);
    const parentId: string = payload.parentId ?? "";
    const planId: string = payload.planId ?? "";
    const amountEgp: number = Number(payload.amountEgp ?? -1);
    const currency: string = String(payload.currency ?? "").toUpperCase();
    const transactionId: string = String(payload.transactionId ?? "").trim();
    const webhookEventId: string = String(payload.webhookEventId ?? "").trim();
    const referenceCode: string = String(payload.referenceCode ?? "").trim().toUpperCase();
    const eventType: string = String(payload.eventType ?? "payment.succeeded");

    const planSpec = PLAN_PRICES_EGP[planId];
    if (!parentId || !planSpec || currency !== "EGP" || amountEgp !== planSpec.price || !transactionId || !webhookEventId) {
      return new Response(
        JSON.stringify({ verified: false, error: "Invalid payment amount, currency, or identifiers" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Idempotency check: prevent duplicate webhook processing
    const { data: existingTx } = await supabaseAdmin
      .from("payment_transactions")
      .select("id, status")
      .or(`id.eq.${transactionId},webhook_event_id.eq.${webhookEventId},reference_code.eq.${referenceCode}`)
      .maybeSingle();

    if (existingTx && eventType === "payment.succeeded") {
      return new Response(
        JSON.stringify({ verified: false, error: "Duplicate transaction or webhook event" }),
        { status: 409, headers: { "Content-Type": "application/json" } },
      );
    }

    if (eventType === "payment.refunded" || eventType === "subscription.cancelled") {
      const nextStatus = eventType === "payment.refunded" ? "refunded" : "cancelled";
      await supabaseAdmin
        .from("payment_transactions")
        .update({ status: nextStatus })
        .eq("id", transactionId);

      await supabaseAdmin
        .from("subscriptions")
        .update({
          lifecycle_status: nextStatus,
          expiry_date: new Date().toISOString(),
          entitlement_token: "",
        })
        .eq("parent_id", parentId);

      return new Response(
        JSON.stringify({ verified: true, status: nextStatus }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    const expiryDate = new Date(Date.now() + planSpec.days * 86400 * 1000).toISOString();
    const entitlementToken = `ent_srv_${transactionId}_${Date.now()}`;

    await supabaseAdmin.from("payment_transactions").insert({
      id: transactionId,
      parent_id: parentId,
      plan_id: planId,
      plan_title: planSpec.title,
      amount_egp: amountEgp,
      currency: "EGP",
      payment_method_id: payload.paymentMethodId ?? "instapay",
      payment_method_name: payload.paymentMethodName ?? "InstaPay",
      payer_identifier_masked: payload.payerIdentifierMasked ?? "***",
      reference_code: referenceCode,
      webhook_event_id: webhookEventId,
      webhook_signature_verified: true,
      receipt_signature: webhookSig,
      status: "verified",
    });

    await supabaseAdmin.from("subscriptions").upsert({
      parent_id: parentId,
      plan_id: planId,
      lifecycle_status: "active",
      expiry_date: expiryDate,
      has_used_free_trial: true,
      active_transaction_id: transactionId,
      entitlement_token: entitlementToken,
    });

    return new Response(
      JSON.stringify({
        verified: true,
        status: "active",
        planId,
        amountEgp,
        currency: "EGP",
        transactionId,
        webhookEventId,
        webhookVerified: true,
        webhookSignature: webhookSig,
        expiryDate,
        entitlementToken,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ verified: false, error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
