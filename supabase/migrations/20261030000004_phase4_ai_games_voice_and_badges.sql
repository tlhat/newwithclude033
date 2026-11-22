-- =============================================================================
-- Haneen Kids v3.8 — Phase 4 Educational AI, Voice & Performance Controls Migration
-- Adds sound/voice toggle, low-memory performance mode, and cognitive domain scores
-- =============================================================================

ALTER TABLE public.child_profiles
  ADD COLUMN IF NOT EXISTS allow_sound_effects_and_voice BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS low_memory_performance_mode BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS cognitive_skill_scores_by_domain JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.child_profiles.allow_sound_effects_and_voice IS
  'Parental control for Haneen voice guidance and game sound effects.';
COMMENT ON COLUMN public.child_profiles.low_memory_performance_mode IS
  'Battery & memory optimization mode for low-end and mid-range Android devices.';
COMMENT ON COLUMN public.child_profiles.cognitive_skill_scores_by_domain IS
  'Privacy-safe numeric skill radar scores (0..100) across 8 cognitive domains; never stores raw audio or PII.';
