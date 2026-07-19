-- ============================================================
-- RLS Policies for Firebase Auth + Supabase hybrid setup
-- ============================================================
-- This app uses Firebase Auth for identity, but Supabase for the database.
-- We create a Supabase Auth session alongside Firebase Auth (same email/password)
-- so that `auth.email()` is available in RLS policies.
--
-- Strategy: Match users by EMAIL, not by auth.uid(), because Firebase UIDs
-- are stored in the `id` column but they don't match Supabase Auth UUIDs.
--
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ============================================================

-- Step 1: Drop ALL existing RLS policies (clean slate)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- Step 2: Helper to enable RLS + create policy only if table exists
-- We use this for every table to avoid errors on missing tables

-- ============================================================
-- USERS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='users') THEN
        EXECUTE 'ALTER TABLE public.users ENABLE ROW LEVEL SECURITY';

        EXECUTE 'CREATE POLICY "users_insert_own" ON public.users FOR INSERT WITH CHECK (email = auth.email())';
        EXECUTE 'CREATE POLICY "users_select_own" ON public.users FOR SELECT USING (email = auth.email())';
        EXECUTE 'CREATE POLICY "users_update_own" ON public.users FOR UPDATE USING (email = auth.email()) WITH CHECK (email = auth.email())';

        RAISE NOTICE 'RLS configured for: users';
    END IF;
END $$;

-- ============================================================
-- BOOKINGS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='bookings') THEN
        EXECUTE 'ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "bookings_select_own" ON public.bookings FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        EXECUTE 'CREATE POLICY "bookings_insert_own" ON public.bookings FOR INSERT WITH CHECK (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        EXECUTE 'CREATE POLICY "bookings_update_own" ON public.bookings FOR UPDATE USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: bookings';
    END IF;
END $$;

-- ============================================================
-- SLOTS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='slots') THEN
        EXECUTE 'ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "slots_select_all" ON public.slots FOR SELECT USING (true)';
        RAISE NOTICE 'RLS configured for: slots';
    END IF;
END $$;

-- ============================================================
-- GROUNDS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='grounds') THEN
        EXECUTE 'ALTER TABLE public.grounds ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "grounds_select_all" ON public.grounds FOR SELECT USING (true)';
        RAISE NOTICE 'RLS configured for: grounds';
    END IF;
END $$;

-- ============================================================
-- LOCATIONS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='locations') THEN
        EXECUTE 'ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "locations_select_all" ON public.locations FOR SELECT USING (true)';
        RAISE NOTICE 'RLS configured for: locations';
    END IF;
END $$;

-- ============================================================
-- REVIEWS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='reviews') THEN
        EXECUTE 'ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "reviews_select_all" ON public.reviews FOR SELECT USING (true)';
        EXECUTE 'CREATE POLICY "reviews_insert_own" ON public.reviews FOR INSERT WITH CHECK (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: reviews';
    END IF;
END $$;

-- ============================================================
-- FAVORITES TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='favorites') THEN
        EXECUTE 'ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "favorites_select_own" ON public.favorites FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        EXECUTE 'CREATE POLICY "favorites_insert_own" ON public.favorites FOR INSERT WITH CHECK (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        EXECUTE 'CREATE POLICY "favorites_delete_own" ON public.favorites FOR DELETE USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: favorites';
    END IF;
END $$;

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='notifications') THEN
        EXECUTE 'ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "notifications_select_own" ON public.notifications FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: notifications';
    END IF;
END $$;

-- ============================================================
-- WALLETS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='wallets') THEN
        EXECUTE 'ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "wallets_select_own" ON public.wallets FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: wallets';
    END IF;
END $$;

-- ============================================================
-- WALLET TRANSACTIONS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='wallet_transactions') THEN
        EXECUTE 'ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "wallet_transactions_select_own" ON public.wallet_transactions FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: wallet_transactions';
    END IF;
END $$;

-- ============================================================
-- SPLIT REQUESTS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='split_requests') THEN
        EXECUTE 'ALTER TABLE public.split_requests ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "split_requests_select_own" ON public.split_requests FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        EXECUTE 'CREATE POLICY "split_requests_insert_own" ON public.split_requests FOR INSERT WITH CHECK (user_id IN (SELECT id FROM public.users WHERE email = auth.email()))';
        RAISE NOTICE 'RLS configured for: split_requests';
    END IF;
END $$;

-- ============================================================
-- SPLIT MEMBERS TABLE
-- ============================================================
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='split_members') THEN
        EXECUTE 'ALTER TABLE public.split_members ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "split_members_select_own" ON public.split_members FOR SELECT USING (split_request_id IN (SELECT id FROM public.split_requests WHERE user_id IN (SELECT id FROM public.users WHERE email = auth.email())))';
        EXECUTE 'CREATE POLICY "split_members_insert_own" ON public.split_members FOR INSERT WITH CHECK (split_request_id IN (SELECT id FROM public.split_requests WHERE user_id IN (SELECT id FROM public.users WHERE email = auth.email())))';
        RAISE NOTICE 'RLS configured for: split_members';
    END IF;
END $$;
