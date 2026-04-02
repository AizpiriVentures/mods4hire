-- Mods4Hire — Initial Schema
-- Run: supabase db push

-- ============================================================
-- PROFILES
-- ============================================================
create table if not exists profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  username text unique not null,
  role text check (role in ('hirer', 'moderator', 'both')) not null default 'both',
  bio text,
  avatar_url text,
  rating_avg numeric(3,2) default 0,
  rating_count int default 0,
  created_at timestamptz default now()
);

alter table profiles enable row level security;
create policy "profiles_public_read" on profiles for select using (true);
create policy "profiles_insert_own" on profiles for insert with check (auth.uid() = id);
create policy "profiles_update_own" on profiles for update using (auth.uid() = id);


-- ============================================================
-- MODERATOR PROFILES
-- ============================================================
create table if not exists moderator_profiles (
  user_id uuid references profiles(id) on delete cascade primary key,
  platforms text[] default '{}',
  hours_per_week int,
  hourly_rate numeric(6,2),
  experience_summary text,
  portfolio_url text
);

alter table moderator_profiles enable row level security;
create policy "mod_profiles_public_read" on moderator_profiles for select using (true);
create policy "mod_profiles_insert_own" on moderator_profiles for insert with check (auth.uid() = user_id);
create policy "mod_profiles_update_own" on moderator_profiles for update using (auth.uid() = user_id);


-- ============================================================
-- JOB LISTINGS
-- ============================================================
create table if not exists job_listings (
  id uuid primary key default gen_random_uuid(),
  hirer_id uuid references profiles(id) on delete cascade not null,
  title text not null,
  platform text[] default '{}',
  community_size text,
  community_type text,
  hours_per_week int,
  compensation_type text check (compensation_type in ('paid_hourly','monthly_retainer','volunteer')) not null,
  compensation_details text,
  required_skills text,
  deadline date,
  status text default 'open' check (status in ('open','filled','closed')),
  created_at timestamptz default now()
);

alter table job_listings enable row level security;
create policy "listings_public_read" on job_listings for select using (true);
create policy "listings_insert_hirer" on job_listings for insert with check (auth.uid() = hirer_id);
create policy "listings_update_hirer" on job_listings for update using (auth.uid() = hirer_id);
create policy "listings_delete_hirer" on job_listings for delete using (auth.uid() = hirer_id);


-- ============================================================
-- APPLICATIONS
-- ============================================================
create table if not exists applications (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references job_listings(id) on delete cascade not null,
  moderator_id uuid references profiles(id) on delete cascade not null,
  pitch text,
  status text default 'pending' check (status in ('pending','accepted','rejected')),
  applied_at timestamptz default now(),
  unique (listing_id, moderator_id)
);

alter table applications enable row level security;

create policy "applications_mod_read" on applications
  for select using (auth.uid() = moderator_id);

create policy "applications_hirer_read" on applications
  for select using (
    auth.uid() = (select hirer_id from job_listings where id = listing_id)
  );

create policy "applications_insert_mod" on applications
  for insert with check (auth.uid() = moderator_id);

create policy "applications_hirer_update" on applications
  for update using (
    auth.uid() = (select hirer_id from job_listings where id = listing_id)
  );


-- ============================================================
-- RATINGS
-- ============================================================
create table if not exists ratings (
  id uuid primary key default gen_random_uuid(),
  rater_id uuid references profiles(id) on delete cascade not null,
  ratee_id uuid references profiles(id) on delete cascade not null,
  listing_id uuid references job_listings(id) on delete cascade not null,
  reliability int check (reliability between 1 and 5),
  communication int check (communication between 1 and 5),
  judgment int check (judgment between 1 and 5),
  professionalism int check (professionalism between 1 and 5),
  comment text,
  created_at timestamptz default now(),
  unique (rater_id, ratee_id, listing_id)
);

alter table ratings enable row level security;
create policy "ratings_public_read" on ratings for select using (true);

-- Only allow rating after confirmed accepted engagement
create policy "ratings_insert_verified" on ratings
  for insert with check (
    auth.uid() = rater_id
    and exists (
      select 1 from applications
      where listing_id = ratings.listing_id
        and status = 'accepted'
        and (moderator_id = auth.uid() or (select hirer_id from job_listings where id = ratings.listing_id) = auth.uid())
    )
  );

create or replace function update_mod_rating_avg()
returns trigger language plpgsql security definer as $$
begin
  update profiles set
    rating_avg = (select avg((reliability + communication + judgment + professionalism) / 4.0) from ratings where ratee_id = NEW.ratee_id),
    rating_count = (select count(*) from ratings where ratee_id = NEW.ratee_id)
  where id = NEW.ratee_id;
  return NEW;
end;
$$;

create trigger on_new_rating
  after insert on ratings
  for each row execute function update_mod_rating_avg();
