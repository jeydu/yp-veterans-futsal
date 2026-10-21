-- YP Veterans Futsal: database setup
--
-- Run this once in Supabase: SQL Editor -> New query -> paste everything -> Run.
-- It is safe to run again; it won't duplicate anything.
--
-- What the public (the website) can do:  register a team, its officials, players and their photos.
-- What the public can NOT do:             read, change or delete anything.
-- What organisers can do (after logging in on admin.html): read, confirm/reject, delete.


-- 1. Organisers -------------------------------------------------------------
-- Only these email addresses can see registrations and ID photos.
-- Each one also needs a login: Authentication -> Users -> Add user.

create table if not exists public.organisers (
  email text primary key
);

-- The organiser logins are not kept in this file, because the website (and this file) are public.
-- Add each one yourself in the SQL Editor (it only needs doing once per organiser):
--   insert into public.organisers (email) values ('organiser@example.com') on conflict do nothing;
-- Phone-number logins are stored as <960 + number>@phone.ypveterans.com (admin.html converts the number).

create or replace function public.is_organiser()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.organisers
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;


-- 1b. Settings: organisers open or close registration ------------------------
-- One row only. The website reads it; only organisers can change it.

create table if not exists public.settings (
  id                 int primary key default 1 check (id = 1),
  registration_open  boolean not null default true,
  closed_message     text check (char_length(closed_message) <= 500),
  updated_at         timestamptz not null default now()
);

insert into public.settings (id) values (1) on conflict do nothing;

-- Optional closing date (registration closes automatically after it)
-- and instructions shown to teams (one per line)
alter table public.settings add column if not exists closes_at timestamptz;
alter table public.settings add column if not exists instructions text;
alter table public.settings drop constraint if exists settings_instructions_length;
alter table public.settings add constraint settings_instructions_length check (char_length(instructions) <= 1000);

-- True while registration is open and the closing date hasn't passed (used by the security rules below)
create or replace function public.registration_open()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((
    select registration_open and (closes_at is null or now() < closes_at)
    from public.settings where id = 1
  ), false);
$$;


-- 2. Teams ------------------------------------------------------------------

create table if not exists public.teams (
  id          uuid primary key,
  created_at  timestamptz not null default now(),
  team_name   text not null check (char_length(team_name) between 1 and 100),
  manager     text not null check (char_length(manager) between 1 and 100),
  phone       text not null check (char_length(phone) between 7 and 20),
  island      text not null check (char_length(island) between 1 and 100),
  notes       text check (char_length(notes) <= 1000),
  status      text not null default 'pending'
              check (status in ('pending', 'confirmed', 'rejected'))
);


-- 3. Players ----------------------------------------------------------------

create table if not exists public.players (
  id             uuid primary key default gen_random_uuid(),
  team_id        uuid not null references public.teams (id) on delete cascade,
  position       int  not null check (position between 1 and 20),
  name           text not null check (char_length(name) between 1 and 100),
  age            int  not null check (age between 35 and 99),
  id_photo_path  text not null check (char_length(id_photo_path) <= 200)
);

create index if not exists players_team_id_idx on public.players (team_id);

