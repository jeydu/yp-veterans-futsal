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


-- 7. Fixtures & results (shown on the website, edited in the organiser portal) ------------------
-- One row per tournament year, and one row per match. Anyone can read them; organisers edit them.

create table if not exists public.seasons (
  year         int primary key check (year between 2000 and 2100),
  champion     text check (char_length(champion) <= 100),
  champion_dv  text check (char_length(champion_dv) <= 100),
  -- true while some results of that year are missing (hides the match and goal totals)
  partial      boolean not null default false
);

create table if not exists public.matches (
  id          uuid primary key default gen_random_uuid(),
  year        int not null references public.seasons (year) on delete cascade,
  day         int not null default 1 check (day between 1 and 60),
  no          int check (no between 1 and 200),
  kickoff     timestamptz,
  home        text not null check (char_length(home) between 1 and 60),
  away        text not null check (char_length(away) between 1 and 60),
  -- both empty = not played yet
  home_score  int check (home_score between 0 and 99),
  away_score  int check (away_score between 0 and 99),
  pen_home    int check (pen_home between 0 and 99),
  pen_away    int check (pen_away between 0 and 99),
  stage       text check (stage in ('semi', 'playoff', 'final')),
  -- YouTube video id of the match stream
  video       text check (video ~ '^[A-Za-z0-9_-]{11}$'),
  -- highlight clips: [{ "at": seconds, "s": clip start, "t": clip end - 5, "team": "...", "score": "1–0" }]
  goals       jsonb not null default '[]'::jsonb
              check (jsonb_typeof(goals) = 'array' and jsonb_array_length(goals) <= 60),
  updated_at  timestamptz not null default now()
);

create index if not exists matches_year_idx on public.matches (year, day, no);

alter table public.seasons enable row level security;
alter table public.matches enable row level security;
grant select on public.seasons, public.matches to anon, authenticated;
grant insert, update, delete on public.seasons, public.matches to authenticated;

drop policy if exists "anyone reads seasons" on public.seasons;
create policy "anyone reads seasons" on public.seasons for select to anon, authenticated using (true);
drop policy if exists "organisers edit seasons" on public.seasons;
create policy "organisers edit seasons" on public.seasons for all to authenticated
  using (public.is_organiser()) with check (public.is_organiser());

drop policy if exists "anyone reads matches" on public.matches;
create policy "anyone reads matches" on public.matches for select to anon, authenticated using (true);
drop policy if exists "organisers edit matches" on public.matches;
create policy "organisers edit matches" on public.matches for all to authenticated
  using (public.is_organiser()) with check (public.is_organiser());


-- 8. Teams & players (organiser portal → Teams & Players) --------------------------------------
-- One row per club. The name must match the name used in fixtures so its logo shows.

create table if not exists public.clubs (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique check (char_length(name) between 1 and 60),
  short       text check (char_length(short) <= 20),
  manager     text check (char_length(manager) <= 100),
  phone       text check (char_length(phone) <= 20),
  -- full web address of the logo, or a path on the website like images/rbg-logo.jpg
  logo        text check (char_length(logo) <= 500),
  -- true for logos that aren't round: the whole logo shows inside the circle
  logo_fit    boolean not null default false,
  -- squad: [{ "name": "...", "no": 10 }]
  players     jsonb not null default '[]'::jsonb
              check (jsonb_typeof(players) = 'array' and jsonb_array_length(players) <= 40),
  created_at  timestamptz not null default now()
);

alter table public.clubs enable row level security;
grant select on public.clubs to anon, authenticated;
grant insert, update, delete on public.clubs to authenticated;
drop policy if exists "anyone reads clubs" on public.clubs;
create policy "anyone reads clubs" on public.clubs for select to anon, authenticated using (true);
drop policy if exists "organisers edit clubs" on public.clubs;
create policy "organisers edit clubs" on public.clubs for all to authenticated
  using (public.is_organiser()) with check (public.is_organiser());

