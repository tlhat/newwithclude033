-- =============================================================================
-- Haneen Kids v3.9 — Phase 5 ElevenLabs Voice Personas, Dialect & Speed Migration
-- Adds parental voice persona, dialect (Egyptian / MSA), and speed settings
-- =============================================================================

ALTER TABLE public.child_profiles
  ADD COLUMN IF NOT EXISTS preferred_voice_persona_id TEXT NOT NULL DEFAULT 'haneen'
    CHECK (preferred_voice_persona_id IN ('haneen', 'teacher', 'storyteller', 'cheerful_friend', 'calm_assistant')),
  ADD COLUMN IF NOT EXISTS preferred_voice_dialect TEXT NOT NULL DEFAULT 'msa'
    CHECK (preferred_voice_dialect IN ('msa', 'egyptian')),
  ADD COLUMN IF NOT EXISTS preferred_voice_speed NUMERIC(3,2) NOT NULL DEFAULT 1.00
    CHECK (preferred_voice_speed BETWEEN 0.70 AND 1.20);

COMMENT ON COLUMN public.child_profiles.preferred_voice_persona_id IS
  'Selected ElevenLabs voice persona (haneen, teacher, storyteller, cheerful_friend, calm_assistant).';
COMMENT ON COLUMN public.child_profiles.preferred_voice_dialect IS
  'Selected Arabic dialect for voice synthesis (msa: الفصحى, egyptian: اللهجة المصرية).';
COMMENT ON COLUMN public.child_profiles.preferred_voice_speed IS
  'Playback and synthesis speech rate multiplier (0.70 to 1.20).';
