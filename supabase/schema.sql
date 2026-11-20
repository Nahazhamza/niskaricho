-- =============================================================================
--  Niskaricho? (നിസ്കരിച്ചോ?) — Supabase / PostgreSQL schema
-- =============================================================================
--  Design principle: THE SERVER IS THE SOURCE OF TRUTH.
--
--  * Clients can READ prayer logs, streaks, nudges, etc. through RLS, but they
--    can NEVER insert or update them directly. Every write goes through a
--    SECURITY DEFINER function (RPC) that:
--      - uses the database clock now(), never a client-supplied timestamp
--      - recomputes the prayer window on the server from the user's stored
--        location (astronomical calculation implemented below in SQL)
--      - decides On-Time vs Qada itself
--      - enforces the 5-minute minimum focus duration
--  * Photo proofs are immutable once uploaded (no UPDATE/DELETE policies) and
--    their accepted timestamp is the storage object's server-side created_at.
--
--  Run this whole file once in the Supabase SQL editor (or `supabase db push`).
--  It is idempotent enough to re-run during development.
-- =============================================================================

create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
-- 0. Enums
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.prayer_name as enum ('fajr','dhuhr','asr','maghrib','isha');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.prayer_status as enum ('in_progress','on_time','qada','missed','excused');
exception when duplicate_object then null; end $$;

do $$ begin
  -- Mirrors the presets of the `adhan_dart` package used on the client.
  create type public.calc_method as enum ('karachi','muslim_world_league','egyptian','north_america','kuwait','dubai',
    'umm_al_qura','qatar','singapore','indonesian','turkey','morocco','jordan');
exception when duplicate_object then null; end $$;
-- Upgrades from v1: add the UAE (IACAD / Dubai) method.
alter type public.prayer_status add value if not exists 'excused';
alter type public.calc_method add value if not exists 'dubai';
alter type public.calc_method add value if not exists 'umm_al_qura';
alter type public.calc_method add value if not exists 'qatar';
alter type public.calc_method add value if not exists 'singapore';
alter type public.calc_method add value if not exists 'indonesian';
alter type public.calc_method add value if not exists 'turkey';
alter type public.calc_method add value if not exists 'morocco';
alter type public.calc_method add value if not exists 'jordan';

do $$ begin
  create type public.asr_madhab as enum ('shafi','hanafi');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.circle_role as enum ('owner','member');
exception when duplicate_object then null; end $$;

-- -----------------------------------------------------------------------------
-- 1. Tunables (one row). Change here, not in the app.
-- -----------------------------------------------------------------------------
create table if not exists public.app_config (
  id                        boolean primary key default true check (id),
  min_focus_seconds         int  not null default 300,   -- 5 minute Khushu' timer
  max_session_minutes       int  not null default 90,    -- open session expires after this
  nudge_window_minutes      int  not null default 20,    -- nudges allowed only in last N minutes
  photo_deadline_minutes    int  not null default 10,    -- photo must follow completion within N min
  qada_lookback_days        int  not null default 7,     -- how far back a Qada can be logged
  location_cooldown_hours   int  not null default 6,     -- anti "teleport" to shift prayer windows
  join_attempts_per_hour    int  not null default 10,    -- invite code brute-force throttle
  settings_cooldown_hours   int  not null default 6      -- method / madhab / mosque offsets
);
alter table public.app_config add column if not exists settings_cooldown_hours int not null default 6;
insert into public.app_config default values on conflict do nothing;

-- -----------------------------------------------------------------------------
-- 2. Tables
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  display_name        text not null default 'Friend' check (char_length(display_name) between 1 and 40),
  avatar_url          text,
  -- Location is PRIVATE (column privileges below hide it from peers).
  latitude            double precision check (latitude between -90 and 90),
  longitude           double precision check (longitude between -180 and 180),
  timezone            text not null default 'Asia/Kolkata',
  calc_method         public.calc_method not null default 'karachi',
  asr_madhab          public.asr_madhab  not null default 'shafi',
  location_updated_at timestamptz,
  created_at          timestamptz not null default now()
);
-- Prayer-time settings (v3). method_auto: pick the method from the region
-- (time zone) on every move. minute_offsets: Fajr, Dhuhr, Asr, Maghrib, Isha
-- shifts in minutes, to match the local mosque (each between -10 and +10).
alter table public.profiles add column if not exists method_auto boolean not null default true;
alter table public.profiles add column if not exists minute_offsets int[] not null default '{0,0,0,0,0}';
alter table public.profiles add column if not exists settings_updated_at timestamptz;
do $$ begin
  alter table public.profiles add constraint minute_offsets_valid check (
    array_length(minute_offsets, 1) = 5 and -10 <= all(minute_offsets) and 10 >= all(minute_offsets));
exception when duplicate_object then null; end $$;

create table if not exists public.circles (
  id             uuid primary key default gen_random_uuid(),
  name           text not null check (char_length(name) between 2 and 40),
  invite_code    char(6) not null unique check (invite_code ~ '^[0-9]{6}$'),
  require_photo  boolean not null default false,   -- BeReal-style proof mode
  created_by     uuid not null references public.profiles(id) on delete cascade,
  created_at     timestamptz not null default now()
);

