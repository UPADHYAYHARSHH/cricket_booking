-- Migration: Allow multiple devices per user and multi-platform registrations (Owner & User apps)
-- Currently, fcm_tokens has a UNIQUE constraint on user_id (fcm_tokens_user_id_key).
-- Running this in Supabase SQL Editor ensures:
-- 1. A user can receive push notifications on multiple devices (phone, tablet).
-- 2. An owner who uses the same email/UID for both the User and Owner apps has both app tokens retained.

-- Drop the single-token-per-user constraint
ALTER TABLE IF EXISTS public.fcm_tokens DROP CONSTRAINT IF EXISTS fcm_tokens_user_id_key;

-- Ensure device tokens are unique
CREATE UNIQUE INDEX IF NOT EXISTS fcm_tokens_token_idx ON public.fcm_tokens (token);

-- Index user_id for fast lookup when sending notifications
CREATE INDEX IF NOT EXISTS fcm_tokens_user_id_idx ON public.fcm_tokens (user_id);
