-- Add is_admin flag to all project profiles

ALTER TABLE mods4hire.profiles    ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE gamers4rent.profiles  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE medicinerate.profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- ── mods4hire: allow admins to delete any listing or application ──────────
DROP POLICY IF EXISTS "listings_delete"  ON mods4hire.job_listings;
CREATE POLICY "listings_delete" ON mods4hire.job_listings FOR DELETE USING (
  auth.uid() = hirer_id OR
  COALESCE((SELECT is_admin FROM mods4hire.profiles WHERE id = auth.uid()), false)
);

DROP POLICY IF EXISTS "apps_delete" ON mods4hire.applications;
CREATE POLICY "apps_delete" ON mods4hire.applications FOR DELETE USING (
  auth.uid() = applicant_id OR
  COALESCE((SELECT is_admin FROM mods4hire.profiles WHERE id = auth.uid()), false)
);

-- ── gamers4rent: allow admins to delete any listing ───────────────────────
DROP POLICY IF EXISTS "listings_delete"  ON gamers4rent.game_listings;
CREATE POLICY "listings_delete" ON gamers4rent.game_listings FOR DELETE USING (
  auth.uid() = developer_id OR
  COALESCE((SELECT is_admin FROM gamers4rent.profiles WHERE id = auth.uid()), false)
);

DROP POLICY IF EXISTS "apps_delete" ON gamers4rent.applications;
CREATE POLICY "apps_delete" ON gamers4rent.applications FOR DELETE USING (
  auth.uid() = tester_id OR
  COALESCE((SELECT is_admin FROM gamers4rent.profiles WHERE id = auth.uid()), false)
);

-- ── medicinerate: allow admins to delete any review or medication ─────────
DROP POLICY IF EXISTS "reviews_delete" ON medicinerate.reviews;
CREATE POLICY "reviews_delete" ON medicinerate.reviews FOR DELETE USING (
  auth.uid() = user_id OR
  COALESCE((SELECT is_admin FROM medicinerate.profiles WHERE id = auth.uid()), false)
);

DROP POLICY IF EXISTS "medications_admin_all" ON medicinerate.medications;
CREATE POLICY "medications_admin_all" ON medicinerate.medications
  FOR ALL USING (
    COALESCE((SELECT is_admin FROM medicinerate.profiles WHERE id = auth.uid()), false)
  );

NOTIFY pgrst, 'reload schema';
