-- Initial schema for the v1 pilot (District 1 + edge of Chợ Lớn).
--
-- Two rules shape every table below.
--
-- 1. ONE UNLOCK LAYER. `visit_state` is the single source of truth for what a
--    user has unlocked. No lens stores unlock state of its own, and nothing
--    derived from it is persisted. See docs/12-engineering-guide.md section 3.
--
-- 2. NEVER TRUST THE CLIENT. `visit_state` has no insert, update or delete
--    policy at all, so an authenticated client cannot write to it even with a
--    valid session. Only the check-in edge function, running with the service
--    role, may write. A client can read its own rows and nothing else.
--
-- Deviations from the sketch in docs/06-tech-stack.md, both deliberate:
--
--   * `quest_progress` does NOT store completed steps. The sketch has
--     `done_steps`, which would be a second copy of unlock state and would
--     break rule 1 outright: finishing a checkpoint would have to be written
--     twice, and the two copies would drift. Quest progress is derived by
--     intersecting the quest's checkpoint list with `visit_state`. The table
--     survives only to hold things that are genuinely quest-specific and not
--     derivable, such as when a reward was claimed.
--
--   * `footprints` is not created. It belongs to the Social lens, deferred to
--     v1.5 in docs/08-scope.md. Shipping the table early invites code that
--     depends on it.

create extension if not exists postgis with schema extensions;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

-- A missing `visit_state` row means `unknown`; the value exists so a row can
-- record "revealed but not yet visited" explicitly.
create type public.visit_status as enum ('unknown', 'revealed', 'visited');

-- How a visit was proven. `qr` and `quiz` are the fallbacks for the places
-- where GPS is unreliable between the tall buildings of District 1.
create type public.verify_method as enum ('gps', 'qr', 'quiz');

create type public.checkpoint_category as enum (
  'museum',
  'monument',
  'market',
  'religious',
  'architecture',
  'street'
);

