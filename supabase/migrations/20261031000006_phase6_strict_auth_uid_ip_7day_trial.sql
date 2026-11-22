-- Phase 6 Migration: Official Account UID, Phone E.164, and UID+IP 7-Day Free Trial Registry
ALTER TABLE IF EXISTS public.parent_accounts
  ADD COLUMN IF NOT EXISTS account_uid TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS phone_e164 TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS registered_client_ip_hash TEXT;

CREATE TABLE IF NOT EXISTS public.free_trial_claims_registry (
  id BIGSERIAL PRIMARY KEY,
  account_uid TEXT NOT NULL UNIQUE,
  client_ip_hash TEXT NOT NULL UNIQUE,
  trial_days INTEGER NOT NULL DEFAULT 7,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.free_trial_claims_registry ENABLE ROW LEVEL SECURITY;
