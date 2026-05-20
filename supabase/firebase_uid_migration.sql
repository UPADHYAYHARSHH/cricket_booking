-- Migration Script: Convert UUID columns to TEXT to support Firebase UIDs and handle RLS
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/_/sql)

DO $$
DECLARE
    -- List of tables and columns to convert
    tables_to_migrate TEXT[][] := ARRAY[
        ['users', 'id'],
        ['bookings', 'user_id'],
        ['wallets', 'user_id'],
        ['wallet_transactions', 'user_id'],
        ['loyalty_points', 'user_id'],
        ['reviews', 'user_id'],
        ['favorites', 'user_id'],
        ['notifications', 'user_id'],
        ['split_requests', 'user_id'],
        ['split_members', 'user_id']
    ];
    t TEXT;
    c TEXT;
    fk_record RECORD;
BEGIN
    -- 1. Dynamically drop all policies in the public schema to avoid active dependency blocks
    FOR fk_record IN 
        SELECT policyname, tablename, schemaname
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', fk_record.policyname, fk_record.schemaname, fk_record.tablename);
    END LOOP;

    -- 2. Disable RLS and alter existing tables/columns
    FOR i IN 1 .. array_upper(tables_to_migrate, 1) LOOP
        t := tables_to_migrate[i][1];
        c := tables_to_migrate[i][2];

        -- Only perform alterations if the table and column actually exist in the database
        IF EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = t 
              AND column_name = c
        ) THEN
            -- Disable Row Level Security on the table
            EXECUTE format('ALTER TABLE IF EXISTS public.%I DISABLE ROW LEVEL SECURITY', t);

            -- Dynamically find and drop any foreign key constraints on this column
            FOR fk_record IN 
                SELECT tc.constraint_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
                WHERE tc.constraint_type = 'FOREIGN KEY'
                  AND tc.table_schema = 'public'
                  AND tc.table_name = t
                  AND kcu.column_name = c
            LOOP
                EXECUTE format('ALTER TABLE public.%I DROP CONSTRAINT IF EXISTS %I', t, fk_record.constraint_name);
            END LOOP;

            -- Convert column type to TEXT
            EXECUTE format('ALTER TABLE public.%I ALTER COLUMN %I TYPE TEXT USING %I::text', t, c, c);
        END IF;
    END LOOP;

    -- 3. Re-create foreign keys referencing public.users(id) where applicable
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'users' 
          AND column_name = 'id'
    ) THEN
        FOR i IN 2 .. array_upper(tables_to_migrate, 1) LOOP
            t := tables_to_migrate[i][1];
            c := tables_to_migrate[i][2];

            IF EXISTS (
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                  AND table_name = t 
                  AND column_name = c
            ) THEN
                -- Clean up any orphaned child rows referencing user IDs that do not exist in the public.users table
                EXECUTE format(
                    'DELETE FROM public.%I WHERE %I IS NOT NULL AND %I NOT IN (SELECT id FROM public.users)',
                    t, c, c
                );

                -- Add safe FOREIGN KEY constraint referencing public.users(id)
                EXECUTE format(
                    'ALTER TABLE public.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.users(id) ON DELETE CASCADE',
                    t, t || '_' || c || '_fkey', c
                );
            END IF;
        END LOOP;
    END IF;
END $$;
