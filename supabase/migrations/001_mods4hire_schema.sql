-- ============================================================
--  Mods4Hire — Schema Migration
--  Run this in the Supabase SQL Editor.
--  SAFE: creates a new 'mods4hire' namespace only.
--  Nothing in the 'public' schema is touched.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS mods4hire;

-- Grant usage to Supabase roles
GRANT USAGE ON SCHEMA mods4hire TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA mods4hire TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA mods4hire TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mods4hire GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mods4hire GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- ── Profiles ──────────────────────────────────────────────────────────────
-- One row per user, linked to auth.users
CREATE TABLE mods4hire.profiles (
  id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username       TEXT UNIQUE NOT NULL,
  role           TEXT NOT NULL DEFAULT 'hirer'
                   CHECK (role IN ('hirer', 'moderator', 'both')),
  bio            TEXT,
  avatar_url     TEXT,
  rating_avg     NUMERIC(3,2) NOT NULL DEFAULT 0,
  rating_count   INTEGER      NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Auto-create a profile row whenever a new user signs up
CREATE OR REPLACE FUNCTION mods4hire.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO mods4hire.profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created_mods4hire
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION mods4hire.handle_new_user();

-- ── Moderator Profiles ────────────────────────────────────────────────────
-- Extra info only relevant to moderators
CREATE TABLE mods4hire.moderator_profiles (
  id              UUID PRIMARY KEY REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  platforms       TEXT[]  NOT NULL DEFAULT '{}',
  hours_per_week  INTEGER,
  experience      TEXT,
  portfolio_url   TEXT
);

-- ── Job Listings ──────────────────────────────────────────────────────────
CREATE TABLE mods4hire.job_listings (
  id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  hirer_id           UUID         NOT NULL REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  title              TEXT         NOT NULL,
  platform           TEXT[]       NOT NULL DEFAULT '{}',
  compensation_type  TEXT         NOT NULL
                       CHECK (compensation_type IN ('paid_hourly','monthly_retainer','salary','volunteer')),
  hours_per_week     INTEGER,
  required_skills    TEXT,
  deadline           DATE,
  status             TEXT         NOT NULL DEFAULT 'open'
                       CHECK (status IN ('open','closed','filled')),
  -- Role Details (expandable section)
  community_size     TEXT,
  experience_level   TEXT,
  responsibilities   TEXT,
  timezone_pref      TEXT,
  additional_notes   TEXT,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── Applications ──────────────────────────────────────────────────────────
CREATE TABLE mods4hire.applications (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id    UUID        NOT NULL REFERENCES mods4hire.job_listings(id) ON DELETE CASCADE,
  applicant_id  UUID        NOT NULL REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  pitch         TEXT,
  status        TEXT        NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending','accepted','rejected')),
  applied_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (listing_id, applicant_id)
);

-- ── Ratings ───────────────────────────────────────────────────────────────
CREATE TABLE mods4hire.ratings (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  ratee_id    UUID        NOT NULL REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  rater_id    UUID        NOT NULL REFERENCES mods4hire.profiles(id) ON DELETE CASCADE,
  listing_id  UUID        REFERENCES mods4hire.job_listings(id) ON DELETE SET NULL,
  score       INTEGER     NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (rater_id, ratee_id, listing_id)
);

-- Auto-update rating_avg and rating_count on profiles when a rating is inserted/deleted
CREATE OR REPLACE FUNCTION mods4hire.refresh_rating()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  target_id UUID;
BEGIN
  target_id := COALESCE(NEW.ratee_id, OLD.ratee_id);
  UPDATE mods4hire.profiles SET
    rating_avg   = COALESCE((SELECT AVG(score) FROM mods4hire.ratings WHERE ratee_id = target_id), 0),
    rating_count = (SELECT COUNT(*) FROM mods4hire.ratings WHERE ratee_id = target_id)
  WHERE id = target_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_rating_change
  AFTER INSERT OR UPDATE OR DELETE ON mods4hire.ratings
  FOR EACH ROW EXECUTE FUNCTION mods4hire.refresh_rating();

-- ── Row Level Security ────────────────────────────────────────────────────
ALTER TABLE mods4hire.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE mods4hire.moderator_profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE mods4hire.job_listings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE mods4hire.applications        ENABLE ROW LEVEL SECURITY;
ALTER TABLE mods4hire.ratings             ENABLE ROW LEVEL SECURITY;

-- Profiles: anyone can read, only owner can update
CREATE POLICY "profiles_select"  ON mods4hire.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_update"  ON mods4hire.profiles FOR UPDATE USING (auth.uid() = id);

-- Moderator profiles: anyone can read, only owner can write
CREATE POLICY "mod_profiles_select" ON mods4hire.moderator_profiles FOR SELECT USING (true);
CREATE POLICY "mod_profiles_write"  ON mods4hire.moderator_profiles FOR ALL   USING (auth.uid() = id);

-- Listings: anyone can read open listings, only hirer can create/edit their own
CREATE POLICY "listings_select"  ON mods4hire.job_listings FOR SELECT USING (true);
CREATE POLICY "listings_insert"  ON mods4hire.job_listings FOR INSERT WITH CHECK (auth.uid() = hirer_id);
CREATE POLICY "listings_update"  ON mods4hire.job_listings FOR UPDATE USING (auth.uid() = hirer_id);
CREATE POLICY "listings_delete"  ON mods4hire.job_listings FOR DELETE USING (auth.uid() = hirer_id);

-- Applications: applicant can insert/read own; hirer can read apps to their listings
CREATE POLICY "apps_insert"      ON mods4hire.applications FOR INSERT WITH CHECK (auth.uid() = applicant_id);
CREATE POLICY "apps_select_own"  ON mods4hire.applications FOR SELECT USING (
  auth.uid() = applicant_id OR
  auth.uid() = (SELECT hirer_id FROM mods4hire.job_listings WHERE id = listing_id)
);
CREATE POLICY "apps_update_hirer" ON mods4hire.applications FOR UPDATE USING (
  auth.uid() = (SELECT hirer_id FROM mods4hire.job_listings WHERE id = listing_id)
);

-- Ratings: anyone can read; only authenticated users can rate; one rating per pair per listing
CREATE POLICY "ratings_select" ON mods4hire.ratings FOR SELECT USING (true);
CREATE POLICY "ratings_insert" ON mods4hire.ratings FOR INSERT WITH CHECK (auth.uid() = rater_id);
