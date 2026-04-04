-- ============================================================
--  Mods4Hire — Migration 004: Fix ratings schema
--  1. Replace single 'score' column with 4 moderation dimensions
--  2. Update refresh_rating() to average the 4 dimensions
--  3. Add engagement gate: ratings only allowed after accepted application
-- ============================================================

-- Step 1: Replace score with 4-dimension columns
ALTER TABLE mods4hire.ratings
  DROP COLUMN IF EXISTS score,
  ADD COLUMN IF NOT EXISTS reliability     INTEGER CHECK (reliability     BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS communication   INTEGER CHECK (communication   BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS judgment        INTEGER CHECK (judgment        BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS professionalism INTEGER CHECK (professionalism BETWEEN 1 AND 5);

-- Step 2: Update trigger function to average the 4 dimensions
CREATE OR REPLACE FUNCTION mods4hire.refresh_rating()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE target_id UUID;
BEGIN
  target_id := COALESCE(NEW.ratee_id, OLD.ratee_id);
  UPDATE mods4hire.profiles SET
    rating_avg = COALESCE((
      SELECT AVG(
        (COALESCE(r.reliability,0) + COALESCE(r.communication,0) +
         COALESCE(r.judgment,0) + COALESCE(r.professionalism,0)) / 4.0
      )
      FROM mods4hire.ratings r
      WHERE r.ratee_id = target_id
    ), 0),
    rating_count = (SELECT COUNT(*) FROM mods4hire.ratings WHERE ratee_id = target_id)
  WHERE id = target_id;
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Step 3: Replace permissive ratings_insert policy with engagement gate
--   A user can only leave a rating if there is an accepted application on that listing
--   where either they rated the accepted moderator (hirer→mod) or vice versa (mod→hirer).
DROP POLICY IF EXISTS "ratings_insert" ON mods4hire.ratings;
CREATE POLICY "ratings_insert" ON mods4hire.ratings FOR INSERT WITH CHECK (
  auth.uid() = rater_id
  AND listing_id IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM mods4hire.applications a
    JOIN mods4hire.job_listings l ON l.id = a.listing_id
    WHERE a.listing_id = mods4hire.ratings.listing_id
      AND a.status = 'accepted'
      AND (
        -- Hirer rates the accepted moderator
        (l.hirer_id = auth.uid() AND a.applicant_id = mods4hire.ratings.ratee_id)
        OR
        -- Accepted moderator rates the hirer
        (a.applicant_id = auth.uid() AND l.hirer_id = mods4hire.ratings.ratee_id)
      )
  )
);

NOTIFY pgrst, 'reload schema';
