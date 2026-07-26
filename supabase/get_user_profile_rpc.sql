-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql

CREATE OR REPLACE FUNCTION public.get_user_profile(p_id TEXT)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_data json;
BEGIN
    SELECT row_to_json(u) INTO user_data
    FROM public.users u
    WHERE id = p_id;
    
    RETURN user_data;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_profile(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_user_profile(TEXT) TO authenticated;
