-- =============================================================================
-- Haneen Kids v3.7 — Phase 3 Adaptive Mastery Curriculum Migration
-- Adds mastery-based progression fields to `public.child_profiles`
-- =============================================================================

ALTER TABLE public.child_profiles
  ADD COLUMN IF NOT EXISTS current_curriculum_tier INTEGER NOT NULL DEFAULT 2
    CHECK (current_curriculum_tier BETWEEN 1 AND 4),
  ADD COLUMN IF NOT EXISTS skill_mastery_by_lesson_id JSONB NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS needs_remediation_lesson_ids TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

COMMENT ON COLUMN public.child_profiles.current_curriculum_tier IS
  'Progressive curriculum tier (1: تمهيدي 2-3 yrs, 2: مبتدئ 3-4 yrs, 3: متوسط 4-5 yrs, 4: متقدم 5-6 yrs). Advancement requires >= 80% mastery.';
COMMENT ON COLUMN public.child_profiles.skill_mastery_by_lesson_id IS
  'Per-lesson mastery percentage (0..100) keyed by lesson_id.';
COMMENT ON COLUMN public.child_profiles.needs_remediation_lesson_ids IS
  'Lesson IDs where the child needs alternative playful re-presentation before achieving 80% mastery.';
