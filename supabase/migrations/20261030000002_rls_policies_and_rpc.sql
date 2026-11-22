-- =============================================================================
-- Haneen Kids v3.6 — Row-Level Security (RLS) Policies & Server-Side RPCs
-- Migration: 20261030000002_rls_policies_and_rpc.sql
-- Security Guarantees:
--   1. Every table has RLS ENABLED and FORCED.
--   2. A parent (`auth.uid()`) can ONLY access their own `parent_accounts` row
--      and child rows where `parent_id = auth.uid()`.
--   3. `subscriptions` and `payment_transactions` are strictly READ-ONLY (`SELECT`)
--      for `authenticated` users; `INSERT`, `UPDATE`, and `DELETE` are restricted
--      exclusively to `service_role` (Edge Functions / Server Webhooks).
--   4. Two-tier child data deletion and full parent account deletion are executed
--      atomically on the server via SECURITY DEFINER RPCs verifying `auth.uid()`.
-- =============================================================================

-- Enable & Force RLS on all 9 tables
ALTER TABLE public.parent_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_accounts FORCE ROW LEVEL SECURITY;

ALTER TABLE public.child_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_profiles FORCE ROW LEVEL SECURITY;

ALTER TABLE public.child_educational_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_educational_progress FORCE ROW LEVEL SECURITY;

ALTER TABLE public.child_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_activity_logs FORCE ROW LEVEL SECURITY;

ALTER TABLE public.child_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.child_favorites FORCE ROW LEVEL SECURITY;

ALTER TABLE public.parent_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_videos FORCE ROW LEVEL SECURITY;

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.sync_mutation_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_mutation_ledger FORCE ROW LEVEL SECURITY;

-- 1. Policies for `parent_accounts`
CREATE POLICY parent_accounts_select_own ON public.parent_accounts
  FOR SELECT TO authenticated USING (auth.uid() = id);

CREATE POLICY parent_accounts_insert_own ON public.parent_accounts
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY parent_accounts_update_own ON public.parent_accounts
  FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY parent_accounts_delete_own ON public.parent_accounts
  FOR DELETE TO authenticated USING (auth.uid() = id);

-- 2. Policies for `child_profiles`
CREATE POLICY child_profiles_select_own ON public.child_profiles
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

CREATE POLICY child_profiles_insert_own ON public.child_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = parent_id);

CREATE POLICY child_profiles_update_own ON public.child_profiles
  FOR UPDATE TO authenticated USING (auth.uid() = parent_id) WITH CHECK (auth.uid() = parent_id);

CREATE POLICY child_profiles_delete_own ON public.child_profiles
  FOR DELETE TO authenticated USING (auth.uid() = parent_id);

-- 3. Policies for `child_educational_progress`
CREATE POLICY child_progress_select_own ON public.child_educational_progress
  FOR SELECT TO authenticated
  USING (
    auth.uid() = parent_id
    AND EXISTS (
      SELECT 1 FROM public.child_profiles cp
      WHERE cp.id = child_id AND cp.parent_id = auth.uid()
    )
  );

CREATE POLICY child_progress_insert_own ON public.child_educational_progress
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = parent_id
    AND EXISTS (
      SELECT 1 FROM public.child_profiles cp
      WHERE cp.id = child_id AND cp.parent_id = auth.uid()
    )
  );

CREATE POLICY child_progress_delete_own ON public.child_educational_progress
  FOR DELETE TO authenticated USING (auth.uid() = parent_id);

-- 4. Policies for `child_activity_logs`
CREATE POLICY child_logs_select_own ON public.child_activity_logs
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

CREATE POLICY child_logs_insert_own ON public.child_activity_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = parent_id
    AND EXISTS (
      SELECT 1 FROM public.child_profiles cp
      WHERE cp.id = child_id AND cp.parent_id = auth.uid()
    )
  );

CREATE POLICY child_logs_delete_own ON public.child_activity_logs
  FOR DELETE TO authenticated USING (auth.uid() = parent_id);

-- 5. Policies for `child_favorites`
CREATE POLICY child_favorites_select_own ON public.child_favorites
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

CREATE POLICY child_favorites_insert_own ON public.child_favorites
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = parent_id
    AND EXISTS (
      SELECT 1 FROM public.child_profiles cp
      WHERE cp.id = child_id AND cp.parent_id = auth.uid()
    )
  );

CREATE POLICY child_favorites_delete_own ON public.child_favorites
  FOR DELETE TO authenticated USING (auth.uid() = parent_id);

-- 6. Policies for `parent_videos`
CREATE POLICY parent_videos_select_own ON public.parent_videos
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

CREATE POLICY parent_videos_insert_own ON public.parent_videos
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = parent_id);