create table if not exists public.circle_members (
  circle_id  uuid not null references public.circles(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  role       public.circle_role not null default 'member',
  joined_at  timestamptz not null default now(),
  primary key (circle_id, user_id)
);
create index if not exists circle_members_user_idx on public.circle_members(user_id);

create table if not exists public.prayer_logs (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles(id) on delete cascade,
  prayer_date        date not null,                 -- the user's LOCAL prayer day
  prayer             public.prayer_name not null,
  status             public.prayer_status not null,
  window_start       timestamptz not null,          -- server-computed
  window_end         timestamptz not null,          -- server-computed
  started_at         timestamptz,                   -- server clock (start_prayer)
  completed_at       timestamptz,                   -- server clock (complete_prayer)
  focus_seconds      int,
  focus_verified     boolean not null default false,
  photo_path         text,
  photo_uploaded_at  timestamptz,                   -- storage.objects.created_at
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (user_id, prayer_date, prayer)
);
create index if not exists prayer_logs_user_date_idx on public.prayer_logs(user_id, prayer_date desc);

create table if not exists public.streaks (
  user_id              uuid primary key references public.profiles(id) on delete cascade,
  current_days         int  not null default 0,   -- consecutive 5/5 on-time days (🔥)
  best_days            int  not null default 0,
  fajr_current_days    int  not null default 0,
  fajr_best_days       int  not null default 0,
  last_full_date       date,
  updated_at           timestamptz not null default now()
);

create table if not exists public.circle_streaks (
  circle_id            uuid primary key references public.circles(id) on delete cascade,
  full_fajr_current    int  not null default 0,   -- every member prayed Fajr on time
  full_fajr_best       int  not null default 0,
  last_full_fajr_date  date,
  updated_at           timestamptz not null default now()
);

create table if not exists public.badges (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  code        text not null,     -- e.g. 'streak_7', 'streak_40', 'fajr_30', 'circle_fajr_7'
  circle_id   uuid references public.circles(id) on delete cascade,
  awarded_at  timestamptz not null default now(),
  primary key (user_id, code)
);

create table if not exists public.nudges (
  id           uuid primary key default gen_random_uuid(),
  circle_id    uuid not null references public.circles(id) on delete cascade,
  sender_id    uuid not null references public.profiles(id) on delete cascade,
  receiver_id  uuid not null references public.profiles(id) on delete cascade,
  prayer       public.prayer_name not null,
  prayer_date  date not null,
  created_at   timestamptz not null default now(),
  seen_at      timestamptz,
  check (sender_id <> receiver_id),
  unique (sender_id, receiver_id, prayer_date, prayer)   -- one nudge per prayer per friend
);
create index if not exists nudges_receiver_idx on public.nudges(receiver_id, created_at desc);

create table if not exists public.join_attempts (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  success     boolean not null,
  created_at  timestamptz not null default now()
);
create index if not exists join_attempts_user_idx on public.join_attempts(user_id, created_at desc);

-- -----------------------------------------------------------------------------
-- 3. Astronomical prayer-time engine (server-side mirror of the client `adhan`)
--    Algorithm: PrayTimes.org / Meeus low-precision solar position.
--    Accuracy ≈ ±1 min vs adhan_dart — the server's window is authoritative.
-- -----------------------------------------------------------------------------
create or replace function public._fix_hour(h double precision)
returns double precision language sql immutable as $$ select h - 24.0 * floor(h / 24.0) $$;

create or replace function public._fix_angle(a double precision)
returns double precision language sql immutable as $$ select a - 360.0 * floor(a / 360.0) $$;

-- Sun declination (degrees) and equation of time (hours) for a Julian date.
create or replace function public._sun_position(jd double precision,
  out decl double precision, out eqt double precision)
language plpgsql immutable as $$
declare
  d  double precision := jd - 2451545.0;
  g  double precision := public._fix_angle(357.529 + 0.98560028 * d);
  q  double precision := public._fix_angle(280.459 + 0.98564736 * d);
  l  double precision;
  e  double precision := 23.439 - 0.00000036 * d;
  ra double precision;
begin
  l    := public._fix_angle(q + 1.915 * sind(g) + 0.020 * sind(2 * g));
  ra   := atan2d(cosd(e) * sind(l), cosd(l)) / 15.0;
  eqt  := q / 15.0 - public._fix_hour(ra);
  decl := asind(sind(e) * sind(l));
end $$;

-- Hours (local solar, before longitude shift) when the sun is `angle` degrees
-- below the horizon. ccw=true -> before noon (morning), false -> afternoon.
create or replace function public._sun_angle_time(jd double precision, angle double precision,
  lat double precision, ccw boolean)
returns double precision language plpgsql immutable as $$
declare
  sp   record;
  noon double precision;
  x    double precision;
  t    double precision;
begin
  sp   := public._sun_position(jd);
  noon := public._fix_hour(12 - sp.eqt);
  x    := (-sind(angle) - sind(sp.decl) * sind(lat)) / (cosd(sp.decl) * cosd(lat));
  -- The sun never reaches this angle today (far north/south in summer):
  -- return null and let the high-latitude rule decide.
  if x > 1 or x < -1 then return null; end if;
  t    := acosd(x) / 15.0;
  return noon + case when ccw then -t else t end;
end $$;

create or replace function public.compute_prayer_times(
  p_lat double precision, p_lng double precision, p_date date,
  p_method public.calc_method default 'karachi',
  p_madhab public.asr_madhab default 'shafi')
returns table (fajr timestamptz, sunrise timestamptz, dhuhr timestamptz,
               asr timestamptz, maghrib timestamptz, isha timestamptz)
language plpgsql stable as $$
declare
  jd0        double precision := to_char(p_date, 'J')::int - 0.5 - p_lng / 360.0;
  fajr_angle double precision;
  isha_angle double precision;
  factor     double precision := case when p_madhab = 'hanafi' then 2 else 1 end;
  base       timestamptz := (p_date::timestamp at time zone 'UTC');
  sp         record;
  asr_angle  double precision;
  adj_rise int; adj_dhuhr int; adj_asr int; adj_maghrib int; isha_interval int;
  night double precision;
  h_fajr double precision; h_rise double precision; h_dhuhr double precision;
  h_asr  double precision; h_set  double precision; h_isha  double precision;
begin
  -- Angles and per-method minute offsets, identical to adhan_dart's presets.
  -- (UAE: official timetable has no +3 on Asr, so that preset offset is 0.)
  -- isha_interval > 0 means Isha = sunset + N minutes (Umm al-Qura, Qatar).
  select a.f, a.i, a.ii, a.rise, a.dh, a.asr_adj, a.mag
    into fajr_angle, isha_angle, isha_interval, adj_rise, adj_dhuhr, adj_asr, adj_maghrib
    from (values
    ('karachi',             18.0, 18.0,  0,  0, 1, 0, 0),
    ('muslim_world_league', 18.0, 17.0,  0,  0, 1, 0, 0),
    ('egyptian',            19.5, 17.5,  0,  0, 1, 0, 0),
    ('north_america',       15.0, 15.0,  0,  0, 1, 0, 0),
    ('kuwait',              18.0, 17.5,  0,  0, 0, 0, 0),
    ('dubai',               18.2, 18.2,  0, -3, 3, 0, 3),
    ('umm_al_qura',         18.5,  0.0, 90,  0, 0, 0, 0),
    ('qatar',               18.0,  0.0, 90,  0, 0, 0, 0),
    ('singapore',           20.0, 18.0,  0,  0, 1, 0, 0),
    ('indonesian',          20.0, 18.0,  0,  0, 1, 0, 0),
    ('turkey',              18.0, 17.0,  0, -7, 5, 4, 7),
    ('morocco',             19.0, 17.0,  0, -3, 5, 0, 5),
    ('jordan',              18.0, 18.0,  0,  0, 0, 0, 5)) as a(m, f, i, ii, rise, dh, asr_adj, mag)
  where a.m = p_method::text;

  h_fajr  := public._sun_angle_time(jd0 + 5/24.0,  fajr_angle, p_lat, true);
  h_rise  := public._sun_angle_time(jd0 + 6/24.0,  0.833,      p_lat, true);
  sp      := public._sun_position(jd0 + 12/24.0);
  h_dhuhr := public._fix_hour(12 - sp.eqt);
  sp      := public._sun_position(jd0 + 13/24.0);
  asr_angle := -atand(1.0 / (factor + tand(abs(p_lat - sp.decl))));
  h_asr   := public._sun_angle_time(jd0 + 13/24.0, asr_angle,  p_lat, false);
  h_set   := public._sun_angle_time(jd0 + 18/24.0, 0.833,      p_lat, false);
  h_isha  := case when isha_interval > 0 then h_set + isha_interval / 60.0
                  else public._sun_angle_time(jd0 + 18/24.0, isha_angle, p_lat, false) end;
  if h_rise is null or h_set is null then
    raise exception 'polar_location_unsupported' using hint = 'The sun does not rise or set here today';
  end if;
  -- High latitudes ("middle of the night", same as adhan): Fajr is never
  -- earlier than sunrise - night/2, Isha never later than sunset + night/2.
  night := 24 - (h_set - h_rise);
  if h_fajr is null or h_fajr < h_rise - night / 2 then h_fajr := h_rise - night / 2; end if;
  if isha_interval = 0 and (h_isha is null or h_isha > h_set + night / 2) then h_isha := h_set + night / 2; end if;

  -- local-solar hours -> UTC instants (p_date is the LOCAL calendar day)
  fajr    := base + make_interval(secs => (h_fajr  - p_lng / 15.0) * 3600);
  sunrise := base + make_interval(secs => (h_rise  - p_lng / 15.0) * 3600 + adj_rise * 60);
  dhuhr   := base + make_interval(secs => (h_dhuhr - p_lng / 15.0) * 3600 + adj_dhuhr * 60); -- safety after zawal
  asr     := base + make_interval(secs => (h_asr   - p_lng / 15.0) * 3600 + adj_asr * 60);
  maghrib := base + make_interval(secs => (h_set   - p_lng / 15.0) * 3600 + adj_maghrib * 60);
  isha    := base + make_interval(secs => (h_isha  - p_lng / 15.0) * 3600);
  return next;
end $$;

-- Valid windows for one user on one local prayer day.
--   Fajr    : Fajr    -> Sunrise
--   Dhuhr   : Dhuhr   -> Asr
--   Asr     : Asr     -> Maghrib
--   Maghrib : Maghrib -> Isha
--   Isha    : Isha    -> next day's Fajr
create or replace function public.prayer_windows_for(p_user uuid, p_date date)
returns table (prayer public.prayer_name, window_start timestamptz, window_end timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare
  pr record; t record; tn record; o int[];
begin
  select * into pr from profiles where id = p_user;
  if pr.latitude is null then
    raise exception 'location_required' using hint = 'Call set_my_location first';
  end if;
  select * into t  from compute_prayer_times(pr.latitude, pr.longitude, p_date,     pr.calc_method, pr.asr_madhab);
  select * into tn from compute_prayer_times(pr.latitude, pr.longitude, p_date + 1, pr.calc_method, pr.asr_madhab);
  -- Mosque offsets move each prayer's start (and so the previous window's end).
  o := coalesce(pr.minute_offsets, '{0,0,0,0,0}');
  return query values
    ('fajr'::prayer_name,    t.fajr    + make_interval(mins => o[1]), t.sunrise),
    ('dhuhr'::prayer_name,   t.dhuhr   + make_interval(mins => o[2]), t.asr     + make_interval(mins => o[3])),
    ('asr'::prayer_name,     t.asr     + make_interval(mins => o[3]), t.maghrib + make_interval(mins => o[4])),
    ('maghrib'::prayer_name, t.maghrib + make_interval(mins => o[4]), t.isha    + make_interval(mins => o[5])),
    ('isha'::prayer_name,    t.isha    + make_interval(mins => o[5]), tn.fajr   + make_interval(mins => o[1]));
end $$;

-- The user's local calendar date right now.
create or replace function public._local_date(p_user uuid)
returns date language sql stable security definer set search_path = public as $$
  select (now() at time zone coalesce((select timezone from profiles where id = p_user), 'UTC'))::date
$$;

-- The prayer-day that is "live" now: before today's Fajr it is still
-- yesterday (its Isha window runs until Fajr).
create or replace function public._current_prayer_date(p_user uuid)
returns date language sql stable security definer set search_path = public as $$
  select case when now() < (select w.window_start from prayer_windows_for(p_user, _local_date(p_user)) w
                            where w.prayer = 'fajr')
              then _local_date(p_user) - 1 else _local_date(p_user) end
$$;

-- -----------------------------------------------------------------------------
-- 4. Membership helpers (SECURITY DEFINER to avoid RLS recursion)
-- -----------------------------------------------------------------------------
create or replace function public.is_circle_member(p_circle uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from circle_members where circle_id = p_circle and user_id = p_user)
$$;

create or replace function public.shares_circle(p_other uuid, p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select p_other = p_user or exists (
    select 1 from circle_members a join circle_members b using (circle_id)
    where a.user_id = p_user and b.user_id = p_other)
$$;

-- -----------------------------------------------------------------------------
-- 5. Profiles: auto-create on sign-up, private location, rate-limited moves
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, display_name)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), split_part(coalesce(new.email, 'Friend'), '@', 1)))
  on conflict do nothing;
  insert into streaks (user_id) values (new.id) on conflict do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.get_my_profile()
returns public.profiles language sql stable security definer set search_path = public as $$
  select * from profiles where id = auth.uid()
$$;

-- Location drives the prayer windows, so moving it is the obvious cheat
-- ("set my city to one where Asr hasn't ended yet"). We therefore:
--   * rate-limit changes (cooldown),
--   * forbid changes while a prayer session is open.
-- Usual method for a region, from the phone's IANA time zone (works offline,
-- no reverse geocoding). Mirrored in lib/services/method_by_region.dart.
create or replace function public._method_for_timezone(p_tz text)
returns public.calc_method language sql immutable as $$
  select (case
    when p_tz in ('Asia/Kolkata','Asia/Calcutta','Asia/Karachi','Asia/Dhaka','Asia/Kathmandu',
                  'Asia/Colombo','Asia/Kabul','Indian/Maldives') then 'karachi'
    when p_tz in ('Asia/Dubai','Asia/Muscat')                      then 'dubai'
    when p_tz in ('Asia/Riyadh','Asia/Aden')                       then 'umm_al_qura'
    when p_tz in ('Asia/Qatar','Asia/Bahrain')                     then 'qatar'
    when p_tz = 'Asia/Kuwait'                                      then 'kuwait'
    when p_tz in ('Asia/Singapore','Asia/Kuala_Lumpur','Asia/Kuching','Asia/Brunei') then 'singapore'
    when p_tz in ('Asia/Jakarta','Asia/Pontianak','Asia/Makassar','Asia/Jayapura')   then 'indonesian'
    when p_tz = 'Europe/Istanbul'                                  then 'turkey'
    when p_tz in ('Africa/Casablanca','Africa/El_Aaiun')           then 'morocco'
    when p_tz = 'Asia/Amman'                                       then 'jordan'
    when p_tz in ('Africa/Cairo','Africa/Khartoum','Asia/Damascus','Asia/Beirut') then 'egyptian'
    when p_tz like 'America/%' or p_tz like 'US/%' or p_tz like 'Canada/%' then 'north_america'
    else 'muslim_world_league' end)::public.calc_method
$$;

create or replace function public.set_my_location(p_lat double precision, p_lng double precision,
  p_timezone text, p_method public.calc_method default null, p_madhab public.asr_madhab default null)
returns public.profiles language plpgsql security definer set search_path = public as $$
declare
  me profiles; cfg app_config; moved boolean;