-- Jersey number for each player (older registrations don't have one)
alter table public.players add column if not exists jersey_number int check (jersey_number between 0 and 99);

-- Passport-size photo for each player (older registrations don't have one)
alter table public.players add column if not exists passport_photo_path text check (char_length(passport_photo_path) <= 200);


-- 3b. Team officials: manager, coach, official and medic ----------------------

create table if not exists public.officials (
  id                   uuid primary key default gen_random_uuid(),
  team_id              uuid not null references public.teams (id) on delete cascade,
  role                 text not null,
  name                 text not null check (char_length(name) between 1 and 100),
  phone                text check (char_length(phone) between 7 and 20),
  passport_photo_path  text not null check (char_length(passport_photo_path) <= 200),
  id_photo_path        text not null check (char_length(id_photo_path) <= 200),
  unique (team_id, role)
);

create index if not exists officials_team_id_idx on public.officials (team_id);

-- Only the manager gives a phone number
alter table public.officials alter column phone drop not null;

-- The four roles. 'assistant' was used before 2026-10-17 and is kept so older registrations stay valid
alter table public.officials drop constraint if exists officials_role_check;
alter table public.officials add constraint officials_role_check check (role in ('manager', 'coach', 'official', 'medic', 'assistant'));


-- 4. Who can do what --------------------------------------------------------

alter table public.organisers enable row level security;
alter table public.teams      enable row level security;
alter table public.players    enable row level security;
alter table public.officials  enable row level security;
alter table public.settings   enable row level security;

-- Nobody writes teams, officials or players directly: the website uses register_team() (section 6)
revoke insert on public.teams, public.players, public.officials from anon, authenticated;
grant select, update, delete on public.teams                 to authenticated;
grant select, delete         on public.players, public.officials to authenticated;
grant select                 on public.organisers            to authenticated;
grant select                 on public.settings              to anon, authenticated;
grant update                 on public.settings              to authenticated;

-- Old direct-insert rules (before 2026-10-18), removed
drop policy if exists "public can register teams" on public.teams;
drop policy if exists "public can add players" on public.players;
drop policy if exists "public can add officials" on public.officials;

-- Anyone can see whether registration is open; only organisers can change it
drop policy if exists "anyone reads settings" on public.settings;
create policy "anyone reads settings" on public.settings
  for select to anon, authenticated using (true);

drop policy if exists "organisers update settings" on public.settings;
create policy "organisers update settings" on public.settings
  for update to authenticated
  using (public.is_organiser()) with check (public.is_organiser());

-- Organisers can read, update and delete
drop policy if exists "organisers read teams" on public.teams;
create policy "organisers read teams" on public.teams
  for select to authenticated using (public.is_organiser());

drop policy if exists "organisers update teams" on public.teams;
create policy "organisers update teams" on public.teams
  for update to authenticated
  using (public.is_organiser()) with check (public.is_organiser());

drop policy if exists "organisers delete teams" on public.teams;
create policy "organisers delete teams" on public.teams
  for delete to authenticated using (public.is_organiser());

drop policy if exists "organisers read players" on public.players;
create policy "organisers read players" on public.players
  for select to authenticated using (public.is_organiser());

drop policy if exists "organisers delete players" on public.players;
create policy "organisers delete players" on public.players
  for delete to authenticated using (public.is_organiser());

drop policy if exists "organisers read officials" on public.officials;
create policy "organisers read officials" on public.officials
  for select to authenticated using (public.is_organiser());

drop policy if exists "organisers delete officials" on public.officials;
create policy "organisers delete officials" on public.officials
  for delete to authenticated using (public.is_organiser());

drop policy if exists "organisers read organisers" on public.organisers;
create policy "organisers read organisers" on public.organisers
  for select to authenticated using (public.is_organiser());


-- 5. Photos: passport and ID card (private storage) --------------------------
-- Private bucket (named id-cards): photos are never public. Max 3 MB each, images only.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('id-cards', 'id-cards', false, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Who can upload photos: see section 6

drop policy if exists "organisers read id cards" on storage.objects;
create policy "organisers read id cards" on storage.objects
  for select to authenticated
  using (bucket_id = 'id-cards' and public.is_organiser());

drop policy if exists "organisers delete id cards" on storage.objects;
create policy "organisers delete id cards" on storage.objects
  for delete to authenticated
  using (bucket_id = 'id-cards' and public.is_organiser());


-- 6. Registering a team: one checked, all-or-nothing step ---------------------
-- The website calls register_team(). It saves the team, its 4 officials and 10-12 players together,
-- or nothing at all, and only after checking the squad rules and that every photo was uploaded.

create or replace function public.team_exists(team text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.teams where id::text = team);
$$;

create or replace function public.register_team(p jsonb)
returns uuid
language plpgsql security definer
set search_path = public
as $$
declare
  tid  uuid  := nullif(p->>'id', '')::uuid;
  pl   jsonb := coalesce(p->'players', '[]'::jsonb);
  ofs  jsonb := coalesce(p->'officials', '[]'::jsonb);
  n    int   := jsonb_array_length(coalesce(p->'players', '[]'::jsonb));
  missing int;
begin
  if not (public.registration_open() or public.is_organiser()) then
    raise exception 'Registration is closed' using errcode = '42501';
  end if;
  if tid is null then raise exception 'Missing team id'; end if;
  if exists (select 1 from public.teams where id = tid) then raise exception 'This team was already sent'; end if;
  if n < 10 or n > 12 then raise exception 'A team needs 10 to 12 players'; end if;
  if jsonb_array_length(ofs) <> 4
     or (select count(distinct x->>'role') from jsonb_array_elements(ofs) x
         where x->>'role' in ('manager', 'coach', 'official', 'medic')) <> 4 then
    raise exception 'A team needs a manager, coach, official and medic';
  end if;
  if (select count(distinct (x->>'jersey_number')::int) from jsonb_array_elements(pl) x) <> n then
    raise exception 'Each player needs a different jersey number';
  end if;

  -- Every passport-size photo and ID photo must already be uploaded
  select count(*) into missing from (
    select tid::text || '/players/' || lpad(i::text, 2, '0') || '-' || k || '.jpg' as path
      from generate_series(1, n) i, unnest(array['photo', 'id']) k
    union all
    select tid::text || '/officials/' || r || '-' || k || '.jpg'
      from unnest(array['manager', 'coach', 'official', 'medic']) r, unnest(array['photo', 'id']) k
  ) want
  where not exists (select 1 from storage.objects o where o.bucket_id = 'id-cards' and o.name = want.path);
  if missing > 0 then raise exception '% photos are missing', missing; end if;

  insert into public.teams (id, team_name, manager, phone, island)
  select tid, trim(p->>'team_name'), trim(m->>'name'), trim(m->>'phone'), trim(p->>'island')
    from jsonb_array_elements(ofs) m where m->>'role' = 'manager';

  insert into public.officials (team_id, role, name, phone, passport_photo_path, id_photo_path)
  select tid, x->>'role', trim(x->>'name'),
         case when x->>'role' = 'manager' then trim(x->>'phone') end,
         tid::text || '/officials/' || (x->>'role') || '-photo.jpg',
         tid::text || '/officials/' || (x->>'role') || '-id.jpg'
    from jsonb_array_elements(ofs) x;

  insert into public.players (team_id, position, name, age, jersey_number, passport_photo_path, id_photo_path)
  select tid, i, trim(x->>'name'), (x->>'age')::int, (x->>'jersey_number')::int,
         tid::text || '/players/' || lpad(i::text, 2, '0') || '-photo.jpg',
         tid::text || '/players/' || lpad(i::text, 2, '0') || '-id.jpg'
    from jsonb_array_elements(pl) with ordinality as t(x, i);

  return tid;
end;
$$;

revoke all on function public.register_team(jsonb) from public;
grant execute on function public.register_team(jsonb) to anon, authenticated;

-- No two players in a team share a jersey number or a place in the list
create unique index if not exists players_team_jersey_key on public.players (team_id, jersey_number) where jersey_number is not null;
create unique index if not exists players_team_position_key on public.players (team_id, position);

-- Photo uploads: only the exact names the form uses, and only for a team that isn't saved yet
drop policy if exists "public can upload id cards" on storage.objects;
create policy "public can upload id cards" on storage.objects
  for insert to anon, authenticated
  with check (
    bucket_id = 'id-cards' and (
      public.is_organiser() or (
        public.registration_open()
        and name ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(players/(0[1-9]|1[0-2])|officials/(manager|coach|official|medic))-(photo|id)\.jpg$'
        and not public.team_exists(split_part(name, '/', 1))
      )
    )
  );
