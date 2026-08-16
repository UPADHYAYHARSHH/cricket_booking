-- Migration to convert ground-wise ratings to location-wise ratings

-- 1. Add rating and total_reviews columns to locations
ALTER TABLE locations
  ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS total_reviews INTEGER NOT NULL DEFAULT 0;

-- 2. Create location_reviews table
DROP TABLE IF EXISTS location_reviews CASCADE;

CREATE TABLE IF NOT EXISTS location_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  rating DOUBLE PRECISION NOT NULL CHECK (rating >= 0 AND rating <= 5),
  review_text TEXT,
  media_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create trigger function to update locations.rating and locations.total_reviews
CREATE OR REPLACE FUNCTION update_location_rating()
RETURNS TRIGGER AS $$
DECLARE
  avg_rating DOUBLE PRECISION;
  review_count INTEGER;
  loc_id UUID;
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    loc_id := NEW.location_id;
  ELSIF TG_OP = 'DELETE' THEN
    loc_id := OLD.location_id;
  END IF;

  SELECT COALESCE(AVG(rating), 0.0), COUNT(id)
  INTO avg_rating, review_count
  FROM location_reviews
  WHERE location_id = loc_id;

  UPDATE locations
  SET rating = avg_rating, total_reviews = review_count
  WHERE id = loc_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. Attach trigger to location_reviews
DROP TRIGGER IF EXISTS update_location_rating_trigger ON location_reviews;
CREATE TRIGGER update_location_rating_trigger
AFTER INSERT OR UPDATE OR DELETE ON location_reviews
FOR EACH ROW EXECUTE FUNCTION update_location_rating();
