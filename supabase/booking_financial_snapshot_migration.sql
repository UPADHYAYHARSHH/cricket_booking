-- Migration: Add financial snapshot columns and update RPC functions
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard)

-- 1. Add financial columns to bookings table
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS platform_fee NUMERIC DEFAULT 30.0,
ADD COLUMN IF NOT EXISTS commission_rate NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS commission_is_percentage BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS base_amount NUMERIC DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS owner_earnings NUMERIC DEFAULT 0.0;

-- 2. Ensure RLS Policy allows UPDATE on bookings
DROP POLICY IF EXISTS "Users can update their own bookings" ON public.bookings;
CREATE POLICY "Users can update their own bookings" 
ON public.bookings FOR UPDATE 
USING (true);

-- 3. Update all existing bookings from 0.0 to 30.0 platform fee (if still 0.0)
UPDATE public.bookings
SET 
  platform_fee = 30.0,
  commission_rate = 0.0,
  commission_is_percentage = true,
  base_amount = GREATEST(0.0, amount - 30.0),
  owner_earnings = GREATEST(0.0, amount - 30.0)
WHERE platform_fee = 0.0 OR owner_earnings = 0.0;

-- 4. Drop all overloaded versions of save_booking to fix PGRST203 candidate function ambiguity
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text);
DROP FUNCTION IF EXISTS public.save_booking(text, text, text, integer, text, text, text, text, text, text, numeric, numeric, boolean, numeric, numeric);

-- 5. Create atomic save_booking RPC function that automatically calculates & saves platform_fee & owner_earnings
CREATE OR REPLACE FUNCTION public.save_booking(
    p_user_id TEXT,
    p_ground_id TEXT,
    p_slot_time TEXT,
    p_amount INT,
    p_status TEXT,
    p_sport_name TEXT DEFAULT NULL,
    p_period TEXT DEFAULT NULL,
    p_razorpay_order_id TEXT DEFAULT NULL,
    p_razorpay_payment_id TEXT DEFAULT NULL,
    p_razorpay_signature TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_platform_fee NUMERIC;
    v_commission_rate NUMERIC;
    v_commission_is_pct BOOLEAN;
    v_base_amount NUMERIC;
    v_owner_earnings NUMERIC;
    v_db_fee TEXT;
    v_db_comm TEXT;
    v_db_is_pct TEXT;
    result JSON;
BEGIN
    -- Fetch dynamic configuration from app_config table
    SELECT value INTO v_db_fee FROM public.app_config WHERE key = 'platform_fee' LIMIT 1;
    SELECT value INTO v_db_comm FROM public.app_config WHERE key = 'commission_rate' LIMIT 1;
    SELECT value INTO v_db_is_pct FROM public.app_config WHERE key = 'commission_is_percentage' LIMIT 1;

    v_platform_fee := COALESCE(NULLIF(v_db_fee, '')::numeric, 30.0);
    v_commission_rate := COALESCE(NULLIF(v_db_comm, '')::numeric, 0.0);
    v_commission_is_pct := COALESCE((v_db_is_pct IS NULL OR v_db_is_pct = 'true' OR v_db_is_pct = '1'), true);

    v_base_amount := GREATEST(0.0, p_amount - v_platform_fee);

    IF v_commission_is_pct THEN
        v_owner_earnings := GREATEST(0.0, v_base_amount - (v_base_amount * (v_commission_rate / 100.0)));
    ELSE
        v_owner_earnings := GREATEST(0.0, v_base_amount - v_commission_rate);
    END IF;

    INSERT INTO public.bookings (
        user_id, ground_id, slot_time, amount, status,
        sport_name, period,
        razorpay_order_id, razorpay_payment_id, razorpay_signature,
        platform_fee, commission_rate, commission_is_percentage,
        base_amount, owner_earnings
    )
    VALUES (
        p_user_id, p_ground_id::uuid, p_slot_time::timestamptz, p_amount, p_status,
        p_sport_name, p_period,
        p_razorpay_order_id, p_razorpay_payment_id, p_razorpay_signature,
        v_platform_fee, v_commission_rate, v_commission_is_pct,
        v_base_amount, v_owner_earnings
    )
    RETURNING to_json(bookings.*) INTO result;
    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.save_booking(TEXT, TEXT, TEXT, INT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 6. Update get_user_bookings RPC to select ALL booking columns (b.*)
CREATE OR REPLACE FUNCTION public.get_user_bookings(p_user_id TEXT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN (
        SELECT COALESCE(json_agg(row_to_json(b)), '[]'::json)
        FROM (
            SELECT
                b.*,
                CASE WHEN g.id IS NOT NULL THEN json_build_object(
                    'id', g.id,
                    'name', g.name,
                    'owner_id', g.owner_id,
                    'location_id', g.location_id,
                    'category', g.category,
                    'opening_time', g.opening_time,
                    'closing_time', g.closing_time,
                    'slot_duration', g.slot_duration,
                    'price_per_hour', g.price_per_hour,
                    'weekend_price', g.weekend_price,
                    'latitude', l.latitude,
                    'longitude', l.longitude,
                    'address', l.address,
                    'city', l.city,
                    'amenities', l.amenities,
                    'owner_id', l.owner_id,
                    'imageUrl', (
                        SELECT image_url FROM public.ground_images
                        WHERE ground_id = g.id LIMIT 1
                    )
                ) ELSE NULL END AS grounds
            FROM public.bookings b
            LEFT JOIN public.grounds g ON b.ground_id = g.id
            LEFT JOIN public.locations l ON g.location_id = l.id
            WHERE b.user_id = p_user_id
            ORDER BY b.slot_time DESC
        ) b
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_bookings(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_user_bookings(TEXT) TO authenticated;
