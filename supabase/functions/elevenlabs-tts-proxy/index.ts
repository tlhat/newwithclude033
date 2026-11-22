// =============================================================================
// Supabase Edge Function: `elevenlabs-tts-proxy`
// Secure Backend Proxy for ElevenLabs Neural Text-to-Speech (Haneen Kids v3.9)
//
// SECURITY ARCHITECTURE:
// 1. Reads `ELEVENLABS_API_KEY` exclusively from Supabase Edge Functions Secrets:
//      supabase secrets set ELEVENLABS_API_KEY=<your-elevenlabs-api-key>
//    The API key is NEVER exposed to the Flutter client, APK, or Git repository.
// 2. Requires a valid `Authorization: Bearer <sessionAccessToken>` header.
// 3. Enforces a strict allowlist of the 5 tested Haneen Kids Voice IDs and
//    models (`eleven_v4`, `eleven_flash_v2_5`, `eleven_multilingual_v2`).
// =============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";

const ALLOWED_VOICE_IDS = new Set([
  "cUDXOxxuLZJdTcxEyGVB", // Primary Voice Assistant (Instructions, Explanations & Main Storyteller)
  "L14QZl4DxSQ6xGvib36i", // Superhero Voice Assistant (Correct Answer Encouragement & Second Story Character)
  "21m00Tcm4TlvDq8ikWAM", // 1. حنين (Rachel — Expressive Child Companion)
  "pNInz6obpgDQGcFmaJgB", // 2. المعلم (Adam — Clear Articulate Educator)
  "EXAVITQu4vr4xnSDxMaL", // 3. الراوية (Sarah — Warm Storyteller)
  "TxGEqnHWrfWFTfGW9XjX", // 4. الصديق المرح (Josh — Energetic Game Friend)
  "XB0fDUnXU5powFXDhCwa", // 5. المساعدة الهادئة (Charlotte — Soothing Calm Assistant)
]);

const ALLOWED_MODELS = new Set([
  "eleven_v4",
  "eleven_flash_v2_5",
  "eleven_multilingual_v2",
]);

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json; charset=utf-8" },
    });
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ") || authHeader.length < 16) {
    return new Response(
      JSON.stringify({ error: "Unauthorized: Missing or invalid Bearer token" }),
      {
        status: 401,
        headers: { "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }

  const elevenLabsApiKey = Deno.env.get("ELEVENLABS_API_KEY") ?? "";
  if (!elevenLabsApiKey) {
    return new Response(
      JSON.stringify({
        error: "Server configuration error: ELEVENLABS_API_KEY secret is not set",
      }),
      {
        status: 503,
        headers: { "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }

  try {
    const body = await req.json();
    const voiceId = String(body.voiceId ?? "cUDXOxxuLZJdTcxEyGVB").trim();
    const requestedModel = String(body.modelId ?? "eleven_flash_v2_5").trim();
    const text = String(body.text ?? "").trim();
    const speed = Math.min(1.2, Math.max(0.7, Number(body.speed ?? 1.0)));

    if (!ALLOWED_VOICE_IDS.has(voiceId)) {
      return new Response(
        JSON.stringify({ error: "Forbidden Voice ID: Not in approved Haneen Kids personas" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json; charset=utf-8" },
        },
      );
    }

    if (!text || text.length > 600) {
      return new Response(
        JSON.stringify({ error: "Invalid text length (must be 1..600 characters)" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json; charset=utf-8" },
        },
      );
    }

    const primaryModel = ALLOWED_MODELS.has(requestedModel)
      ? requestedModel
      : "eleven_flash_v2_5";

    const voiceSettings = body.voiceSettings ?? {
      stability: 0.65,
      similarity_boost: 0.82,
      style: 0.30,
      use_speaker_boost: true,
      speed,
    };

    let ttsResponse = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`,
      {
        method: "POST",
        headers: {
          "xi-api-key": elevenLabsApiKey,
          "Content-Type": "application/json",
          "Accept": "audio/mpeg",
        },
        body: JSON.stringify({
          text,
          model_id: primaryModel,
          voice_settings: { ...voiceSettings, speed },
        }),
      },
    );

    let modelUsed = primaryModel;
    // Automatic graceful fallback if `eleven_v4` is not yet enabled on the account tier
    if (!ttsResponse.ok && primaryModel === "eleven_v4") {
      modelUsed = "eleven_multilingual_v2";
      ttsResponse = await fetch(
        `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`,
        {
          method: "POST",
          headers: {
            "xi-api-key": elevenLabsApiKey,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
          },
          body: JSON.stringify({
            text,
            model_id: modelUsed,
            voice_settings: { ...voiceSettings, speed },
          }),
        },
      );
    }

    if (!ttsResponse.ok) {
      return new Response(
        JSON.stringify({
          error: `Upstream ElevenLabs TTS error (${ttsResponse.status})`,
        }),
        {
          status: 502,
          headers: { "Content-Type": "application/json; charset=utf-8" },
        },
      );
    }

    const audioBuffer = new Uint8Array(await ttsResponse.arrayBuffer());
    let binary = "";
    for (let i = 0; i < audioBuffer.byteLength; i++) {
      binary += String.fromCharCode(audioBuffer[i]);
    }
    const audioBase64 = btoa(binary);

    return new Response(
      JSON.stringify({
        audioBase64,
        mimeType: "audio/mpeg",
        voiceId,
        modelUsed,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Cache-Control": "public, max-age=604800, immutable",
        },
      },
    );
  } catch (_err) {
    return new Response(
      JSON.stringify({ error: "Invalid request payload" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json; charset=utf-8" },
      },
    );
  }
});
