-- Kids Language-Learning App — initial schema
-- Content hierarchy (PRD F4): courses -> units -> lessons -> activities -> items
-- Plus profiles (roles) and learner_item_states (PRD F3 adaptive memory).
--
-- Compliance note: anonymous auth is used for the first slice. Role-based auth,
-- parental-consent gating and a no-analytics-on-kids posture are deferred, but
-- the `profiles.role` column and RLS below are shaped so they slot in later.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Roles / profiles
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  role         text not null default 'learner'
                 check (role in ('teacher', 'learner', 'parent')),
  display_name text,
  created_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Content hierarchy
-- ---------------------------------------------------------------------------
create table if not exists public.courses (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  ui_language     text not null default 'en',   -- language of instructions
  target_language text not null default 'es',   -- language being taught
  description     text,
  published       boolean not null default false,
  created_at      timestamptz not null default now()
);

create table if not exists public.units (
  id        uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses (id) on delete cascade,
  title     text not null,
  position  int  not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id        uuid primary key default gen_random_uuid(),
  unit_id   uuid not null references public.units (id) on delete cascade,
  title     text not null,
  position  int  not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.activities (
  id        uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons (id) on delete cascade,
  type      text not null default 'match'      -- 'match' is the only slice type
              check (type in ('match', 'trace', 'sequence', 'speak')),
  title     text not null,
  position  int  not null default 0,
  config    jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  id              uuid primary key default gen_random_uuid(),
  activity_id     uuid not null references public.activities (id) on delete cascade,
  prompt_text     text,             -- the word/phrase being taught
  prompt_audio_url text,            -- native-speaker clip; null -> client TTS
  image_url       text,             -- optional remote picture
  glyph           text,             -- emoji fallback "picture" (no asset needed)
  answer          text not null,    -- canonical answer key
  difficulty      int  not null default 1 check (difficulty between 1 and 5),
  position        int  not null default 0,
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Per-learner memory state (PRD F3 / SRS)
-- ---------------------------------------------------------------------------
create table if not exists public.learner_item_states (
  id                 uuid primary key default gen_random_uuid(),
  learner_id         uuid not null references auth.users (id) on delete cascade,
  item_id            uuid not null references public.items (id) on delete cascade,
  correct_count      int  not null default 0,
  incorrect_count    int  not null default 0,
  attempts           int  not null default 0,
  last_response_ms   int,
  pronunciation_score numeric,       -- nullable; populated by future speech path
  ease               numeric not null default 2.5,
  interval_days      numeric not null default 0,
  repetitions        int  not null default 0,
  due_at             timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (learner_id, item_id)
);

create index if not exists learner_item_states_learner_due_idx
  on public.learner_item_states (learner_id, due_at);

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.profiles            enable row level security;
alter table public.courses             enable row level security;
alter table public.units               enable row level security;
alter table public.lessons             enable row level security;
alter table public.activities          enable row level security;
alter table public.items               enable row level security;
alter table public.learner_item_states enable row level security;

-- Profiles: a user sees and edits only their own profile row.
create policy "profiles_self_select" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_self_upsert" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_self_update" on public.profiles
  for update using (auth.uid() = id);

-- Content: any authenticated user (incl. anonymous) may read PUBLISHED content.
-- Teacher write access is intentionally omitted here (authoring is a later phase).
create policy "courses_read_published" on public.courses
  for select using (published = true);
create policy "units_read_published" on public.units
  for select using (exists (
    select 1 from public.courses c where c.id = units.course_id and c.published));
create policy "lessons_read_published" on public.lessons
  for select using (exists (
    select 1 from public.units u join public.courses c on c.id = u.course_id
    where u.id = lessons.unit_id and c.published));
create policy "activities_read_published" on public.activities
  for select using (exists (
    select 1 from public.lessons l
      join public.units u on u.id = l.unit_id
      join public.courses c on c.id = u.course_id
    where l.id = activities.lesson_id and c.published));
create policy "items_read_published" on public.items
  for select using (exists (
    select 1 from public.activities a
      join public.lessons l on l.id = a.lesson_id
      join public.units u on u.id = l.unit_id
      join public.courses c on c.id = u.course_id
    where a.id = items.activity_id and c.published));

-- Learner state: a learner reads and writes only their own rows.
create policy "lis_select_own" on public.learner_item_states
  for select using (auth.uid() = learner_id);
create policy "lis_insert_own" on public.learner_item_states
  for insert with check (auth.uid() = learner_id);
create policy "lis_update_own" on public.learner_item_states
  for update using (auth.uid() = learner_id);

-- ---------------------------------------------------------------------------
-- Table privileges. RLS restricts WHICH rows are visible, but the API roles
-- still need table-level GRANTs. (The dashboard adds these automatically for
-- tables made in the UI; raw-SQL migrations must grant explicitly.)
-- ---------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select on public.courses, public.units, public.lessons,
  public.activities, public.items to anon, authenticated;
grant select, insert, update on public.learner_item_states to authenticated;
grant select, insert, update on public.profiles to authenticated;
