-- FIX: Disable RLS on all tables for Firebase Auth compatibility
-- The app uses Firebase Auth, not Supabase Auth, so auth.uid() returns null
-- and RLS policies block all operations. This script disables RLS on all
-- relevant tables so the app can work with Firebase Auth UIDs.
--
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql

DO $$
DECLARE
    t TEXT;
    tables_to_fix TEXT[] := ARRAY[
        'users', 'bookings', 'wallets', 'wallet_transactions',
        'loyalty_points', 'reviews', 'favorites', 'notifications',
        'split_requests', 'split_members', 'slots', 'grounds',
        'locations', 'owner_profiles'
    ];
BEGIN
    FOREACH t IN ARRAY tables_to_fix LOOP
        -- Disable RLS
        EXECUTE format('ALTER TABLE IF EXISTS public.%I DISABLE ROW LEVEL SECURITY', t);
        -- Drop all policies on this table
        EXECUTE format(
            'DO $$ DECLARE r RECORD; BEGIN FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = ''public'' AND tablename = ''%s'' LOOP EXECUTE format(''DROP POLICY IF EXISTS %%I ON public.%I'', r.policyname); END LOOP; END $$',
            t, t
        );
        RAISE NOTICE 'Fixed RLS for table: %', t;
    END LOOP;
END $$;

-- Also ensure the users table id column is TEXT (not UUID)
-- to support Firebase UIDs which are strings
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'id'
          AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.users ALTER COLUMN id TYPE TEXT USING id::text;
        RAISE NOTICE 'Converted users.id from UUID to TEXT';
    END IF;
END $$;

-- Ensure bookings.user_id is TEXT too
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'bookings'
          AND column_name = 'user_id'
          AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.bookings ALTER COLUMN user_id TYPE TEXT USING user_id::text;
        RAISE NOTICE 'Converted bookings.user_id from UUID to TEXT';
    END IF;
END $$;
