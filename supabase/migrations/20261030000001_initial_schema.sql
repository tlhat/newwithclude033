-- =============================================================================
-- Haneen Kids v3.6 — Supabase / PostgreSQL Initial Cloud Schema
-- Migration: 20261030000001_initial_schema.sql
-- Features:
--   * Normalized tables for Parent Accounts, Multi-Child Profiles, Educational
--     Progress, Activity Logs, Favorites, Parent Videos, Subscriptions,
--     Payment Transactions, and Idempotent Offline Sync Ledger.
--   * Strict foreign keys with ON DELETE CASCADE for full child/parent data erasure.
--   * Data minimization for children's privacy (no raw voice recordings, no GPS,
--     no external ad identifiers).
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Automatic updated_at & version_seq trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at_and_version()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- 1. Parent Accounts Table (1-to-1 with auth.users)
CREATE TABLE IF NOT EXISTS public.parent_accounts (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email_or_phone TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL CHECK (char_length(trim(full_name)) >= 2),
  auth_provider TEXT NOT NULL DEFAULT 'email' CHECK (auth_provider IN ('email', 'google', 'demo')),
  pin_hash TEXT NOT NULL,
  pin_salt TEXT NOT NULL,
  failed_pin_attempts INT NOT NULL DEFAULT 0 CHECK (failed_pin_attempts >= 0),
  pin_lockout_until TIMESTAMPTZ,
  failed_password_attempts INT NOT NULL DEFAULT 0 CHECK (failed_password_attempts >= 0),
  password_lockout_until TIMESTAMPTZ,
  warm_evening_filter BOOLEAN NOT NULL DEFAULT FALSE,
  email_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  daily_smart_suggestions_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  voice_assistant_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  active_child_id TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_parent_accounts_updated_at
BEFORE UPDATE ON public.parent_accounts
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at_and_version();

-- 2. Child Profiles Table (Data Minimization: nickname/first name, age bracket, avatar emoji only)
CREATE TABLE IF NOT EXISTS public.child_profiles (
  id TEXT PRIMARY KEY,
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL CHECK (char_length(trim(display_name)) BETWEEN 1 AND 40),
  age_group TEXT NOT NULL DEFAULT '3–6 سنوات',
  chosen_avatar TEXT NOT NULL DEFAULT '🦁',
  education_level TEXT NOT NULL DEFAULT 'مبتدئ' CHECK (education_level IN ('مبتدئ', 'متوسط', 'متقدم')),
  daily_time_limit INT NOT NULL DEFAULT 20 CHECK (daily_time_limit BETWEEN 5 AND 180),
  used_minutes_today INT NOT NULL DEFAULT 0 CHECK (used_minutes_today >= 0),
  watched_videos_today INT NOT NULL DEFAULT 0 CHECK (watched_videos_today >= 0),
  stars_earned INT NOT NULL DEFAULT 0 CHECK (stars_earned >= 0),
  intelligence_points INT NOT NULL DEFAULT 10 CHECK (intelligence_points >= 0),
  games_completed_count INT NOT NULL DEFAULT 0 CHECK (games_completed_count >= 0),
  correct_pronunciations_count INT NOT NULL DEFAULT 0 CHECK (correct_pronunciations_count >= 0),
  allow_microphone BOOLEAN NOT NULL DEFAULT TRUE,
  allow_external_videos BOOLEAN NOT NULL DEFAULT TRUE,
  offline_only_mode BOOLEAN NOT NULL DEFAULT FALSE,
  reduce_motion BOOLEAN NOT NULL DEFAULT FALSE,
  high_contrast_mode BOOLEAN NOT NULL DEFAULT FALSE,
  is_device_remotely_locked BOOLEAN NOT NULL DEFAULT FALSE,
  remote_lock_reason_message TEXT NOT NULL DEFAULT '',
  current_live_status TEXT NOT NULL DEFAULT 'متصل — يتصفح أكاديمية وقصص حنين',
  family_pairing_code TEXT NOT NULL DEFAULT 'HK-8824',
  last_active_academy_lesson_id TEXT NOT NULL DEFAULT 'les_arabic_alif',
  unlocked_cosmetics JSONB NOT NULL DEFAULT '["hero_crown_basic"]'::jsonb,
  practiced_vocabulary JSONB NOT NULL DEFAULT '[]'::jsonb,
  unlocked_achievements JSONB NOT NULL DEFAULT '{}'::jsonb,
  game_progress_by_game_id JSONB NOT NULL DEFAULT '{}'::jsonb,
  sync_version_seq BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_child_profiles_parent_id ON public.child_profiles(parent_id);

CREATE TRIGGER trg_child_profiles_updated_at
BEFORE UPDATE ON public.child_profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at_and_version();

-- 3. Child Educational Progress Table (Non-duplicating lessons, game levels & activities)
CREATE TABLE IF NOT EXISTS public.child_educational_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL CHECK (item_type IN ('lesson', 'game_level', 'activity', 'achievement')),
  item_key TEXT NOT NULL,
  level_reached INT NOT NULL DEFAULT 1 CHECK (level_reached >= 1),
  stars_awarded INT NOT NULL DEFAULT 0 CHECK (stars_awarded >= 0),
  iq_points_awarded INT NOT NULL DEFAULT 0 CHECK (iq_points_awarded >= 0),
  learned_word TEXT NOT NULL DEFAULT '',
  idempotency_key TEXT UNIQUE NOT NULL,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (child_id, item_type, item_key)
);

CREATE INDEX IF NOT EXISTS idx_child_progress_parent_child
  ON public.child_educational_progress(parent_id, child_id);

-- 4. Child Activity Timeline Logs (Separately clearable without losing educational progress)
CREATE TABLE IF NOT EXISTS public.child_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
  action_title TEXT NOT NULL,
  category_badge TEXT NOT NULL DEFAULT 'نشاط',
  client_event_id TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_child_activity_logs_parent_child
  ON public.child_activity_logs(parent_id, child_id, created_at DESC);

-- 5. Child Favorites (Stories & Liked Videos per Child)
CREATE TABLE IF NOT EXISTS public.child_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL REFERENCES public.child_profiles(id) ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('video', 'story')),
  target_id TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (child_id, target_type, target_id)
);

