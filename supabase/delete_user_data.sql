CREATE OR REPLACE FUNCTION delete_user_and_data(user_id_text TEXT)
RETURNS void AS $$
BEGIN
  -- 1. Manually delete all child records from tables that reference the user
  
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favorites') THEN
    EXECUTE format('DELETE FROM public.favorites WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reviews') THEN
    EXECUTE format('DELETE FROM public.reviews WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'loyalty_points') THEN
    EXECUTE format('DELETE FROM public.loyalty_points WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN
    EXECUTE format('DELETE FROM public.bookings WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'wallets') THEN
    EXECUTE format('DELETE FROM public.wallets WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
    EXECUTE format('DELETE FROM public.notifications WHERE user_id = %L', user_id_text);
  END IF;

  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'split_members') THEN
    EXECUTE format('DELETE FROM public.split_members WHERE user_id = %L', user_id_text);
  END IF;
  
  -- Delete the user from the public users table
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
    EXECUTE format('DELETE FROM public.users WHERE id = %L', user_id_text);
  END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
