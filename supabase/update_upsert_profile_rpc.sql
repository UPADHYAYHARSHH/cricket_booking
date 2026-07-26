-- Run this in your Supabase SQL Editor:
-- This updates the RPC to also handle the username field

-- 1. Ensure the username column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema='public' 
          AND table_name='users' 
          AND column_name='username'
    ) THEN
        ALTER TABLE public.users ADD COLUMN username TEXT;
    END IF;
END $$;

-- 2. Update the RPC function
CREATE OR REPLACE FUNCTION public.upsert_user_profile(
    p_id TEXT,
    p_name TEXT,
    p_email TEXT,
    p_gender TEXT,
    p_dob TEXT,
    p_username TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (id, name, email, gender, dob, username, updated_at)
    VALUES (p_id, p_name, p_email, p_gender, p_dob::timestamptz, p_username, now())
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        gender = EXCLUDED.gender,
        dob = EXCLUDED.dob,
        username = COALESCE(EXCLUDED.username, public.users.username),
        updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.upsert_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
