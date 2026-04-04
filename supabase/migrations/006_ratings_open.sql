-- ============================================================
--  Mods4Hire — Migration 006: Open rating system
--  - Remove engagement gate (any auth user can rate any other user)
--  - Drop listing_id requirement from uniqueness (one rating per user pair)
--  - listing_id stays nullable for historical reference but is no longer required
-- ============================================================

-- 1. Revert to simple auth-only insert policy
DROP POLICY IF EXISTS "ratings_insert" ON mods4hire.ratings;
CREATE POLICY "ratings_insert" ON mods4hire.ratings FOR INSERT WITH CHECK (
  auth.uid() = rater_id
  AND auth.uid() <> ratee_id
);

-- 2. Replace unique constraint: one rating per rater/ratee pair regardless of listing
ALTER TABLE mods4hire.ratings
  DROP CONSTRAINT IF EXISTS ratings_rater_id_ratee_id_listing_id_key;

ALTER TABLE mods4hire.ratings
  ADD CONSTRAINT ratings_rater_id_ratee_id_key UNIQUE (rater_id, ratee_id);

NOTIFY pgrst, 'reload schema';