CREATE INDEX IF NOT EXISTS idx_child_favorites_parent_child
  ON public.child_favorites(parent_id, child_id);

-- 6. Parent Videos Library & Approval Queue (Staging before publishing to child feed)
CREATE TABLE IF NOT EXISTS public.parent_videos (
  id TEXT NOT NULL,
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'bedtime',
  age_group TEXT NOT NULL DEFAULT '3–6 سنوات',
  repeat_phrase TEXT NOT NULL DEFAULT '',
  active_activity TEXT NOT NULL DEFAULT '',
  stream_url TEXT NOT NULL,
  audio_stream_url TEXT NOT NULL DEFAULT '',
  original_source_url TEXT NOT NULL DEFAULT '',
  emoji TEXT NOT NULL DEFAULT '🌟',
  quality_badge TEXT NOT NULL DEFAULT '1080p HD',
  is_approved_by_parent BOOLEAN NOT NULL DEFAULT FALSE,
  is_broken_stream BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (parent_id, id)
);

CREATE TRIGGER trg_parent_videos_updated_at
BEFORE UPDATE ON public.parent_videos
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at_and_version();

-- 7. Subscriptions Table (Server-Authoritative ONLY; clients have SELECT only)
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL UNIQUE REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL DEFAULT 'trial_1day',
  lifecycle_status TEXT NOT NULL DEFAULT 'trial'
    CHECK (lifecycle_status IN ('trial', 'active', 'expired', 'cancelled', 'refunded')),
  trial_start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expiry_date TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  has_used_free_trial BOOLEAN NOT NULL DEFAULT TRUE,
  active_transaction_id TEXT,
  entitlement_token TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_subscriptions_updated_at
BEFORE UPDATE ON public.subscriptions
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at_and_version();

-- 8. Payment Transactions Table (Server-Authoritative ONLY; clients have SELECT only)
CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id TEXT PRIMARY KEY,
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL,
  plan_title TEXT NOT NULL,
  amount_egp INT NOT NULL CHECK (amount_egp >= 0),
  currency TEXT NOT NULL DEFAULT 'EGP' CHECK (currency = 'EGP'),
  payment_method_id TEXT NOT NULL,
  payment_method_name TEXT NOT NULL,
  payer_identifier_masked TEXT NOT NULL,
  reference_code TEXT UNIQUE NOT NULL,
  webhook_event_id TEXT UNIQUE,
  webhook_signature_verified BOOLEAN NOT NULL DEFAULT FALSE,
  receipt_signature TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'failed', 'refunded', 'cancelled')),
  failure_reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_parent_id
  ON public.payment_transactions(parent_id, created_at DESC);

-- 9. Offline Sync Idempotency Ledger (Prevents duplicate mutation execution across retries/devices)
CREATE TABLE IF NOT EXISTS public.sync_mutation_ledger (
  idempotency_key TEXT PRIMARY KEY,
  parent_id UUID NOT NULL REFERENCES public.parent_accounts(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL DEFAULT '',
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_mutation_ledger_parent
  ON public.sync_mutation_ledger(parent_id, applied_at DESC);