-- Club logos: a public bucket (anyone can see logos), only organisers upload or remove
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('club-logos', 'club-logos', true, 2097152, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists "organisers add club logos" on storage.objects;
create policy "organisers add club logos" on storage.objects for insert to authenticated
  with check (bucket_id = 'club-logos' and public.is_organiser());
drop policy if exists "organisers change club logos" on storage.objects;
create policy "organisers change club logos" on storage.objects for update to authenticated
  using (bucket_id = 'club-logos' and public.is_organiser());
drop policy if exists "organisers remove club logos" on storage.objects;
create policy "organisers remove club logos" on storage.objects for delete to authenticated
  using (bucket_id = 'club-logos' and public.is_organiser());

-- The clubs already on the website (only added if missing)
insert into public.clubs (name, short, logo, logo_fit) values
  ('RK SC', 'RK', 'images/royal-knights-logo.jpg', false),
  ('RBG SC', 'RBG', 'images/rbg-logo.jpg', true),
  ('Stelco SC', 'STELCO', 'images/stelco-logo.jpg', false),
  ('BHC', 'BHC', 'images/bhc-logo.jpg', false),
  ('FT Nakasole', 'NAKASOLE', 'images/ft-nakasole-logo.png', true),
  ('Afiyns SC', 'AFIYNS', 'images/afiyns-logo.jpg', false),
  ('KK Kandumathi', 'KANDUMATHI', 'images/kk-kandumathi-logo.jpg', true),
  ('Old Stars', 'OLD STARS', 'images/old-stars-logo.jpg', true),
  ('FC Mathiveri', 'MATHIVERI', 'images/fc-mathiveri-logo.jpg', true),
  ('Mathiveri Veterans', 'MATH VETS', 'images/mathiveri-veterans-logo.jpg', true),
  ('Aaru FT', 'AARU', 'images/aaru-ft-logo.jpg', false)
on conflict (name) do nothing;


-- 9. Users & roles -------------------------------------------------------------------------------
-- Each organiser has a role; a role is a list of permissions. "Super Admin" can always do everything.
-- Permissions: dashboard, registrations, fixtures, teams, news, gallery, sponsors, users

create table if not exists public.roles (
  name   text primary key check (char_length(name) between 1 and 40),
  perms  text[] not null default '{}'
);
insert into public.roles (name, perms) values
  ('Super Admin',    array['dashboard','registrations','fixtures','teams','news','gallery','sponsors','users']),
  ('Administrator',  array['dashboard','registrations','fixtures','teams','news','gallery','sponsors']),
  ('Match Official', array['fixtures']),
  ('Media Officer',  array['news','gallery'])
on conflict (name) do nothing;

-- Organisers already on the list become Super Admins
alter table public.organisers add column if not exists name text check (char_length(name) <= 100);
alter table public.organisers add column if not exists role text not null default 'Super Admin';
alter table public.organisers drop constraint if exists organisers_role_fkey;
alter table public.organisers add constraint organisers_role_fkey foreign key (role) references public.roles (name) on update cascade;

create or replace function public.has_perm(p text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.organisers o left join public.roles r on r.name = o.role
    where lower(o.email) = lower(auth.jwt() ->> 'email')
      and (o.role = 'Super Admin' or p = any (r.perms))
  );
$$;

alter table public.roles enable row level security;
grant select, insert, update, delete on public.roles to authenticated;
grant insert, update, delete on public.organisers to authenticated;
drop policy if exists "organisers read roles" on public.roles;
create policy "organisers read roles" on public.roles for select to authenticated using (public.is_organiser());
drop policy if exists "user managers edit roles" on public.roles;
create policy "user managers edit roles" on public.roles for all to authenticated
  using (public.has_perm('users')) with check (public.has_perm('users') and name <> '');
drop policy if exists "user managers edit organisers" on public.organisers;
create policy "user managers edit organisers" on public.organisers for all to authenticated
  using (public.has_perm('users')) with check (public.has_perm('users'));

-- Each part of the portal now needs its permission
drop policy if exists "organisers read teams" on public.teams;
create policy "organisers read teams" on public.teams for select to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers update teams" on public.teams;
create policy "organisers update teams" on public.teams for update to authenticated
  using (public.has_perm('registrations')) with check (public.has_perm('registrations'));
drop policy if exists "organisers delete teams" on public.teams;
create policy "organisers delete teams" on public.teams for delete to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers read players" on public.players;
create policy "organisers read players" on public.players for select to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers delete players" on public.players;
create policy "organisers delete players" on public.players for delete to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers read officials" on public.officials;
create policy "organisers read officials" on public.officials for select to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers delete officials" on public.officials;
create policy "organisers delete officials" on public.officials for delete to authenticated using (public.has_perm('registrations'));
drop policy if exists "organisers update settings" on public.settings;
create policy "organisers update settings" on public.settings for update to authenticated
  using (public.has_perm('registrations')) with check (public.has_perm('registrations'));
drop policy if exists "organisers read id cards" on storage.objects;
create policy "organisers read id cards" on storage.objects for select to authenticated
  using (bucket_id = 'id-cards' and public.has_perm('registrations'));
drop policy if exists "organisers delete id cards" on storage.objects;
create policy "organisers delete id cards" on storage.objects for delete to authenticated
  using (bucket_id = 'id-cards' and public.has_perm('registrations'));
drop policy if exists "organisers edit seasons" on public.seasons;
create policy "organisers edit seasons" on public.seasons for all to authenticated
  using (public.has_perm('fixtures')) with check (public.has_perm('fixtures'));
drop policy if exists "organisers edit matches" on public.matches;
create policy "organisers edit matches" on public.matches for all to authenticated
  using (public.has_perm('fixtures')) with check (public.has_perm('fixtures'));
drop policy if exists "organisers edit clubs" on public.clubs;
create policy "organisers edit clubs" on public.clubs for all to authenticated
  using (public.has_perm('teams')) with check (public.has_perm('teams'));
drop policy if exists "organisers add club logos" on storage.objects;
create policy "organisers add club logos" on storage.objects for insert to authenticated
  with check (bucket_id = 'club-logos' and public.has_perm('teams'));
drop policy if exists "organisers change club logos" on storage.objects;
create policy "organisers change club logos" on storage.objects for update to authenticated
  using (bucket_id = 'club-logos' and public.has_perm('teams'));
drop policy if exists "organisers remove club logos" on storage.objects;
create policy "organisers remove club logos" on storage.objects for delete to authenticated
  using (bucket_id = 'club-logos' and public.has_perm('teams'));


-- 10. Website visitors (organiser portal → Dashboard) ------------------------------------------
-- The website adds one row per page view: a random visitor id kept in the browser, nothing personal.

create table if not exists public.visits (
  id       bigint generated always as identity primary key,
  at       timestamptz not null default now(),
  visitor  text not null check (char_length(visitor) between 8 and 40),
  path     text check (char_length(path) <= 100),
  device   text check (device in ('phone', 'tablet', 'computer'))
);
create index if not exists visits_at_idx on public.visits (at);
alter table public.visits enable row level security;
grant insert on public.visits to anon, authenticated;
drop policy if exists "website logs visits" on public.visits;
create policy "website logs visits" on public.visits for insert to anon, authenticated
  with check (at between now() - interval '1 minute' and now() + interval '1 minute');

-- Numbers for the dashboard, in Maldives time
create or replace function public.visit_stats()
returns jsonb
language plpgsql stable security definer
set search_path = public
as $$
declare
  today date := (now() at time zone 'Indian/Maldives')::date;
begin
  if not public.has_perm('dashboard') then raise exception 'No access' using errcode = '42501'; end if;
  return jsonb_build_object(
    'live',        (select count(distinct visitor) from public.visits where at > now() - interval '5 minutes'),
    'today',       (select count(distinct visitor) from public.visits where (at at time zone 'Indian/Maldives')::date = today),
    'today_views', (select count(*) from public.visits where (at at time zone 'Indian/Maldives')::date = today),
    'all_time',    (select count(distinct visitor) from public.visits),
    'days', (select jsonb_agg(jsonb_build_object('day', d,
                'visitors', (select count(distinct visitor) from public.visits v where (v.at at time zone 'Indian/Maldives')::date = d)) order by d)
             from (select (today - g) as d from generate_series(0, 6) g) x),
    'devices', (select coalesce(jsonb_object_agg(device, n), '{}'::jsonb) from (
                 select coalesce(device, 'computer') as device, count(distinct visitor) as n from public.visits
                 where at > now() - interval '7 days' group by 1) y)
  );
end;
$$;
revoke all on function public.visit_stats() from public;
grant execute on function public.visit_stats() to authenticated;


-- 11. News, gallery and sponsors ---------------------------------------------------------------

create table if not exists public.posts (
  id         uuid primary key default gen_random_uuid(),
  title      text not null check (char_length(title) between 1 and 200),
  body       text check (char_length(body) <= 20000),
  cover      text check (char_length(cover) <= 500),
  posted_on  date not null default current_date,
  published  boolean not null default true,
  -- shown in the photo slider at the top of the News section
  in_slider  boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.gallery (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null check (kind in ('photo', 'video')),
  url        text not null check (char_length(url) <= 500),
  title      text check (char_length(title) <= 200),
  created_at timestamptz not null default now()
);

create table if not exists public.sponsors (
  id       uuid primary key default gen_random_uuid(),
  name     text check (char_length(name) <= 100),
  logo     text check (char_length(logo) <= 500),
  level    text not null default 'Partner' check (level in ('Main Sponsor', 'Gold Sponsor', 'Silver Sponsor', 'Partner', 'Media Partner')),
  website  text check (char_length(website) <= 300),
  sort     int not null default 0,
  visible  boolean not null default true
);

alter table public.posts enable row level security;
alter table public.gallery enable row level security;
alter table public.sponsors enable row level security;
grant select on public.posts, public.gallery, public.sponsors to anon, authenticated;
grant insert, update, delete on public.posts, public.gallery, public.sponsors to authenticated;

drop policy if exists "anyone reads published posts" on public.posts;
create policy "anyone reads published posts" on public.posts for select to anon, authenticated using (published or public.has_perm('news'));
drop policy if exists "news editors edit posts" on public.posts;
create policy "news editors edit posts" on public.posts for all to authenticated using (public.has_perm('news')) with check (public.has_perm('news'));
drop policy if exists "anyone reads gallery" on public.gallery;
create policy "anyone reads gallery" on public.gallery for select to anon, authenticated using (true);
drop policy if exists "gallery editors edit gallery" on public.gallery;
create policy "gallery editors edit gallery" on public.gallery for all to authenticated using (public.has_perm('gallery')) with check (public.has_perm('gallery'));
drop policy if exists "anyone reads sponsors" on public.sponsors;
create policy "anyone reads sponsors" on public.sponsors for select to anon, authenticated using (visible or public.has_perm('sponsors'));
drop policy if exists "sponsor editors edit sponsors" on public.sponsors;
create policy "sponsor editors edit sponsors" on public.sponsors for all to authenticated using (public.has_perm('sponsors')) with check (public.has_perm('sponsors'));

-- Photos and videos for news, gallery and sponsors: public bucket, 50 MB each
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 52428800, array['image/png', 'image/jpeg', 'image/webp', 'video/mp4', 'video/webm', 'video/quicktime'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
drop policy if exists "editors add media" on storage.objects;
create policy "editors add media" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (public.has_perm('news') or public.has_perm('gallery') or public.has_perm('sponsors')));
drop policy if exists "editors remove media" on storage.objects;
create policy "editors remove media" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and (public.has_perm('news') or public.has_perm('gallery') or public.has_perm('sponsors')));


-- 12. Site settings: the website's logos (organiser portal → Site Settings) ---------------------
alter table public.settings add column if not exists site_logo text check (char_length(site_logo) <= 500);
alter table public.settings add column if not exists club_logo text check (char_length(club_logo) <= 500);
drop policy if exists "site editors update settings" on public.settings;
create policy "site editors update settings" on public.settings for update to authenticated
  using (public.has_perm('settings')) with check (public.has_perm('settings'));
update public.roles set perms = array_append(perms, 'settings') where name = 'Super Admin' and not ('settings' = any (perms));
drop policy if exists "editors add media" on storage.objects;
create policy "editors add media" on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and (public.has_perm('news') or public.has_perm('gallery') or public.has_perm('sponsors') or public.has_perm('settings')));
drop policy if exists "editors remove media" on storage.objects;
create policy "editors remove media" on storage.objects for delete to authenticated
  using (bucket_id = 'media' and (public.has_perm('news') or public.has_perm('gallery') or public.has_perm('sponsors') or public.has_perm('settings')));