-- ---------------------------------------------------------------------------
-- Content. Authored in content/*.json, loaded by the seed script, readable by
-- everyone. No user data, so no per-user policy — only a read policy.
-- ---------------------------------------------------------------------------

create table public.narrators (
  id text primary key,
  name text not null,
  bio text,
  portrait_url text,
  created_at timestamptz not null default now()
);

create table public.checkpoints (
  id text primary key,
  name text not null,
  -- geography, not geometry: distances come back in metres without the caller
  -- having to pick a projection, which is exactly what a check-in needs.
  geom geography(Point, 4326) not null,
  radius_m integer not null check (radius_m between 20 and 500),
  category public.checkpoint_category not null,
  -- Some checkpoints sit where GPS is unreliable. Set by the S3 field survey;
  -- when true the client must offer the QR fallback up front.
  requires_qr_fallback boolean not null default false,
  address text,
  photo_url text,
  created_at timestamptz not null default now()
);

create index checkpoints_geom_idx on public.checkpoints using gist (geom);

create table public.stories (
  id text primary key,
  checkpoint_id text not null references public.checkpoints (id) on delete cascade,
  narrator_id text not null references public.narrators (id),
  title text not null,
  -- Self-defined chapter format: an array of nodes. Kept as jsonb rather than
  -- normalised because the shape is authored, versioned and shipped as a unit.
  nodes jsonb not null,
  created_at timestamptz not null default now()
);

create unique index stories_checkpoint_idx on public.stories (checkpoint_id);

create table public.stamps (
  id text primary key,
  checkpoint_id text not null references public.checkpoints (id) on delete cascade,
  art_url text not null,
  created_at timestamptz not null default now()
);

-- Ownership of a stamp is NOT stored. A stamp is owned exactly when its
-- checkpoint is visited, which is already in visit_state. Storing it again
-- would be a second copy of unlock state.
create unique index stamps_checkpoint_idx on public.stamps (checkpoint_id);

create table public.quests (
  id text primary key,
  title text not null,
  summary text,
  reward text,
  created_at timestamptz not null default now()
);

create table public.quest_steps (
  quest_id text not null references public.quests (id) on delete cascade,
  checkpoint_id text not null references public.checkpoints (id) on delete cascade,
  position integer not null,
  primary key (quest_id, checkpoint_id)
);

create unique index quest_steps_order_idx on public.quest_steps (quest_id, position);

-- ---------------------------------------------------------------------------
-- User state
-- ---------------------------------------------------------------------------

-- THE FOUNDATION LAYER. Every lens reads this. Only the check-in edge function
-- writes it.
create table public.visit_state (
  user_id uuid not null references auth.users (id) on delete cascade,
  checkpoint_id text not null references public.checkpoints (id) on delete cascade,
  status public.visit_status not null default 'visited',
  visited_at timestamptz not null default now(),
  verified_by public.verify_method not null,
  primary key (user_id, checkpoint_id)
);

-- The composite primary key is what makes unlocking idempotent: a second
-- check-in at the same place is an upsert that changes nothing.

create index visit_state_user_idx on public.visit_state (user_id);

-- Walked trail for the Fog of War lens. Cosmetic, client-written, and
-- deliberately NOT a source of unlock truth.
create table public.fog_trail (
  id bigserial primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  geom geography(Point, 4326) not null,
  recorded_at timestamptz not null default now()
);

create index fog_trail_user_time_idx on public.fog_trail (user_id, recorded_at);

-- Quest state that cannot be derived from visit_state. Completion is NOT here.
create table public.quest_progress (
  user_id uuid not null references auth.users (id) on delete cascade,
  quest_id text not null references public.quests (id) on delete cascade,
  started_at timestamptz not null default now(),
  reward_claimed_at timestamptz,
  primary key (user_id, quest_id)
);

-- The Itinerary lens: a user-ordered list of checkpoints. Holds order and
-- membership only; whether a stop is done comes from visit_state.
create table public.itineraries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now()
);

create table public.itinerary_items (
  itinerary_id uuid not null references public.itineraries (id) on delete cascade,
  checkpoint_id text not null references public.checkpoints (id) on delete cascade,
  position integer not null,
  primary key (itinerary_id, checkpoint_id)
);

create index itineraries_user_idx on public.itineraries (user_id);

-- ---------------------------------------------------------------------------
-- Table privileges
--
-- These are not optional and they are not the same thing as the policies
-- below. Postgres checks the GRANT first; a policy is only consulted once the
-- verb is already permitted. Without these, every request fails with
-- "permission denied for table" no matter how the policies are written — which
-- looks like working security and is in fact a broken app.
--
-- Read the two layers together:
--   GRANT  decides which verbs a role may attempt.
--   POLICY decides which rows those verbs may touch.
--
-- visit_state gets SELECT and nothing else. That is the unlock layer expressed
-- as a privilege: an authenticated client cannot even attempt a write, and the
-- missing insert policy stops it a second time. Only the check-in edge
-- function, running as service_role, may write.
-- ---------------------------------------------------------------------------

grant select on
  public.narrators,
  public.checkpoints,
  public.stories,
  public.stamps,
  public.quests,
  public.quest_steps
  to authenticated;

grant select on public.visit_state to authenticated;

grant select, insert on public.fog_trail to authenticated;
grant usage, select on sequence public.fog_trail_id_seq to authenticated;

grant select, insert, update, delete on
  public.quest_progress,
  public.itineraries,
  public.itinerary_items
  to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.narrators enable row level security;
alter table public.checkpoints enable row level security;
alter table public.stories enable row level security;
alter table public.stamps enable row level security;
alter table public.quests enable row level security;
alter table public.quest_steps enable row level security;
alter table public.visit_state enable row level security;
alter table public.fog_trail enable row level security;
alter table public.quest_progress enable row level security;
alter table public.itineraries enable row level security;
alter table public.itinerary_items enable row level security;

-- Content is readable by any signed-in user and writable by no one. The seed
-- script uses the service role, which bypasses these policies.
create policy "content is readable" on public.narrators
  for select to authenticated using (true);
create policy "content is readable" on public.checkpoints
  for select to authenticated using (true);
create policy "content is readable" on public.stories
  for select to authenticated using (true);
create policy "content is readable" on public.stamps
  for select to authenticated using (true);
create policy "content is readable" on public.quests
  for select to authenticated using (true);
create policy "content is readable" on public.quest_steps
  for select to authenticated using (true);

-- visit_state: READ ONLY for the client, and only its own rows.
--
-- There is deliberately no insert, update or delete policy. With RLS enabled
-- and no permissive policy, those statements are rejected for every
-- authenticated user. Unlocking goes through the check-in edge function, which
-- verifies position server-side and writes with the service role.
create policy "own visit state is readable" on public.visit_state
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "own trail is readable" on public.fog_trail
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own trail is writable" on public.fog_trail
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "own quest progress is readable" on public.quest_progress
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own quest progress is writable" on public.quest_progress
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "own itineraries are readable" on public.itineraries
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own itineraries are writable" on public.itineraries
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Items inherit ownership from their itinerary.
create policy "own itinerary items are readable" on public.itinerary_items
  for select to authenticated using (
    exists (
      select 1 from public.itineraries i
      where i.id = itinerary_id and i.user_id = (select auth.uid())
    )
  );
create policy "own itinerary items are writable" on public.itinerary_items
  for all to authenticated
  using (
    exists (
      select 1 from public.itineraries i
      where i.id = itinerary_id and i.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.itineraries i
      where i.id = itinerary_id and i.user_id = (select auth.uid())
    )
  );
