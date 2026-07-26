-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql

-- 1. Ensure the city column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema='public' 
          AND table_name='users' 
          AND column_name='city'
    ) THEN
        ALTER TABLE public.users ADD COLUMN city TEXT;
    END IF;
END $$;

-- 2. Create RPC function to safely update the city, bypassing any RLS issues
CREATE OR REPLACE FUNCTION public.update_user_city(p_id TEXT, p_city TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.users SET city = p_city WHERE id = p_id;
END;
$$;

-- Allow authenticated and anonymous callers to invoke this function
GRANT EXECUTE ON FUNCTION public.update_user_city(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.update_user_city(TEXT, TEXT) TO authenticated;