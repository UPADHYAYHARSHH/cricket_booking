-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema='public' 
          AND table_name='users' 
          AND column_name='is_notification_enabled'
    ) THEN
        ALTER TABLE public.users ADD COLUMN is_notification_enabled BOOLEAN DEFAULT true;
    END IF;
END $$;
