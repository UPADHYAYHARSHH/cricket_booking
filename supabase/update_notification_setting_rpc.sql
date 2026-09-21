-- Run this in your Supabase SQL Editor (v2 - replaces previous version):
-- https://supabase.com/dashboard/project/_/sql
-- Fixes: 1) RLS blocks direct update (Firebase Auth -> anon has no auth.email()),
--        2) id column may still be UUID in some projects -> compare as TEXT,
--        3) fallback to email match when id doesn't match, returns updated count.

CREATE OR REPLACE FUNCTION public.update_notification_setting(p_id TEXT, p_enabled BOOLEAN, p_email TEXT DEFAULT NULL)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INT := 0;
BEGIN
    -- Primary match: id as text (works whether id is TEXT or UUID)
    UPDATE public.users
    SET is_notification_enabled = p_enabled,
        updated_at = NOW()
    WHERE id::TEXT = p_id;
    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Fallback: match by email (RLS policy keys off email, so this is the real owner row)
    IF v_count = 0 AND p_email IS NOT NULL AND p_email <> '' THEN
        UPDATE public.users
        SET is_notification_enabled = p_enabled,
            updated_at = NOW()
        WHERE email = p_email;
        GET DIAGNOSTICS v_count = ROW_COUNT;
    END IF;

    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_notification_setting(TEXT, BOOLEAN, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.update_notification_setting(TEXT, BOOLEAN) TO anon;
GRANT EXECUTE ON FUNCTION public.update_notification_setting(TEXT, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_notification_setting(TEXT, BOOLEAN) TO authenticated;
