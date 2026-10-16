-- YP Veterans Futsal: database setup
--
-- Run this once in Supabase: SQL Editor -> New query -> paste everything -> Run.
-- It is safe to run again; it won't duplicate anything.
--
-- What the public (the website) can do:  register a team, its players and ID photos.
-- What the public can NOT do:             read, change or delete anything.
-- What organisers can do (after logging in on admin.html): read, confirm/reject, delete.


-- 1. Organisers -------------------------------------------------------------
-- Only these email addresses can see registrations and ID photos.
-- Each one also needs a login: Authentication -> Users -> Add user.

create table if not exists public.organisers (
  email text primary key
);

insert into public.organisers (email)
values ('jadhullo7@gmail.com')
on conflict do nothing;

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

-- True while registration is open (used by the security rules below)
create or replace function public.registration_open()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select registration_open from public.settings where id = 1), false);
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


-- 4. Who can do what --------------------------------------------------------

alter table public.organisers enable row level security;
alter table public.teams      enable row level security;
alter table public.players    enable row level security;
alter table public.settings   enable row level security;

grant insert                 on public.teams, public.players to anon, authenticated;
grant select, update, delete on public.teams                 to authenticated;
grant select, delete         on public.players               to authenticated;
grant select                 on public.organisers            to authenticated;
grant select                 on public.settings              to anon, authenticated;
grant update                 on public.settings              to authenticated;

-- The public can register while registration is open, but can't read anything back
drop policy if exists "public can register teams" on public.teams;
create policy "public can register teams" on public.teams
  for insert to anon, authenticated
  with check (status = 'pending' and (public.registration_open() or public.is_organiser()));

drop policy if exists "public can add players" on public.players;
create policy "public can add players" on public.players
  for insert to anon, authenticated
  with check (public.registration_open() or public.is_organiser());

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

drop policy if exists "organisers read organisers" on public.organisers;
create policy "organisers read organisers" on public.organisers
  for select to authenticated using (public.is_organiser());


-- 5. ID card photos (private storage) ----------------------------------------
-- Private bucket: photos are never public. Max 3 MB each, images only.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('id-cards', 'id-cards', false, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "public can upload id cards" on storage.objects;
create policy "public can upload id cards" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'id-cards' and (public.registration_open() or public.is_organiser()));

drop policy if exists "organisers read id cards" on storage.objects;
create policy "organisers read id cards" on storage.objects
  for select to authenticated
  using (bucket_id = 'id-cards' and public.is_organiser());

drop policy if exists "organisers delete id cards" on storage.objects;
create policy "organisers delete id cards" on storage.objects
  for delete to authenticated
  using (bucket_id = 'id-cards' and public.is_organiser());
