-- ============================================================
--  Mods4Hire — Gaming Profiles Migration
--  Adds gaming background / preferences to profiles.
--  Run in Supabase SQL Editor.
-- ============================================================

-- Extend base profiles with display name, location, website
ALTER TABLE mods4hire.profiles
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS location     TEXT,
  ADD COLUMN IF NOT EXISTS website      TEXT,
  ADD COLUMN IF NOT EXISTS discord_tag  TEXT,
  ADD COLUMN IF NOT EXISTS twitter_handle TEXT;

-- New table: gaming_profiles (one row per user, optional)
CREATE TABLE IF NOT EXISTS mods4hire.gaming_profiles (
  id                  UUID        PRIMARY KEY REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  gaming_since_year   INTEGER     CHECK (gaming_since_year BETWEEN 1970 AND 2030),
  favorite_genres     TEXT[]      NOT NULL DEFAULT '{}',
  favorite_games      TEXT,
  gaming_hours_week   INTEGER     CHECK (gaming_hours_week BETWEEN 0 AND 168),
  preferred_platforms TEXT[]      NOT NULL DEFAULT '{}',
  gaming_style        TEXT        CHECK (gaming_style IN ('casual','competitive','content_creator','streamer','collector','speedrunner')),
  notable_games       TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mods4hire.gaming_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gaming_profiles_select" ON mods4hire.gaming_profiles FOR SELECT USING (true);
CREATE POLICY "gaming_profiles_write"  ON mods4hire.gaming_profiles FOR ALL   USING (auth.uid() = id);

GRANT ALL ON mods4hire.gaming_profiles TO anon, authenticated, service_role;

NOTIFY pgrst, 'reload schema';
