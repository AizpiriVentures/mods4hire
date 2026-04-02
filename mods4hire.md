# Mods4Hire

**URL:** https://mods4hire.com  
**GitHub:** https://github.com/AizpiriVentures/mods4hire.git  
**Hosting:** Cloudflare Pages  
**Database:** Supabase  
**Type:** Web Application (Phase 1: Webpage → Phase 2: App)

---

## Project Overview

Mods4Hire is a marketplace where community managers, server owners, and platform operators can hire moderators for Discord servers, TeamSpeak communities, forums, subreddits, and any other online community. Moderators can offer paid or volunteer services. A built-in rating system ensures accountability and helps hirers find trustworthy, experienced mods.

---

## Core Features

### For Hirers (Community Owners)
- Post a moderation job listing with:
  - Platform (Discord, TeamSpeak, Reddit, Forum, Twitch, Other)
  - Community size and type
  - Required hours per week
  - Compensation (paid hourly, monthly retainer, or volunteer)
  - Required skills/experience
  - Application deadline
- Browse and manage applicants
- Accept/reject moderators
- Rate moderators after an engagement

### For Moderators
- Create a public profile with:
  - Platforms experienced on
  - Moderation style / approach
  - Availability (hours/week)
  - Past experience (community names optional, size required)
  - Rates (if paid)
  - Portfolio link
- Browse and apply to job listings
- Build a public reputation score
- Display earned ratings and badges

### Rating System
- Hirers rate mods: Reliability, Responsiveness, Judgment, Professionalism (1–5 stars)
- Mods can rate hirers: Communication, Organization, Fairness
- Ratings only unlocked after an accepted engagement concludes
- Public reputation scores on all profiles

### Discovery
- Search and filter listings by platform, compensation type, hours required
- Search and filter moderator profiles by platform, rating, availability
- Featured moderators section

### Transactions
- Hirers and mods agree on terms independently (platform does not process payments in Phase 1)
- Phase 2: Optional escrow / Stripe Connect integration

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | HTML, Tailwind CSS, Vanilla JS |
| Hosting | Cloudflare Pages |
| Backend | Supabase (PostgreSQL + Auth + Edge Functions) |
| Email | Supabase Auth + Edge Functions + Resend |
| Storage | Supabase Storage (profile avatars) |

---

## Database Schema (Supabase / PostgreSQL)

```sql
-- User profiles
profiles (
  id uuid references auth.users primary key,
  username text unique,
  role text check (role in ('hirer','moderator','both')),
  bio text,
  avatar_url text,
  rating_avg numeric(3,2) default 0,
  rating_count int default 0,
  created_at timestamptz default now()
)

-- Moderator profiles
moderator_profiles (
  user_id uuid references profiles(id) primary key,
  platforms text[],
  hours_per_week int,
  hourly_rate numeric(6,2),
  experience_summary text,
  portfolio_url text
)

-- Job listings
job_listings (
  id uuid primary key default gen_random_uuid(),
  hirer_id uuid references profiles(id),
  title text not null,
  platform text[],
  community_size text,
  community_type text,
  hours_per_week int,
  compensation_type text check (compensation_type in ('paid_hourly','monthly_retainer','volunteer')),
  compensation_details text,
  required_skills text,
  deadline date,
  status text default 'open' check (status in ('open','filled','closed')),
  created_at timestamptz default now()
)

-- Applications
applications (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid references job_listings(id),
  moderator_id uuid references profiles(id),
  pitch text,
  status text default 'pending' check (status in ('pending','accepted','rejected')),
  applied_at timestamptz default now()
)

-- Ratings
ratings (
  id uuid primary key default gen_random_uuid(),
  rater_id uuid references profiles(id),
  ratee_id uuid references profiles(id),
  listing_id uuid references job_listings(id),
  reliability int check (reliability between 1 and 5),
  communication int check (communication between 1 and 5),
  judgment int check (judgment between 1 and 5),
  professionalism int check (professionalism between 1 and 5),
  comment text,
  created_at timestamptz default now(),
  unique (rater_id, ratee_id, listing_id)
)
```

---

## Security Considerations

- RLS on all tables
- Ratings only available after accepted engagement
- No email/contact info exposed in public profiles
- Spam protection on listing and application submissions
- Cloudflare WAF for DDoS and bot protection

---

## Pages / Routes

```
/                       → Homepage, search, featured mods
/listings               → Browse job listings
/listings/[id]          → Listing detail + apply
/moderators             → Browse moderator profiles
/moderators/[username]  → Moderator profile + ratings
/dashboard              → User dashboard
/listings/new           → Post a listing (hirers)
/login
/register
```

---

## Phase Roadmap

### Phase 1 — Cloudflare Webpage (Now)
- Listing, application, profile, and rating flows
- No payment processing

### Phase 2 — App + Payments
- Mobile app with push notifications
- In-app messaging
- Stripe Connect for optional escrow payments
- Verified moderator badges

---

## Claude Code Agent Instructions

See `AGENT_PROFILE.md` for full agent configuration.