begin
  perform public._require_approved();
  select * into cfg from app_config;
  select * into me from profiles where id = auth.uid() for update;
  if me.id is null then raise exception 'not_authenticated'; end if;
  if not exists (select 1 from pg_timezone_names where name = p_timezone) then
    raise exception 'invalid_timezone';
  end if;

  moved := me.latitude is null
        or abs(me.latitude - p_lat) > 0.05 or abs(me.longitude - p_lng) > 0.05  -- ~5 km
        or me.timezone <> p_timezone;

  if moved and me.location_updated_at is not null
     and me.location_updated_at > now() - make_interval(hours => cfg.location_cooldown_hours) then
    raise exception 'location_cooldown'
      using hint = format('Location can change once every %s hours', cfg.location_cooldown_hours);
  end if;
  if exists (select 1 from prayer_logs where user_id = me.id and status = 'in_progress') then
    raise exception 'session_open' using hint = 'Finish or cancel your current prayer first';
  end if;

  -- Method/madhab changes go through set_prayer_settings (rate-limited);
  -- here they are only accepted on the very first location.
  update profiles set
    latitude  = case when moved then p_lat else latitude end,
    longitude = case when moved then p_lng else longitude end,
    timezone  = p_timezone,
    calc_method = case
      when me.latitude is null and p_method is not null then p_method
      when me.method_auto and (moved or me.latitude is null) then _method_for_timezone(p_timezone)
      else calc_method end,
    method_auto = case when me.latitude is null and p_method is not null then false else method_auto end,
    asr_madhab  = case when me.latitude is null then coalesce(p_madhab, asr_madhab) else asr_madhab end,
    location_updated_at = case when moved then now() else location_updated_at end
  where id = me.id
  returning * into me;
  return me;
end $$;

-- Method, Asr madhab and mosque offsets. These move the windows too, so the
-- same anti-cheat rules apply as for location: never while a prayer is open,
-- and at most once every settings_cooldown_hours (the app shows a live
-- preview so people can try values before saving). The first save is free.
create or replace function public.set_prayer_settings(p_method_auto boolean, p_method public.calc_method,
  p_madhab public.asr_madhab, p_offsets int[])
returns public.profiles language plpgsql security definer set search_path = public as $$
declare me profiles; cfg app_config; m public.calc_method;
begin
  select * into cfg from app_config;
  select * into me from profiles where id = auth.uid() for update;
  if me.id is null then raise exception 'not_authenticated'; end if;
  if p_offsets is null or array_length(p_offsets, 1) <> 5
     or not (-10 <= all(p_offsets) and 10 >= all(p_offsets)) then
    raise exception 'invalid_offsets' using hint = 'Five values between -10 and +10 minutes';
  end if;
  m := case when p_method_auto then _method_for_timezone(me.timezone) else coalesce(p_method, me.calc_method) end;
  if m = me.calc_method and p_madhab = me.asr_madhab and p_offsets = me.minute_offsets
     and p_method_auto = me.method_auto then
    return me;  -- nothing changed
  end if;
  if exists (select 1 from prayer_logs where user_id = me.id and status = 'in_progress') then
    raise exception 'session_open' using hint = 'Finish or cancel your current prayer first';
  end if;
  if me.settings_updated_at is not null
     and me.settings_updated_at > now() - make_interval(hours => cfg.settings_cooldown_hours) then
    raise exception 'settings_cooldown'
      using hint = format('Prayer time settings can change once every %s hours', cfg.settings_cooldown_hours);
  end if;
  update profiles set calc_method = m, method_auto = p_method_auto, asr_madhab = p_madhab,
    minute_offsets = p_offsets, settings_updated_at = now()
  where id = me.id returning * into me;
  return me;
end $$;

-- Windows for the CURRENT user (client uses this to lock/unlock buttons so the
-- UI always agrees with the server, even if the local adhan calc drifts).
create or replace function public.get_my_prayer_windows(p_date date default null)
returns table (prayer public.prayer_name, window_start timestamptz, window_end timestamptz, server_now timestamptz)
language sql stable security definer set search_path = public as $$
  select w.*, now() from prayer_windows_for(auth.uid(), coalesce(p_date, _local_date(auth.uid()))) w
$$;

-- -----------------------------------------------------------------------------
-- 6. Streaks & badges (recomputed by the server only)
-- -----------------------------------------------------------------------------
create or replace function public._award(p_user uuid, p_code text, p_circle uuid default null)
returns void language sql security definer set search_path = public as $$
  insert into badges (user_id, code, circle_id) values (p_user, p_code, p_circle) on conflict do nothing
$$;

