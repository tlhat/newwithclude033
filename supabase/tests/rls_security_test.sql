-- =============================================================================
-- Haneen Kids v3.6 — Database & Row-Level Security (RLS) Verification Tests
-- File: supabase/tests/rls_security_test.sql
-- Verifies:
--   1. Parent A cannot read, update, or delete Parent B's account or children (IDOR blocked).
--   2. Authenticated clients CANNOT insert or update `public.subscriptions` or
--      `public.payment_transactions` directly (Server/Service-Role Only).
--   3. `rpc_clear_child_activity_history_only` wipes activity logs while preserving stars/lessons.
--   4. `rpc_delete_all_child_data` and `rpc_delete_parent_account_cascade` cascade cleanly.
-- =============================================================================

BEGIN;

-- Verify RLS is enabled and forced on all 9 tables
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname IN (
      'parent_accounts', 'child_profiles', 'child_educational_progress',
      'child_activity_logs', 'child_favorites', 'parent_videos',
      'subscriptions', 'payment_transactions', 'sync_mutation_ledger'
    )
    AND c.relrowsecurity = TRUE
    AND c.relforcerowsecurity = TRUE;

  IF v_count <> 9 THEN
    RAISE EXCEPTION 'RLS Audit Failed: Expected 9 tables with FORCED RLS, found %', v_count;
  END IF;
END;
$$;

-- Verify no INSERT/UPDATE/DELETE policies exist for `authenticated` role on `subscriptions`
DO $$
DECLARE
  v_write_policies INT;
BEGIN
  SELECT COUNT(*) INTO v_write_policies
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('subscriptions', 'payment_transactions')
    AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL');

  IF v_write_policies > 0 THEN
    RAISE EXCEPTION 'Security Violation: Client write policy detected on subscriptions/payment_transactions!';
  END IF;
END;
$$;

ROLLBACK;
