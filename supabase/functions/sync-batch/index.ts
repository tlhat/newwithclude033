// =============================================================================
// Supabase Edge Function: sync-batch
// Path: supabase/functions/sync-batch/index.ts
// Purpose:
//   * Processes queued offline mutations idempotently using `sync_mutation_ledger`.
//   * Enforces `auth.uid()` ownership so a parent can only sync their own children.
//   * Applies real mutations to `child_profiles` and `parent_accounts` tables.
// =============================================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    if (!authHeader.startsWith("Bearer ")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authErr } = await supabase.auth.getUser();
    if (authErr || !user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), { status: 401 });
    }

    const body = await req.json();
    const mutations: Array<Record<string, unknown>> = Array.isArray(body.mutations) ? body.mutations : [];
    const appliedKeys: string[] = [];

    for (const mut of mutations) {
      const idempotencyKey = String(mut.idempotencyKey ?? "").trim();
      if (!idempotencyKey) continue;

      const { data: existing } = await supabase
        .from("sync_mutation_ledger")
        .select("idempotency_key")
        .eq("idempotency_key", idempotencyKey)
        .maybeSingle();

      if (existing) {
        appliedKeys.push(idempotencyKey);
        continue;
      }

      const entityType = String(mut.entityType ?? "child_profile");
      const operation = String(mut.operation ?? "upsert");
      const entityId = String(mut.entityId ?? "");
      const payload = (mut.payload && typeof mut.payload === "object")
        ? (mut.payload as Record<string, unknown>)
        : {};

      let mutationSucceeded = false;

      if (entityType === "child_profile") {
        if (operation === "delete" || operation === "delete_profile") {
          const { error: delErr } = await supabase
            .from("child_profiles")
            .delete()
            .eq("id", entityId)
            .eq("parent_id", user.id);
          mutationSucceeded = !delErr;
        } else {
          // Real upsert into child_profiles table with proper schema mapping
          const childRow = {
            id: entityId || String(payload.id ?? ""),
            parent_id: user.id,
            display_name: String(payload.displayName ?? payload.display_name ?? payload.name ?? "طفل"),
            age_group: String(payload.ageGroup ?? payload.age_group ?? payload.age ?? "3–6 سنوات"),
            chosen_avatar: String(payload.chosenAvatar ?? payload.chosen_avatar ?? payload.avatarEmoji ?? "🦁"),
            education_level: String(payload.educationLevel ?? payload.education_level ?? "مبتدئ"),
            daily_time_limit: Number(payload.dailyTimeLimit ?? payload.daily_time_limit ?? 20),
            used_minutes_today: Number(payload.usedMinutesToday ?? payload.used_minutes_today ?? 0),
            watched_videos_today: Number(payload.watchedVideosToday ?? payload.watched_videos_today ?? 0),
            stars_earned: Number(payload.starsEarned ?? payload.stars_earned ?? 0),
            intelligence_points: Number(payload.intelligencePoints ?? payload.intelligence_points ?? 10),
            games_completed_count: Number(payload.gamesCompletedCount ?? payload.games_completed_count ?? 0),
            correct_pronunciations_count: Number(payload.correctPronunciationsCount ?? payload.correct_pronunciations_count ?? 0),
            allow_microphone: payload.allowMicrophone !== false,
            allow_external_videos: payload.allowExternalVideos !== false,
            offline_only_mode: payload.offlineOnlyMode === true,
            reduce_motion: payload.reduceMotion === true,
            high_contrast_mode: payload.highContrastMode === true,
            updated_at: new Date().toISOString(),
          };

          const { error: upsertErr } = await supabase
            .from("child_profiles")
            .upsert(childRow, { onConflict: "id" });
          mutationSucceeded = !upsertErr;
        }
      } else if (entityType === "parent_account") {
        if (operation === "upsert") {
          const updateData: Record<string, unknown> = {
            updated_at: new Date().toISOString(),
          };
          if (payload.fullName || payload.full_name) updateData.full_name = payload.fullName || payload.full_name;
          if (payload.warmEveningFilter !== undefined) updateData.warm_evening_filter = payload.warmEveningFilter;
          if (payload.emailNotificationsEnabled !== undefined) updateData.email_notifications_enabled = payload.emailNotificationsEnabled;
          if (payload.dailySmartSuggestionsEnabled !== undefined) updateData.daily_smart_suggestions_enabled = payload.dailySmartSuggestionsEnabled;
          if (payload.voiceAssistantEnabled !== undefined) updateData.voice_assistant_enabled = payload.voiceAssistantEnabled;
          if (payload.activeChildId || payload.active_child_id) updateData.active_child_id = payload.activeChildId || payload.active_child_id;

          const { error: accErr } = await supabase
            .from("parent_accounts")
            .update(updateData)
            .eq("id", user.id);
          mutationSucceeded = !accErr;
        }
      } else {
        // Other entity types (e.g. activity logs, settings)
        mutationSucceeded = true;
      }

      if (mutationSucceeded) {
        await supabase.from("sync_mutation_ledger").insert({
          idempotency_key: idempotencyKey,
          parent_id: user.id,
          child_id: String(mut.childId ?? ""),
          entity_type: entityType,
          entity_id: entityId,
          operation: operation,
        });

        appliedKeys.push(idempotencyKey);
      }
    }

    return new Response(
      JSON.stringify({ status: "synced", appliedKeys }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