create or replace function public.recompute_streaks(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  today date := _local_date(p_user);
  d date; cur int := 0; fcur int := 0; full_today boolean; last_full date;
  milestone int;
begin
  -- 5/5 streak: walk back from today (today counts only once it's complete,
  -- an incomplete today does not break yesterday's streak).
  select count(*) = 5 into full_today from prayer_logs
   where user_id = p_user and prayer_date = today and status = 'on_time';
  d := case when full_today then today else today - 1 end;
  loop
    exit when (select count(*) from prayer_logs
               where user_id = p_user and prayer_date = d and status = 'on_time') < 5;
    if last_full is null then last_full := d; end if;
    cur := cur + 1; d := d - 1;
    exit when cur > 3650;
  end loop;

  -- Fajr-only streak
  d := case when exists (select 1 from prayer_logs where user_id = p_user and prayer_date = today
                         and prayer = 'fajr' and status = 'on_time') then today else today - 1 end;
  loop
    exit when not exists (select 1 from prayer_logs where user_id = p_user and prayer_date = d
                          and prayer = 'fajr' and status = 'on_time');
    fcur := fcur + 1; d := d - 1;
    exit when fcur > 3650;
  end loop;

  insert into streaks as s (user_id, current_days, best_days, fajr_current_days, fajr_best_days, last_full_date, updated_at)
  values (p_user, cur, cur, fcur, fcur, last_full, now())
  on conflict (user_id) do update set
    current_days = excluded.current_days,
    best_days = greatest(s.best_days, excluded.current_days),
    fajr_current_days = excluded.fajr_current_days,
    fajr_best_days = greatest(s.fajr_best_days, excluded.fajr_current_days),
    last_full_date = coalesce(excluded.last_full_date, s.last_full_date),
    updated_at = now();

  foreach milestone in array array[3, 7, 30, 40, 100, 365] loop
    if cur  >= milestone then perform _award(p_user, 'streak_' || milestone); end if;
    if fcur >= milestone then perform _award(p_user, 'fajr_'   || milestone); end if;
  end loop;
end $$;

-- "Full Circle Fajr": every member of the circle prayed Fajr on time that day.
create or replace function public.recompute_circle_fajr(p_circle uuid, p_date date)
returns void language plpgsql security definer set search_path = public as $$
declare
  all_done boolean; cs circle_streaks; milestone int; m record;
begin
  select bool_and(exists (select 1 from prayer_logs l where l.user_id = cm.user_id
                  and l.prayer_date = p_date and l.prayer = 'fajr' and l.status = 'on_time'))
    into all_done from circle_members cm where cm.circle_id = p_circle;
  if not coalesce(all_done, false) then return; end if;

  insert into circle_streaks (circle_id) values (p_circle) on conflict do nothing;
  select * into cs from circle_streaks where circle_id = p_circle for update;
  if cs.last_full_fajr_date = p_date then return; end if;

  update circle_streaks set
    full_fajr_current = case when last_full_fajr_date = p_date - 1 then full_fajr_current + 1 else 1 end,
    last_full_fajr_date = p_date, updated_at = now()
  where circle_id = p_circle returning * into cs;
  update circle_streaks set full_fajr_best = greatest(full_fajr_best, full_fajr_current) where circle_id = p_circle;

  foreach milestone in array array[7, 30, 40] loop
    if cs.full_fajr_current >= milestone then
      for m in select user_id from circle_members where circle_id = p_circle loop
        perform _award(m.user_id, 'circle_fajr_' || milestone, p_circle);
      end loop;
    end if;
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 7. ANTI-CHEAT CORE: start / complete / cancel / photo
-- -----------------------------------------------------------------------------

-- Start a prayer session. The server decides which prayer-day it belongs to
-- and whether it is eligible for On-Time.
--   p_prayer_date NULL  -> "Pray Now": must be inside the CURRENT window.
--   p_prayer_date given -> Qada for a PAST window only (never the future).
create or replace function public.start_prayer(p_prayer public.prayer_name, p_prayer_date date default null)
returns public.prayer_logs language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  cfg app_config; today date; target date; log prayer_logs;
  w_start timestamptz; w_end timestamptz;
begin
  perform public._require_approved();
  if uid is null then raise exception 'not_authenticated'; end if;
  select * into cfg from app_config;
  today := _local_date(uid);

  if p_prayer_date is null then
    -- Find the live window: today's, or (for Isha after midnight) yesterday's.
    target := today;
    select x.window_start, x.window_end into w_start, w_end
      from prayer_windows_for(uid, today) x where x.prayer = p_prayer;
    if not (now() >= w_start and now() < w_end) then
      target := today - 1;
      select x.window_start, x.window_end into w_start, w_end
        from prayer_windows_for(uid, today - 1) x where x.prayer = p_prayer;
      if not (now() >= w_start and now() < w_end) then
        raise exception 'outside_window'
          using hint = 'This prayer''s time has not started yet, or it has ended (log it as Qada).';
      end if;
    end if;
  else
    target := p_prayer_date;
    if target > today or target < today - cfg.qada_lookback_days then
      raise exception 'invalid_qada_date';
    end if;
    select x.window_start, x.window_end into w_start, w_end
      from prayer_windows_for(uid, target) x where x.prayer = p_prayer;
    if now() < w_end then
      -- Rule #1: no logging in advance, and a live window is not Qada.
      raise exception 'window_not_closed' using hint = 'Use Pray Now while the window is open.';
    end if;
  end if;

  -- Haid / nifas: this prayer is not owed (and has no qada).
  if _excused_kind(uid, w_start, w_end) is not null then
    raise exception 'excused_no_prayer'
      using hint = 'You are excused from this prayer. End your period in Profile when it is over.';
  end if;

  select * into log from prayer_logs
   where user_id = uid and prayer_date = target and prayer = p_prayer for update;

  if log.id is not null and log.status in ('on_time','qada','excused') then
    raise exception 'already_logged';
  end if;

  if log.id is null then
    insert into prayer_logs (user_id, prayer_date, prayer, status, window_start, window_end, started_at)
    values (uid, target, p_prayer, 'in_progress', w_start, w_end, now())
    returning * into log;
  else
    -- Restart (or a 'missed' row being made up as Qada). Timer restarts from now.
    update prayer_logs set status = 'in_progress', started_at = now(), completed_at = null,
           focus_seconds = null, focus_verified = false, updated_at = now(),
           window_start = w_start, window_end = w_end
     where id = log.id returning * into log;
  end if;
  return log;
end $$;

-- Complete a session. Duration is measured with the SERVER clock, so a modified
-- client cannot fast-forward the 5-minute timer.
create or replace function public.complete_prayer(p_log_id uuid)
returns public.prayer_logs language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid(); cfg app_config; log prayer_logs; secs int; c record;
begin
  perform public._require_approved();
  select * into cfg from app_config;
  select * into log from prayer_logs where id = p_log_id and user_id = uid for update;
  if log.id is null then raise exception 'not_found'; end if;
  if log.status <> 'in_progress' or log.started_at is null then raise exception 'not_in_progress'; end if;

  secs := extract(epoch from now() - log.started_at)::int;
  if secs < cfg.min_focus_seconds then
    raise exception 'focus_too_short'
      using hint = format('%s seconds remaining', cfg.min_focus_seconds - secs);
  end if;
  if secs > cfg.max_session_minutes * 60 then
    raise exception 'session_expired' using hint = 'Session was left open too long. Start again.';
  end if;

  update prayer_logs set
    completed_at   = now(),
    focus_seconds  = secs,
    focus_verified = true,
    -- On-Time only if the session STARTED inside the window. Anything else is Qada, forever.
    status = case when started_at >= window_start and started_at < window_end
                  then 'on_time'::prayer_status else 'qada'::prayer_status end,
    updated_at = now()
  where id = log.id returning * into log;

  perform recompute_streaks(uid);
  if log.prayer = 'fajr' and log.status = 'on_time' then
    for c in select circle_id from circle_members where user_id = uid loop
      perform recompute_circle_fajr(c.circle_id, log.prayer_date);
    end loop;
  end if;
  return log;
end $$;

create or replace function public.cancel_prayer(p_log_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  -- A cancelled live session simply disappears; a cancelled Qada attempt on a
  -- 'missed' row goes back to missed.
  delete from prayer_logs where id = p_log_id and user_id = auth.uid()
     and status = 'in_progress' and window_end > now();
  update prayer_logs set status = 'missed', started_at = null, updated_at = now()
   where id = p_log_id and user_id = auth.uid() and status = 'in_progress';
end $$;

-- Attach a photo proof that was uploaded to storage bucket `prayer-proofs`
-- at path '<uid>/<prayer_date>_<prayer>_<random>.jpg'.
create or replace function public.attach_photo_proof(p_log_id uuid, p_path text)
returns public.prayer_logs language plpgsql security definer set search_path = public, storage as $$
declare
  uid uuid := auth.uid(); cfg app_config; log prayer_logs; obj_created timestamptz;
begin
  perform public._require_approved();
  select * into cfg from app_config;
  select * into log from prayer_logs where id = p_log_id and user_id = uid for update;
  if log.id is null then raise exception 'not_found'; end if;
  if log.status not in ('on_time','qada') then raise exception 'prayer_not_completed'; end if;
  if log.photo_path is not null then raise exception 'photo_already_attached'; end if;
  if split_part(p_path, '/', 1) <> uid::text then raise exception 'invalid_path'; end if;

  select o.created_at into obj_created from storage.objects o
   where o.bucket_id = 'prayer-proofs' and o.name = p_path and o.owner_id = uid::text;
  if obj_created is null then raise exception 'photo_not_found'; end if;
  -- The photo must have been taken AFTER the session started and shortly after it ended
  -- (no re-using an old picture from the gallery).
  if obj_created < log.started_at
     or obj_created > log.completed_at + make_interval(mins => cfg.photo_deadline_minutes) then
    raise exception 'photo_out_of_time';
  end if;

  update prayer_logs set photo_path = p_path, photo_uploaded_at = obj_created, updated_at = now()
   where id = log.id returning * into log;
  return log;
end $$;

-- Mark windows that closed with no log as 'missed'. Schedule with pg_cron
-- (see bottom of file). Safe to run often.
create or replace function public.finalize_missed_prayers()
returns int language plpgsql security definer set search_path = public as $$
declare
  p record; w record; d date; n int := 0; touched boolean;
begin
  for p in select id, location_updated_at from profiles where latitude is not null loop
    touched := false;
    foreach d in array array[_local_date(p.id) - 1, _local_date(p.id)] loop
      for w in select * from prayer_windows_for(p.id, d) loop
        -- only windows that closed after the user set up their location
        if w.window_end < now() and w.window_start >= p.location_updated_at then
          insert into prayer_logs (user_id, prayer_date, prayer, status, window_start, window_end)
          values (p.id, d, w.prayer, 'missed', w.window_start, w.window_end)
          on conflict (user_id, prayer_date, prayer) do nothing;
          if found then n := n + 1; touched := true; end if;
        end if;
      end loop;
    end loop;
    -- Expire sessions left open way too long.
    delete from prayer_logs
     where user_id = p.id and status = 'in_progress' and window_end > now()
       and started_at < now() - make_interval(mins => (select max_session_minutes from app_config));
    update prayer_logs set status = 'missed', started_at = null, updated_at = now()
     where user_id = p.id and status = 'in_progress' and window_end <= now()
       and started_at < now() - make_interval(mins => (select max_session_minutes from app_config));
    if touched then perform recompute_streaks(p.id); end if;
  end loop;
  return n;
end $$;

-- -----------------------------------------------------------------------------
-- 8. Circles: create / join (6-digit code, throttled) / leave / regenerate
-- -----------------------------------------------------------------------------
create or replace function public._new_invite_code()
returns char(6) language plpgsql volatile set search_path = public as $$
declare code char(6);
begin
  loop
    code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from circles where invite_code = code);
  end loop;
  return code;
end $$;

create or replace function public.create_circle(p_name text, p_require_photo boolean default false)
returns public.circles language plpgsql security definer set search_path = public as $$
declare c circles;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  insert into circles (name, invite_code, require_photo, created_by)
  values (trim(p_name), _new_invite_code(), p_require_photo, auth.uid()) returning * into c;
  insert into circle_members (circle_id, user_id, role) values (c.id, auth.uid(), 'owner');
  insert into circle_streaks (circle_id) values (c.id);
  return c;
end $$;

-- join_circle(code) is defined in section 17 (invite-only access, join approval).

create or replace function public.leave_circle(p_circle uuid)
returns void language plpgsql security definer set search_path = public as $$
declare next_owner uuid;
begin
  delete from circle_members where circle_id = p_circle and user_id = auth.uid();
  if not exists (select 1 from circle_members where circle_id = p_circle) then
    delete from circles where id = p_circle;              -- last one out
  elsif not exists (select 1 from circle_members where circle_id = p_circle and role = 'owner') then
    select user_id into next_owner from circle_members where circle_id = p_circle order by joined_at limit 1;
    update circle_members set role = 'owner' where circle_id = p_circle and user_id = next_owner;
  end if;
end $$;

create or replace function public.update_circle(p_circle uuid, p_name text default null,
  p_require_photo boolean default null, p_regenerate_code boolean default false)
returns public.circles language plpgsql security definer set search_path = public as $$
declare c circles;
begin
  if not exists (select 1 from circle_members where circle_id = p_circle and user_id = auth.uid() and role = 'owner') then
    raise exception 'not_owner';
  end if;
  update circles set
    name = coalesce(trim(p_name), name),
    require_photo = coalesce(p_require_photo, require_photo),
    invite_code = case when p_regenerate_code then _new_invite_code() else invite_code end
  where id = p_circle returning * into c;
  return c;
end $$;

-- -----------------------------------------------------------------------------
-- 9. Live squad matrix + nudges
-- -----------------------------------------------------------------------------
-- One row per (member, prayer) for each member's own local "today".
-- display_status: on_time | qada | missed | in_progress | pending (window open) | upcoming
drop function if exists public.get_circle_matrix(uuid);
create or replace function public.get_circle_matrix(p_circle uuid)
returns table (user_id uuid, display_name text, avatar_url text, prayer public.prayer_name,
               prayer_date date, display_status text, focus_verified boolean, photo_path text,
               window_start timestamptz, window_end timestamptz, can_nudge boolean,
               already_nudged boolean, streak_days int,
               log_id uuid, reaction_count int, my_reaction text, member_timezone text)
language plpgsql stable security definer set search_path = public as $$
declare cfg app_config;
begin
  perform public._require_approved();
  if not is_circle_member(p_circle) then raise exception 'not_member'; end if;
  select * into cfg from app_config;
  return query
  with m as (
    select cm.user_id, pr.display_name, pr.avatar_url, pr.timezone,
           _current_prayer_date(cm.user_id) as d
      from circle_members cm join profiles pr on pr.id = cm.user_id
     where cm.circle_id = p_circle and pr.latitude is not null
  )
  select m.user_id, m.display_name, m.avatar_url, w.prayer, m.d,
         case
           when l.status is not null and l.status <> 'in_progress' then l.status::text
           when l.status = 'in_progress' then 'in_progress'
           when now() >= w.window_start and now() < w.window_end then 'pending'
           when now() >= w.window_end then 'missed'
           else 'upcoming'
         end,
         coalesce(l.focus_verified, false), l.photo_path, w.window_start, w.window_end,
         (m.user_id <> auth.uid() and l.status is null
           and now() >= w.window_start and now() < w.window_end
           and w.window_end - now() <= make_interval(mins => cfg.nudge_window_minutes)
           and n.id is null),
         n.id is not null,
         coalesce(s.current_days, 0),
         l.id,
         (select count(*)::int from reactions r where r.log_id = l.id),
         (select r.emoji from reactions r where r.log_id = l.id and r.user_id = auth.uid()),
         m.timezone
    from m
    cross join lateral prayer_windows_for(m.user_id, m.d) w
    left join prayer_logs l on l.user_id = m.user_id and l.prayer_date = m.d and l.prayer = w.prayer
    left join nudges n on n.sender_id = auth.uid() and n.receiver_id = m.user_id
                      and n.prayer_date = m.d and n.prayer = w.prayer
    left join streaks s on s.user_id = m.user_id
   order by m.display_name, w.window_start;
end $$;

create or replace function public.send_nudge(p_circle uuid, p_receiver uuid, p_prayer public.prayer_name)
returns public.nudges language plpgsql security definer set search_path = public as $$
declare cfg app_config; d date; w record; nd nudges;
begin
  perform public._require_approved();
  select * into cfg from app_config;
  if p_receiver = auth.uid() then raise exception 'cannot_nudge_self'; end if;
  if not (is_circle_member(p_circle) and is_circle_member(p_circle, p_receiver)) then
    raise exception 'not_member';
  end if;
  d := _current_prayer_date(p_receiver);
  select x.* into w from prayer_windows_for(p_receiver, d) x where x.prayer = p_prayer;
  if not (now() >= w.window_start and now() < w.window_end) then raise exception 'window_not_open'; end if;
  -- Private members (and anyone excused) can't be nudged; the error doesn't say why.
  if (select hide_status from profiles where id = p_receiver)
     or _excused_kind(p_receiver, w.window_start, least(w.window_end, now() + interval '1 minute')) is not null then
    raise exception 'not_available';
  end if;
  if w.window_end - now() > make_interval(mins => cfg.nudge_window_minutes) then
    raise exception 'too_early_to_nudge'
      using hint = format('Nudges unlock in the last %s minutes', cfg.nudge_window_minutes);
  end if;
  if exists (select 1 from prayer_logs where user_id = p_receiver and prayer_date = d and prayer = p_prayer) then
    raise exception 'already_praying_or_prayed';
  end if;
  insert into nudges (circle_id, sender_id, receiver_id, prayer, prayer_date)
  values (p_circle, auth.uid(), p_receiver, p_prayer, d) returning * into nd;
  return nd;
exception when unique_violation then
  raise exception 'already_nudged';
end $$;

create or replace function public.mark_nudges_seen()
returns void language sql security definer set search_path = public as $$
  update nudges set seen_at = now() where receiver_id = auth.uid() and seen_at is null
$$;

-- -----------------------------------------------------------------------------
-- 10. Row Level Security
-- -----------------------------------------------------------------------------
alter table public.app_config     enable row level security;
alter table public.profiles       enable row level security;
alter table public.circles        enable row level security;
alter table public.circle_members enable row level security;
alter table public.prayer_logs    enable row level security;
alter table public.streaks        enable row level security;
alter table public.circle_streaks enable row level security;
alter table public.badges         enable row level security;
alter table public.nudges         enable row level security;
alter table public.join_attempts  enable row level security;

drop policy if exists "config readable" on public.app_config;
create policy "config readable" on public.app_config for select to authenticated using (true);

drop policy if exists "profiles: self or circle peers" on public.profiles;
create policy "profiles: self or circle peers" on public.profiles for select to authenticated
  using (public.shares_circle(id));
drop policy if exists "profiles: update self" on public.profiles;
create policy "profiles: update self" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "circles: members read" on public.circles;
create policy "circles: members read" on public.circles for select to authenticated
  using (public.is_circle_member(id));

drop policy if exists "members: same circle read" on public.circle_members;
create policy "members: same circle read" on public.circle_members for select to authenticated
  using (public.is_circle_member(circle_id));

-- Read-only for clients. NO insert/update/delete policies => writes only via RPCs.
drop policy if exists "logs: self or circle peers" on public.prayer_logs;
create policy "logs: self or circle peers" on public.prayer_logs for select to authenticated
  using (public.shares_circle(user_id));

drop policy if exists "streaks: self or circle peers" on public.streaks;
create policy "streaks: self or circle peers" on public.streaks for select to authenticated
  using (public.shares_circle(user_id));

drop policy if exists "circle_streaks: members" on public.circle_streaks;
create policy "circle_streaks: members" on public.circle_streaks for select to authenticated
  using (public.is_circle_member(circle_id));

drop policy if exists "badges: self or circle peers" on public.badges;
create policy "badges: self or circle peers" on public.badges for select to authenticated
  using (public.shares_circle(user_id));

drop policy if exists "nudges: sender or receiver" on public.nudges;
create policy "nudges: sender or receiver" on public.nudges for select to authenticated
  using (sender_id = auth.uid() or receiver_id = auth.uid());

-- join_attempts: no policies at all (server-only).

-- Column privileges: peers may see names, never coordinates.
revoke all on public.profiles from anon, authenticated;
grant select (id, display_name, avatar_url, timezone, created_at) on public.profiles to authenticated;
-- (method/offset columns are read only through get_my_profile.)
grant update (display_name, avatar_url) on public.profiles to authenticated;

revoke insert, update, delete on public.prayer_logs, public.streaks, public.circle_streaks,
  public.badges, public.nudges, public.circles, public.circle_members, public.join_attempts,
  public.app_config from anon, authenticated;
revoke all on public.join_attempts from anon, authenticated;

-- Lock down function execution: only signed-in users, only the public API.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function
  public.get_my_profile(), public.set_my_location(double precision, double precision, text, public.calc_method, public.asr_madhab),
  public.set_prayer_settings(boolean, public.calc_method, public.asr_madhab, int[]),
  public.get_my_prayer_windows(date),
  public.start_prayer(public.prayer_name, date), public.complete_prayer(uuid), public.cancel_prayer(uuid),
  public.attach_photo_proof(uuid, text),
  public.create_circle(text, boolean), public.leave_circle(uuid),
  public.update_circle(uuid, text, boolean, boolean),
  public.get_circle_matrix(uuid), public.send_nudge(uuid, uuid, public.prayer_name), public.mark_nudges_seen(),
  public.is_circle_member(uuid, uuid), public.shares_circle(uuid, uuid),
  public.compute_prayer_times(double precision, double precision, date, public.calc_method, public.asr_madhab)
to authenticated;
-- Everything else (finalize_missed_prayers, recompute_*, prayer_windows_for, _helpers)
-- stays internal: callable only by the definer functions above and service_role.

-- -----------------------------------------------------------------------------
-- 11. Storage: immutable photo proofs
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('prayer-proofs', 'prayer-proofs', false, 2 * 1024 * 1024, array['image/jpeg'])
on conflict (id) do nothing;

drop policy if exists "proofs: upload own folder" on storage.objects;
create policy "proofs: upload own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'prayer-proofs' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "proofs: read self or circle peers" on storage.objects;
create policy "proofs: read self or circle peers" on storage.objects for select to authenticated
  using (bucket_id = 'prayer-proofs'
         and public.shares_circle(((storage.foldername(name))[1])::uuid));
-- No UPDATE / DELETE policies: a proof can never be swapped after the fact.

-- -----------------------------------------------------------------------------
-- 12. Realtime
-- -----------------------------------------------------------------------------
do $$ begin
  alter publication supabase_realtime add table public.prayer_logs;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.nudges;
exception when duplicate_object then null; when undefined_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.circle_members;
exception when duplicate_object then null; when undefined_object then null; end $$;

-- -----------------------------------------------------------------------------
-- 13. Scheduled job (enable "pg_cron" under Database > Extensions first)
-- -----------------------------------------------------------------------------
do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('niskaricho-finalize-missed', '*/10 * * * *',
                        'select public.finalize_missed_prayers()');
exception when others then
  raise notice 'pg_cron not available: schedule public.finalize_missed_prayers() yourself (%).', sqlerrm;
end $$;

-- =============================================================================
-- 14. Gamification: XP, levels, circle quests, leaderboard, reactions
-- =============================================================================
-- XP is NEVER stored or sent by the client. It is derived on demand from
-- prayer_logs, which only the anti-cheat RPCs can write. So the only way to
-- earn XP is to actually pass the window + 5-minute + photo checks.
--
--   On-Time            10 XP   (Fajr counts double: 20)
--   Focus verified     +5
--   Photo proof        +5
--   Qada (late)         4 XP   (making it up still matters)
--   Perfect day 5/5   +25
--
-- Level n starts at 50 * (n-1)^2 XP (1: 0, 2: 50, 3: 200, 4: 450, ...).

create table if not exists public.reactions (
  log_id      uuid not null references public.prayer_logs(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  emoji       text not null check (emoji in ('🤲','❤️','🔥','🌟')),
  created_at  timestamptz not null default now(),
  primary key (log_id, user_id)
);
alter table public.reactions enable row level security;
drop policy if exists "reactions: circle peers read" on public.reactions;
create policy "reactions: circle peers read" on public.reactions for select to authenticated
  using (public.shares_circle((select l.user_id from public.prayer_logs l where l.id = log_id)));
revoke insert, update, delete on public.reactions from anon, authenticated;
do $$ begin
  alter publication supabase_realtime add table public.reactions;
exception when duplicate_object then null; when undefined_object then null; end $$;

create or replace function public._xp_for_log(l public.prayer_logs)
returns int language sql immutable as $$
  select case l.status
           when 'on_time' then (case when l.prayer = 'fajr' then 20 else 10 end)
                               + (case when l.focus_verified then 5 else 0 end)
                               + (case when l.photo_path is not null then 5 else 0 end)
           when 'qada'    then 4 + (case when l.photo_path is not null then 2 else 0 end)
           else 0 end
$$;

-- XP for one user over a date range (inclusive), with perfect-day bonuses.
create or replace function public._xp_between(p_user uuid, p_from date, p_to date)
returns int language sql stable security definer set search_path = public as $$
  select coalesce(sum(_xp_for_log(l)), 0)::int
       + 25 * (select count(*)::int from (
           select prayer_date from prayer_logs
            where user_id = p_user and prayer_date between p_from and p_to and status = 'on_time'
            group by prayer_date having count(*) = 5) d)
    from prayer_logs l
   where l.user_id = p_user and l.prayer_date between p_from and p_to
$$;

create or replace function public._level_for(p_xp int)
returns int language sql immutable as $$ select floor(sqrt(greatest(p_xp, 0) / 50.0))::int + 1 $$;

-- Everything the Journey screen needs, in one call.
create or replace function public.get_my_progress()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  uid uuid := auth.uid(); today date; xp int; lvl int;
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  today := _local_date(uid);
  xp := _xp_between(uid, '2000-01-01', today);
  lvl := _level_for(xp);
  return jsonb_build_object(
    'xp', xp,
    'level', lvl,
    'level_start_xp', 50 * (lvl - 1) * (lvl - 1),
    'next_level_xp', 50 * lvl * lvl,
    'week_xp', _xp_between(uid, date_trunc('week', today)::date, today),
    'streak', (select to_jsonb(s) - 'user_id' from streaks s where s.user_id = uid),
    'badges', coalesce((select jsonb_agg(jsonb_build_object('code', b.code, 'awarded_at', b.awarded_at) order by b.awarded_at)
                        from badges b where b.user_id = uid), '[]'::jsonb),
    -- last 35 days: on-time / qada / missed counts per day (heatmap)
    'history', (select jsonb_agg(jsonb_build_object(
                   'date', d::date,
                   'on_time', (select count(*) from prayer_logs where user_id = uid and prayer_date = d and status = 'on_time'),
                   'qada',    (select count(*) from prayer_logs where user_id = uid and prayer_date = d and status = 'qada'),
                   'missed',  (select count(*) from prayer_logs where user_id = uid and prayer_date = d and status = 'missed'))
                 order by d)
                from generate_series(today - 34, today, interval '1 day') d),
    -- on-time rate per prayer over the last 30 days
    'per_prayer', (select jsonb_object_agg(p, coalesce(r, 0)) from (
                     select p::text, (select round(100.0 * count(*) filter (where status = 'on_time') / nullif(count(*), 0))
                                        from prayer_logs where user_id = uid and prayer = p
                                         and prayer_date > today - 30 and status <> 'in_progress') r
                       from unnest(enum_range(null::prayer_name)) p) x)
  );
end $$;

-- Weekly XP leaderboard for a circle (resets every Monday, like a league).
create or replace function public.get_circle_leaderboard(p_circle uuid)
returns table (user_id uuid, display_name text, week_xp int, level int, streak_days int)
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_circle_member(p_circle) then raise exception 'not_member'; end if;
  return query
  select cm.user_id, pr.display_name,
         _xp_between(cm.user_id, date_trunc('week', _local_date(cm.user_id))::date, _local_date(cm.user_id)),
         _level_for(_xp_between(cm.user_id, '2000-01-01', _local_date(cm.user_id))),
         coalesce(s.current_days, 0)
    from circle_members cm
    join profiles pr on pr.id = cm.user_id
    left join streaks s on s.user_id = cm.user_id
   where cm.circle_id = p_circle
   order by 3 desc, 2;
end $$;

-- Co-op "Circle Quest": together, pray 80% of this week's prayers on time.
create or replace function public.get_circle_quest(p_circle uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare n int; week_start date; done int;
begin
  if not is_circle_member(p_circle) then raise exception 'not_member'; end if;
  week_start := date_trunc('week', _local_date(auth.uid()))::date;
  select count(*) into n from circle_members where circle_id = p_circle;
  select count(*) into done from prayer_logs l join circle_members cm on cm.user_id = l.user_id
   where cm.circle_id = p_circle and l.status = 'on_time' and l.prayer_date >= week_start;
  return jsonb_build_object(
    'title', 'Circle Quest: 80% on time this week',
    'goal', ceil(n * 35 * 0.8)::int,
    'progress', done,
    'week_start', week_start,
    'ends_at', (week_start + 7)::timestamptz);
end $$;

-- Encourage a friend's completed prayer (one reaction per person per prayer).
create or replace function public.react_to_log(p_log_id uuid, p_emoji text)
returns void language plpgsql security definer set search_path = public as $$
declare owner uuid; st prayer_status;
begin
  perform public._require_approved();
  select user_id, status into owner, st from prayer_logs where id = p_log_id;
  if owner is null or not shares_circle(owner) then raise exception 'not_found'; end if;
  if owner = auth.uid() then raise exception 'cannot_react_self'; end if;
  if st not in ('on_time', 'qada') then raise exception 'not_completed'; end if;
  insert into reactions (log_id, user_id, emoji) values (p_log_id, auth.uid(), p_emoji)
  on conflict (log_id, user_id) do update set emoji = excluded.emoji, created_at = now();
end $$;

revoke execute on function public._xp_for_log(public.prayer_logs), public._xp_between(uuid, date, date),
  public._level_for(int) from public, anon, authenticated;
grant execute on function public.get_my_progress(), public.get_circle_leaderboard(uuid),
  public.get_circle_quest(uuid), public.react_to_log(uuid, text), public.get_circle_matrix(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 15. Delete my account (required by Google Play and the App Store)
-- -----------------------------------------------------------------------------
-- Removes the user and everything tied to them (logs, streaks, nudges,
-- reactions, memberships). Circles they created are handed to the
-- longest-standing other member, or deleted if nobody else is in them.
-- Photo files in the prayer-proofs bucket are insert-only for anti-cheat;
-- they are removed by the storage cleanup job (see README, "Photo retention").
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); c record; heir uuid;
begin
  if uid is null then raise exception 'not_authenticated'; end if;
  for c in select id from circles where created_by = uid loop
    select user_id into heir from circle_members
      where circle_id = c.id and user_id <> uid order by joined_at limit 1;
    if heir is null then
      delete from circles where id = c.id;
    else
      update circles set created_by = heir where id = c.id;
      update circle_members set role = 'owner' where circle_id = c.id and user_id = heir;
    end if;
  end loop;
  delete from auth.users where id = uid;  -- cascades to profiles and all user rows
end $$;
revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;


-- -----------------------------------------------------------------------------
-- 16. Profile and women's exemptions (haid / nifas)
-- -----------------------------------------------------------------------------
-- Fiqh used (Shafi'i first; Hanafi where it differs):
--   * During haid and nifas salah is not owed and there is NO qada.
--   * Haid lasts at most 15 days (Hanafi 10); after that it is istihada and she prays.
--   * Purity between two periods is at least 15 days; bleeding sooner is istihada.
--   * Nifas lasts at most 60 days (Hanafi 40).
--   * A prayer is still owed if its time had come in and there was time to pray it
--     before bleeding started (we allow 5 minutes), and if bleeding stops before its
--     time ends. Shafi'i: stopping in Asr/Isha time also makes Dhuhr/Maghrib due.
-- The reason is private: the circle only ever sees "not shared".
alter table public.profiles add column if not exists gender text check (gender in ('male','female'));
alter table public.profiles add column if not exists birth_year int check (birth_year between 1900 and 2100);
alter table public.profiles add column if not exists home_mosque text check (char_length(home_mosque) <= 60);
alter table public.profiles add column if not exists language text not null default 'ml' check (language in ('ml','en'));
alter table public.profiles add column if not exists hide_status boolean not null default false;
alter table public.profiles add column if not exists onboarded boolean not null default false;

create table if not exists public.excused_periods (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  kind        text not null check (kind in ('haid','nifas')),
  started_at  timestamptz not null default now(),
  ended_at    timestamptz,
  created_at  timestamptz not null default now()
);
create index if not exists excused_periods_user on public.excused_periods (user_id, started_at desc);
alter table public.excused_periods enable row level security;
drop policy if exists excused_own on public.excused_periods;
create policy excused_own on public.excused_periods for select using (user_id = auth.uid());
revoke all on public.excused_periods from anon, authenticated;
grant select on public.excused_periods to authenticated;  -- own rows only (RLS); writes via RPCs

-- Longest a period can count, by kind and madhab.
create or replace function public._excused_max(p_kind text, p_madhab public.asr_madhab)
returns interval language sql immutable as $$
  select case
    when p_kind = 'haid'  and p_madhab = 'hanafi' then interval '10 days'
    when p_kind = 'haid'  then interval '15 days'
    when p_kind = 'nifas' and p_madhab = 'hanafi' then interval '40 days'
    else interval '60 days' end
$$;

-- The kind of exemption covering a prayer window, or null if the prayer is owed.
create or replace function public._excused_kind(p_user uuid, p_start timestamptz, p_end timestamptz)
returns text language sql stable security definer set search_path = public as $$
  select e.kind from excused_periods e join profiles pr on pr.id = e.user_id
   where e.user_id = p_user
     and e.started_at <= p_start + interval '5 minutes'
     and least(coalesce(e.ended_at, 'infinity'::timestamptz),
               e.started_at + _excused_max(e.kind, pr.asr_madhab)) >= p_end - interval '1 minute'
   order by e.started_at desc limit 1
$$;

create or replace function public.update_my_profile(p_display_name text, p_gender text, p_birth_year int,
  p_home_mosque text, p_language text, p_hide_status boolean)
returns public.profiles language plpgsql security definer set search_path = public as $$
declare me profiles;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_gender = 'male' and exists (select 1 from excused_periods where user_id = auth.uid() and ended_at is null) then
    raise exception 'period_open';
  end if;
  update profiles set
    display_name = coalesce(nullif(trim(p_display_name), ''), display_name),
    gender = p_gender, birth_year = p_birth_year,
    home_mosque = nullif(trim(p_home_mosque), ''),
    language = coalesce(p_language, language),
    hide_status = coalesce(p_hide_status, hide_status),
    onboarded = true
  where id = auth.uid() returning * into me;
  return me;
end $$;

create or replace function public.start_excused(p_kind text)
returns public.excused_periods language plpgsql security definer set search_path = public as $$
declare me profiles; last excused_periods; e excused_periods;
begin
  perform public._require_approved();
  select * into me from profiles where id = auth.uid();
  if me.id is null then raise exception 'not_authenticated'; end if;
  if me.gender is distinct from 'female' then raise exception 'not_applicable'; end if;
  if p_kind not in ('haid','nifas') then raise exception 'invalid_kind'; end if;
  if exists (select 1 from excused_periods where user_id = me.id and ended_at is null
             and started_at + _excused_max(kind, me.asr_madhab) > now()) then
    raise exception 'period_open';
  end if;
  if exists (select 1 from prayer_logs where user_id = me.id and status = 'in_progress') then
    raise exception 'session_open' using hint = 'Finish or cancel your current prayer first';
  end if;
  -- Close any period that ran past its maximum.
  update excused_periods set ended_at = started_at + _excused_max(kind, me.asr_madhab)
   where user_id = me.id and ended_at is null;
  -- At least 15 days of purity between two haid periods (not needed after nifas).
  select * into last from excused_periods where user_id = me.id order by started_at desc limit 1;
  if p_kind = 'haid' and last.id is not null and last.kind = 'haid'
     and last.ended_at > now() - interval '15 days' then
    raise exception 'purity_gap'
      using hint = 'Less than 15 days since your last period ended: this counts as istihada, so salah is still due (wudu for each prayer).';
  end if;
  insert into excused_periods (user_id, kind) values (me.id, p_kind) returning * into e;
  -- Clear the open "pending" state of the current window if it is now excused.
  return e;
end $$;

-- Ends the period now. Prayers whose time is still running become due again.
create or replace function public.end_excused()
returns public.excused_periods language plpgsql security definer set search_path = public as $$
declare me profiles; e excused_periods;
begin
  select * into me from profiles where id = auth.uid();
  select * into e from excused_periods where user_id = me.id and ended_at is null
   order by started_at desc limit 1 for update;
  if e.id is null then raise exception 'no_open_period'; end if;
  update excused_periods
     set ended_at = least(now(), started_at + _excused_max(kind, me.asr_madhab))
   where id = e.id returning * into e;
  -- Shafi'i: purity in Asr or Isha time also makes Dhuhr or Maghrib due, so
  -- those are no longer marked excused (they can be logged now).
  if me.asr_madhab = 'shafi' then
    delete from prayer_logs l
     using prayer_windows_for(me.id, _current_prayer_date(me.id)) w
     where l.user_id = me.id and l.status = 'excused' and l.prayer_date = _current_prayer_date(me.id)
       and ((l.prayer = 'dhuhr'   and w.prayer = 'asr'  and now() between w.window_start and w.window_end)
         or (l.prayer = 'maghrib' and w.prayer = 'isha' and now() between w.window_start and w.window_end));
  end if;
  perform recompute_streaks(me.id);
  return e;
end $$;

-- finalize_missed_prayers: an excused window is stored as 'excused', never 'missed'.
create or replace function public.finalize_missed_prayers()
returns int language plpgsql security definer set search_path = public as $$
declare
  p record; w record; d date; n int := 0; touched boolean;
begin
  for p in select id, location_updated_at from profiles where latitude is not null loop
    touched := false;
    foreach d in array array[_local_date(p.id) - 1, _local_date(p.id)] loop
      for w in select * from prayer_windows_for(p.id, d) loop
        if w.window_end < now() and w.window_start >= p.location_updated_at then
          insert into prayer_logs (user_id, prayer_date, prayer, status, window_start, window_end)
          values (p.id, d, w.prayer,
                  case when _excused_kind(p.id, w.window_start, w.window_end) is not null
                       then 'excused'::prayer_status else 'missed'::prayer_status end,
                  w.window_start, w.window_end)
          on conflict (user_id, prayer_date, prayer) do nothing;
          if found then n := n + 1; touched := true; end if;
        end if;
      end loop;
    end loop;
    delete from prayer_logs
     where user_id = p.id and status = 'in_progress' and window_end > now()
       and started_at < now() - make_interval(mins => (select max_session_minutes from app_config));
    update prayer_logs set status = 'missed', started_at = null, updated_at = now()
     where user_id = p.id and status = 'in_progress' and window_end <= now()
       and started_at < now() - make_interval(mins => (select max_session_minutes from app_config));
    if touched then perform recompute_streaks(p.id); end if;
  end loop;
  return n;
end $$;

-- Streaks: an excused prayer neither breaks nor extends a streak. A day counts
-- if all its owed prayers were on time; a fully excused day is skipped.
create or replace function public.recompute_streaks(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  today date := _local_date(p_user);
  d date; cur int := 0; fcur int := 0; last_full date; milestone int;
  ontime int; exc int; f text; guard int := 0;
begin
  select count(*) filter (where status = 'on_time'), count(*) filter (where status = 'excused')
    into ontime, exc from prayer_logs where user_id = p_user and prayer_date = today;
  d := case when ontime + exc = 5 then today else today - 1 end;
  loop
    guard := guard + 1; exit when guard > 3650;
    select count(*) filter (where status = 'on_time'), count(*) filter (where status = 'excused')
      into ontime, exc from prayer_logs where user_id = p_user and prayer_date = d;
    exit when ontime + exc < 5;
    if ontime > 0 then
      if last_full is null then last_full := d; end if;
      cur := cur + 1;
    end if;
    d := d - 1;
  end loop;

  guard := 0;
  select status::text into f from prayer_logs where user_id = p_user and prayer_date = today and prayer = 'fajr';
  d := case when f in ('on_time','excused') then today else today - 1 end;
  loop
    guard := guard + 1; exit when guard > 3650;
    select status::text into f from prayer_logs where user_id = p_user and prayer_date = d and prayer = 'fajr';
    exit when f is null or f not in ('on_time','excused');
    if f = 'on_time' then fcur := fcur + 1; end if;
    d := d - 1;
  end loop;

  insert into streaks as s (user_id, current_days, best_days, fajr_current_days, fajr_best_days, last_full_date, updated_at)
  values (p_user, cur, cur, fcur, fcur, last_full, now())
  on conflict (user_id) do update set
    current_days = excluded.current_days,
    best_days = greatest(s.best_days, excluded.current_days),
    fajr_current_days = excluded.fajr_current_days,
    fajr_best_days = greatest(s.fajr_best_days, excluded.fajr_current_days),
    last_full_date = coalesce(excluded.last_full_date, s.last_full_date),
    updated_at = now();

  foreach milestone in array array[3, 7, 30, 40, 100, 365] loop
    if cur  >= milestone then perform _award(p_user, 'streak_' || milestone); end if;
    if fcur >= milestone then perform _award(p_user, 'fajr_'   || milestone); end if;
  end loop;
end $$;

-- Matrix: peers see 'private' for excused prayers and for members who hide
-- their status. Nobody can tell a period from a privacy choice.
drop function if exists public.get_circle_matrix(uuid);
create or replace function public.get_circle_matrix(p_circle uuid)
returns table (user_id uuid, display_name text, avatar_url text, prayer public.prayer_name,
               prayer_date date, display_status text, focus_verified boolean, photo_path text,
               window_start timestamptz, window_end timestamptz, can_nudge boolean,
               already_nudged boolean, streak_days int,
               log_id uuid, reaction_count int, my_reaction text, member_timezone text)
language plpgsql stable security definer set search_path = public as $$
declare cfg app_config;
begin
  perform public._require_approved();
  if not is_circle_member(p_circle) then raise exception 'not_member'; end if;
  select * into cfg from app_config;
  return query
  with m as (
    select cm.user_id, pr.display_name, pr.avatar_url, pr.timezone, pr.hide_status,
           _current_prayer_date(cm.user_id) as d
      from circle_members cm join profiles pr on pr.id = cm.user_id
     where cm.circle_id = p_circle and pr.latitude is not null
  ),
  x as (
    select m.*, w.prayer, w.window_start, w.window_end, l.id as lid, l.status as lstatus,
           l.focus_verified as lfv, l.photo_path as lphoto,
           (l.status = 'excused' or (l.status is null and now() >= w.window_start
             and _excused_kind(m.user_id, w.window_start, least(w.window_end, now() + interval '1 minute')) is not null)) as exc
      from m cross join lateral prayer_windows_for(m.user_id, m.d) w
      left join prayer_logs l on l.user_id = m.user_id and l.prayer_date = m.d and l.prayer = w.prayer
  )
  select x.user_id, x.display_name, x.avatar_url, x.prayer, x.d,
         case
           when x.user_id <> auth.uid() and (x.hide_status or x.exc) then 'private'
           when x.exc then 'excused'
           when x.lstatus is not null and x.lstatus <> 'in_progress' then x.lstatus::text
           when x.lstatus = 'in_progress' then 'in_progress'
           when now() >= x.window_start and now() < x.window_end then 'pending'
           when now() >= x.window_end then 'missed'
           else 'upcoming'
         end,
         case when x.user_id <> auth.uid() and (x.hide_status or x.exc) then false else coalesce(x.lfv, false) end,
         case when x.user_id <> auth.uid() and (x.hide_status or x.exc) then null else x.lphoto end,
         x.window_start, x.window_end,
         (x.user_id <> auth.uid() and x.lstatus is null and not x.hide_status and not x.exc
           and now() >= x.window_start and now() < x.window_end
           and x.window_end - now() <= make_interval(mins => cfg.nudge_window_minutes)
           and n.id is null),
         n.id is not null,
         coalesce(s.current_days, 0),
         case when x.user_id <> auth.uid() and (x.hide_status or x.exc) then null else x.lid end,
         (select count(*)::int from reactions r where r.log_id = x.lid),
         (select r.emoji from reactions r where r.log_id = x.lid and r.user_id = auth.uid()),
         x.timezone
    from x
    left join nudges n on n.sender_id = auth.uid() and n.receiver_id = x.user_id
                      and n.prayer_date = x.d and n.prayer = x.prayer
    left join streaks s on s.user_id = x.user_id
   order by x.display_name, x.window_start;
end $$;

revoke execute on function public._excused_kind(uuid, timestamptz, timestamptz), public._excused_max(text, public.asr_madhab)
  from public, anon, authenticated;
grant execute on function public.update_my_profile(text, text, int, text, text, boolean),
  public.start_excused(text), public.end_excused(), public.get_circle_matrix(uuid) to authenticated;


-- -----------------------------------------------------------------------------
-- 17. Invite-only access (early phase) and circle join approval
-- -----------------------------------------------------------------------------
-- * Every new account starts as 'pending' and can do nothing except set up its
--   profile, until an admin approves it or it redeems an invite code.
-- * The very first account becomes the super admin automatically. To make an
--   existing account admin instead, run once in the SQL editor:
--     update public.profiles set is_admin = true, access_status = 'approved'
--      where id = (select id from auth.users where email = '<your email>');
-- * Invite codes: 8 characters, limited uses, expiry, revocable, admin only.
-- * Circles: owners approve join requests and can remove members.
-- Accounts that existed before this section are approved (default 'approved'
-- on the add, then switched to 'pending' for new rows).
alter table public.profiles add column if not exists access_status text not null default 'approved'
  check (access_status in ('pending','approved','rejected','removed'));
alter table public.profiles alter column access_status set default 'pending';
alter table public.profiles add column if not exists is_admin boolean not null default false;
alter table public.profiles add column if not exists access_changed_at timestamptz;
alter table public.profiles add column if not exists invited_with text;

-- App language: English, Malayalam or Arabic.
alter table public.profiles drop constraint if exists profiles_language_check;
alter table public.profiles add constraint profiles_language_check check (language in ('ml','en','ar'));

create table if not exists public.invite_codes (
  code        text primary key check (code ~ '^[A-Z2-9]{8}$'),
  created_by  uuid references public.profiles(id) on delete set null,
  note        text check (char_length(note) <= 60),
  max_uses    int  not null default 1 check (max_uses between 1 and 100),
  used        int  not null default 0,
  expires_at  timestamptz not null,
  revoked_at  timestamptz,
  created_at  timestamptz not null default now()
);
create table if not exists public.invite_redemptions (
  code        text not null references public.invite_codes(code) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  primary key (code, user_id)
);
create table if not exists public.circle_join_requests (
  circle_id    uuid not null references public.circles(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  requested_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);
alter table public.circles add column if not exists approve_joins boolean not null default true;

alter table public.invite_codes enable row level security;
alter table public.invite_redemptions enable row level security;
alter table public.circle_join_requests enable row level security;
-- No policies: read and written only through the functions below.
revoke all on public.invite_codes, public.invite_redemptions, public.circle_join_requests from anon, authenticated;

create or replace function public._is_admin(p_user uuid default auth.uid())
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select is_admin and access_status = 'approved' from profiles where id = p_user), false)
$$;

create or replace function public._require_approved()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if not exists (select 1 from profiles where id = auth.uid() and access_status = 'approved') then
    raise exception 'not_approved';
  end if;
end $$;

create or replace function public._require_admin()
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not public._is_admin() then raise exception 'not_admin'; end if;
end $$;

-- Sign-up: the first account is the super admin; an invite code given at
-- sign-up (user metadata "invite_code") approves the account straight away.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare first boolean := not exists (select 1 from profiles where is_admin);
begin
  insert into profiles (id, display_name, is_admin, access_status)
  values (new.id,
          coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), split_part(coalesce(new.email, 'Friend'), '@', 1)),
          first, case when first then 'approved' else 'pending' end)
  on conflict do nothing;
  insert into streaks (user_id) values (new.id) on conflict do nothing;
  if not first and nullif(new.raw_user_meta_data->>'invite_code', '') is not null then
    perform public._redeem(new.id, new.raw_user_meta_data->>'invite_code');  -- a bad code just leaves it pending
  end if;
  return new;
end $$;

-- Returns 'approved' or the reason it failed. It never raises: a raised error
-- would roll back the failed-attempt row, and the brute-force throttle with it.
create or replace function public._redeem(p_user uuid, p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare ic invite_codes; c text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
begin
  select * into ic from invite_codes where code = c for update;
  if ic.code is null or ic.revoked_at is not null then return 'invalid_invite'; end if;
  if ic.expires_at < now() then return 'invite_expired'; end if;
  if ic.used >= ic.max_uses then return 'invite_used_up'; end if;
  if exists (select 1 from invite_redemptions where code = ic.code and user_id = p_user) then return 'approved'; end if;
  insert into invite_redemptions (code, user_id) values (ic.code, p_user);
  update invite_codes set used = used + 1 where code = ic.code;
  update profiles set access_status = 'approved', access_changed_at = now(), invited_with = ic.code
   where id = p_user and access_status = 'pending';
  return 'approved';
end $$;

-- Pending users redeem a code from the waiting screen (throttled like circle codes).
create or replace function public.redeem_invite(p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare fails int; st text; r text;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  select access_status into st from profiles where id = auth.uid();
  if st = 'approved' then return st; end if;
  if st in ('rejected', 'removed') then raise exception 'access_denied'; end if;
  select count(*) into fails from join_attempts
   where user_id = auth.uid() and not success and created_at > now() - interval '1 hour';
  if fails >= (select join_attempts_per_hour from app_config) then raise exception 'too_many_attempts'; end if;
  r := public._redeem(auth.uid(), p_code);
  insert into join_attempts (user_id, success) values (auth.uid(), r = 'approved');
  return r;
end $$;

-- ---- Admin screen -----------------------------------------------------------
create or replace function public.admin_list_users()
returns table (id uuid, display_name text, email text, access_status text, is_admin boolean,
               invited_with text, created_at timestamptz, access_changed_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public._require_admin();
  return query
    select p.id, p.display_name, u.email::text, p.access_status, p.is_admin, p.invited_with, p.created_at,
           p.access_changed_at
      from profiles p join auth.users u on u.id = p.id
     order by (p.access_status = 'pending') desc, p.created_at desc;
end $$;

-- approve / reject / remove. Removing takes the person out of every circle
-- (circles they own pass to the longest-standing member). Admins cannot be
-- changed here, so nobody can lock the super admin out.
create or replace function public.admin_set_access(p_user uuid, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare c record; heir uuid;
begin
  perform public._require_admin();
  if p_status not in ('approved','rejected','removed') then raise exception 'invalid_status'; end if;
  if p_user = auth.uid() or public._is_admin(p_user) then raise exception 'cannot_change_admin'; end if;
  update profiles set access_status = p_status, access_changed_at = now() where id = p_user;
  if p_status <> 'approved' then
    for c in select circle_id from circle_members where user_id = p_user and role = 'owner' loop
      select user_id into heir from circle_members
       where circle_id = c.circle_id and user_id <> p_user order by joined_at limit 1;
      if heir is null then delete from circles where id = c.circle_id;
      else
        update circles set created_by = heir where id = c.circle_id;
        update circle_members set role = 'owner' where circle_id = c.circle_id and user_id = heir;
      end if;
    end loop;
    delete from circle_members where user_id = p_user;
    delete from circle_join_requests where user_id = p_user;
  end if;
end $$;

create or replace function public.admin_set_admin(p_user uuid, p_admin boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._require_admin();
  if p_user = auth.uid() and not p_admin then raise exception 'cannot_change_admin'; end if;
  update profiles set is_admin = p_admin,
         access_status = case when p_admin then 'approved' else access_status end
   where id = p_user;
end $$;

create or replace function public.admin_create_invite(p_max_uses int default 1, p_valid_days int default 7,
  p_note text default null)
returns public.invite_codes language plpgsql security definer set search_path = public as $$
declare ic invite_codes; c text; alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
begin
  perform public._require_admin();
  if p_valid_days not between 1 and 90 then raise exception 'invalid_days'; end if;
  loop
    c := '';
    for i in 1..8 loop c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1); end loop;
    exit when not exists (select 1 from invite_codes where code = c);
  end loop;
  insert into invite_codes (code, created_by, note, max_uses, expires_at)
  values (c, auth.uid(), nullif(trim(p_note), ''), p_max_uses, now() + make_interval(days => p_valid_days))
  returning * into ic;
  return ic;
end $$;

create or replace function public.admin_list_invites()
returns setof public.invite_codes language plpgsql stable security definer set search_path = public as $$
begin
  perform public._require_admin();
  return query select * from invite_codes order by created_at desc limit 200;
end $$;

create or replace function public.admin_revoke_invite(p_code text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._require_admin();
  update invite_codes set revoked_at = now() where code = p_code and revoked_at is null;
end $$;

-- ---- Circles: approval before joining, owners remove members ----------------
create or replace function public.create_circle(p_name text, p_require_photo boolean default false)
returns public.circles language plpgsql security definer set search_path = public as $$
declare c circles;
begin
  perform public._require_approved();
  insert into circles (name, invite_code, require_photo, created_by)
  values (trim(p_name), _new_invite_code(), p_require_photo, auth.uid()) returning * into c;
  insert into circle_members (circle_id, user_id, role) values (c.id, auth.uid(), 'owner');
  insert into circle_streaks (circle_id) values (c.id);
  return c;
end $$;

-- Returns {"status": "joined" | "requested" | "invalid_code", "circle": {...}}.
-- With join approval on (the default) the caller goes on the owner's request
-- list. Failures are returned, not raised, so the attempt counter is kept.
drop function if exists public.join_circle(text);
create or replace function public.join_circle(p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare c circles; fails int; cfg app_config;
begin
  perform public._require_approved();
  select * into cfg from app_config;
  select count(*) into fails from join_attempts
   where user_id = auth.uid() and not success and created_at > now() - interval '1 hour';
  if fails >= cfg.join_attempts_per_hour then raise exception 'too_many_attempts'; end if;

  select * into c from circles where invite_code = trim(p_code);
  insert into join_attempts (user_id, success) values (auth.uid(), c.id is not null);
  if c.id is null then return jsonb_build_object('status', 'invalid_code'); end if;
  if public.is_circle_member(c.id) then return jsonb_build_object('status', 'joined', 'circle', to_jsonb(c)); end if;

  if c.approve_joins then
    insert into circle_join_requests (circle_id, user_id) values (c.id, auth.uid()) on conflict do nothing;
    return jsonb_build_object('status', 'requested', 'circle', jsonb_build_object('id', c.id, 'name', c.name));
  end if;
  insert into circle_members (circle_id, user_id) values (c.id, auth.uid()) on conflict do nothing;
  return jsonb_build_object('status', 'joined', 'circle', to_jsonb(c));
end $$;

-- Circles you asked to join that the owner has not answered yet.
create or replace function public.my_join_requests()
returns table (circle_id uuid, name text, requested_at timestamptz)
language sql stable security definer set search_path = public as $$
  select r.circle_id, c.name, r.requested_at from circle_join_requests r join circles c on c.id = r.circle_id
   where r.user_id = auth.uid() order by r.requested_at
$$;

create or replace function public._require_circle_owner(p_circle uuid)
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if not exists (select 1 from circle_members where circle_id = p_circle and user_id = auth.uid() and role = 'owner')
     and not public._is_admin() then
    raise exception 'not_owner';
  end if;
end $$;

create or replace function public.get_circle_join_requests(p_circle uuid)
returns table (user_id uuid, display_name text, requested_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public._require_circle_owner(p_circle);
  return query select r.user_id, p.display_name, r.requested_at
    from circle_join_requests r join profiles p on p.id = r.user_id
   where r.circle_id = p_circle order by r.requested_at;
end $$;

create or replace function public.answer_join_request(p_circle uuid, p_user uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._require_circle_owner(p_circle);
  delete from circle_join_requests where circle_id = p_circle and user_id = p_user;
  if not found then raise exception 'no_request'; end if;
  if p_accept and exists (select 1 from profiles where id = p_user and access_status = 'approved') then
    insert into circle_members (circle_id, user_id) values (p_circle, p_user) on conflict do nothing;
  end if;
end $$;

create or replace function public.remove_circle_member(p_circle uuid, p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._require_circle_owner(p_circle);
  if p_user = auth.uid() then raise exception 'use_leave'; end if;
  if exists (select 1 from circle_members where circle_id = p_circle and user_id = p_user and role = 'owner') then
    raise exception 'cannot_remove_owner';
  end if;
  delete from circle_members where circle_id = p_circle and user_id = p_user;
end $$;

create or replace function public.set_circle_approve_joins(p_circle uuid, p_on boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public._require_circle_owner(p_circle);
  update circles set approve_joins = p_on where id = p_circle;
end $$;

revoke execute on function public._redeem(uuid, text), public._require_admin(), public._require_approved(),
  public._require_circle_owner(uuid) from public, anon, authenticated;
grant execute on function public._is_admin(uuid), public.redeem_invite(text), public.admin_list_users(),
  public.admin_set_access(uuid, text), public.admin_set_admin(uuid, boolean),
  public.admin_create_invite(int, int, text), public.admin_list_invites(), public.admin_revoke_invite(text),
  public.create_circle(text, boolean), public.join_circle(text), public.get_circle_join_requests(uuid),
  public.answer_join_request(uuid, uuid, boolean), public.remove_circle_member(uuid, uuid),
  public.set_circle_approve_joins(uuid, boolean), public.my_join_requests() to authenticated;