CREATE POLICY parent_videos_update_own ON public.parent_videos
  FOR UPDATE TO authenticated USING (auth.uid() = parent_id) WITH CHECK (auth.uid() = parent_id);

CREATE POLICY parent_videos_delete_own ON public.parent_videos
  FOR DELETE TO authenticated USING (auth.uid() = parent_id);

-- 7. Policies for `subscriptions` (READ-ONLY for authenticated clients; NO client writes!)
CREATE POLICY subscriptions_select_own ON public.subscriptions
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

-- 8. Policies for `payment_transactions` (READ-ONLY for authenticated clients; NO client writes!)
CREATE POLICY payment_transactions_select_own ON public.payment_transactions
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

-- 9. Policies for `sync_mutation_ledger`
CREATE POLICY sync_ledger_select_own ON public.sync_mutation_ledger
  FOR SELECT TO authenticated USING (auth.uid() = parent_id);

CREATE POLICY sync_ledger_insert_own ON public.sync_mutation_ledger
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = parent_id);

-- =============================================================================
-- Server-Side Atomic RPC Functions
-- =============================================================================

-- RPC 1: Tier-1 Clear Child Activity History Only (preserves lessons, stars, and badges)
CREATE OR REPLACE FUNCTION public.rpc_clear_child_activity_history_only(p_child_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.child_profiles
    WHERE id = p_child_id AND parent_id = v_uid
  ) THEN
    RAISE EXCEPTION 'FORBIDDEN_IDOR: Child profile does not belong to authenticated parent';
  END IF;

  DELETE FROM public.child_activity_logs
  WHERE child_id = p_child_id AND parent_id = v_uid;

  UPDATE public.child_profiles
  SET used_minutes_today = 0,
      watched_videos_today = 0,
      current_live_status = 'متصل — تم مسح سجل النشاط الزمني فقط',
      sync_version_seq = sync_version_seq + 1
  WHERE id = p_child_id AND parent_id = v_uid;

  RETURN jsonb_build_object(
    'status', 'cleared_activity_only',
    'childId', p_child_id
  );
END;
$$;

-- RPC 2: Tier-2 Delete All Personal & Educational Data for a Child (or remove profile)
CREATE OR REPLACE FUNCTION public.rpc_delete_all_child_data(
  p_child_id TEXT,
  p_remove_profile BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_child_count INT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.child_profiles
    WHERE id = p_child_id AND parent_id = v_uid
  ) THEN
    RAISE EXCEPTION 'FORBIDDEN_IDOR: Child profile does not belong to authenticated parent';
  END IF;

  DELETE FROM public.child_activity_logs WHERE child_id = p_child_id AND parent_id = v_uid;
  DELETE FROM public.child_educational_progress WHERE child_id = p_child_id AND parent_id = v_uid;
  DELETE FROM public.child_favorites WHERE child_id = p_child_id AND parent_id = v_uid;
  DELETE FROM public.sync_mutation_ledger WHERE child_id = p_child_id AND parent_id = v_uid;

  SELECT COUNT(*) INTO v_child_count FROM public.child_profiles WHERE parent_id = v_uid;

  IF p_remove_profile AND v_child_count > 1 THEN
    DELETE FROM public.child_profiles WHERE id = p_child_id AND parent_id = v_uid;
    RETURN jsonb_build_object('status', 'profile_deleted', 'childId', p_child_id);
  ELSE
    UPDATE public.child_profiles
    SET stars_earned = 0,
        intelligence_points = 0,
        games_completed_count = 0,
        correct_pronunciations_count = 0,
        used_minutes_today = 0,
        watched_videos_today = 0,
        education_level = 'مبتدئ',
        unlocked_cosmetics = '["hero_crown_basic"]'::jsonb,
        practiced_vocabulary = '[]'::jsonb,
        unlocked_achievements = '{}'::jsonb,
        game_progress_by_game_id = '{}'::jsonb,
        is_device_remotely_locked = FALSE,
        current_live_status = 'تم حذف جميع البيانات التعليمية والشخصية لهذا الملف',
        sync_version_seq = sync_version_seq + 1
    WHERE id = p_child_id AND parent_id = v_uid;

    RETURN jsonb_build_object('status', 'all_child_data_wiped', 'childId', p_child_id);
  END IF;
END;
$$;

-- RPC 3: Delete Parent Account & Cascade All Associated Children, Progress, Videos & Subscriptions
CREATE OR REPLACE FUNCTION public.rpc_delete_parent_account_cascade()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Authentication required';
  END IF;

  DELETE FROM public.parent_accounts WHERE id = v_uid;

  RETURN jsonb_build_object(
    'status', 'parent_account_and_all_children_deleted',
    'deletedParentId', v_uid
  );
END;
$$;
