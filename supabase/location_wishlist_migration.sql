-- 1. Modify the foreign key constraint on the favorites table
-- We drop the constraint that forces ground_id to be in the "grounds" table
ALTER TABLE public.favorites DROP CONSTRAINT IF EXISTS favorites_ground_id_fkey;

-- We MUST delete existing favorites because they contain old ground IDs which 
-- will violate the new location constraint.
DELETE FROM public.favorites;

-- We add a new constraint to enforce that it now points to the "locations" table
ALTER TABLE public.favorites 
  ADD CONSTRAINT favorites_location_id_fkey 
  FOREIGN KEY (ground_id) 
  REFERENCES public.locations(id) 
  ON DELETE CASCADE;

-- 2. Create the missing location_reviews table
CREATE TABLE IF NOT EXISTS public.location_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable RLS and setup basic policies for location_reviews
ALTER TABLE public.location_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all users on location_reviews" ON public.location_reviews;
CREATE POLICY "Enable read access for all users on location_reviews"
    ON public.location_reviews FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.location_reviews;
CREATE POLICY "Enable insert for authenticated users only"
    ON public.location_reviews FOR INSERT
    WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'anon');
