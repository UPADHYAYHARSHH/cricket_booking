-- ============================================================
-- SECURITY DEFINER function for upserting user profiles
-- ============================================================
-- This function runs with the function owner's privileges,
-- bypassing RLS. The app calls it via supabase.rpc().
-- RLS stays enabled for all direct table access.
--
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ============================================================

CREATE OR REPLACE FUNCTION public.upsert_user_profile(
    p_id TEXT,
    p_name TEXT,
    p_email TEXT,
    p_gender TEXT,
    p_dob TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (id, name, email, gender, dob, updated_at)
    VALUES (p_id, p_name, p_email, p_gender, p_dob::timestamptz, now())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        gender = EXCLUDED.gender,
        dob = EXCLUDED.dob,
        updated_at = now();
END;
$$;

-- Allow authenticated and anonymous callers to invoke this function
GRANT EXECUTE ON FUNCTION public.upsert_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.upsert_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
