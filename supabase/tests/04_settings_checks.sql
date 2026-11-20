-- v3: automatic method by region, mosque offsets, settings anti-cheat.
\set ON_ERROR_STOP 0
insert into auth.users(id,email) values ('44444444-4444-4444-4444-444444444444','d@x.com');
-- v5: tests below predate invite-only access; approve everyone and let circles join without approval.
update public.profiles set access_status = 'approved'; alter table public.circles alter column approve_joins set default false;
set role authenticated;
set request.jwt.claim.sub='44444444-4444-4444-4444-444444444444';
-- First location in Dubai: method picked automatically from the time zone.
select calc_method, method_auto from set_my_location(25.2048,55.2708,'Asia/Dubai');   -- expect dubai, t
select prayer, to_char(window_start at time zone 'Asia/Dubai','HH24:MI') s from get_my_prayer_windows('2026-11-20') order by 1;
-- Mosque offsets: Fajr +2, Isha +5. Asr -11 is rejected.
select set_prayer_settings(true, null, 'shafi', '{0,0,-11,0,0}');                     -- expect invalid_offsets
select calc_method, minute_offsets from set_prayer_settings(true, null, 'shafi', '{2,0,0,0,5}');  -- first save is free
select prayer, to_char(window_start at time zone 'Asia/Dubai','HH24:MI') s, to_char(window_end at time zone 'Asia/Dubai','HH24:MI') e
  from get_my_prayer_windows('2026-11-20') order by 1;                                -- fajr 05:21, maghrib ends 18:55
-- A second change soon after is rate-limited (e.g. switching to Hanafi to stretch Dhuhr).
select set_prayer_settings(true, null, 'hanafi', '{2,0,0,0,5}');                      -- expect settings_cooldown
select calc_method from set_prayer_settings(true, null, 'shafi', '{2,0,0,0,5}');      -- unchanged: ok
-- set_my_location can no longer change method/madhab after the first time.
select calc_method, asr_madhab from set_my_location(25.2048,55.2708,'Asia/Dubai','karachi','hanafi');  -- still dubai, shafi
-- Travel: after the location cooldown, moving to Riyadh switches the method automatically.
reset role; update profiles set location_updated_at = now() - interval '7 hours' where id='44444444-4444-4444-4444-444444444444'; set role authenticated;
select calc_method from set_my_location(24.7136,46.6753,'Asia/Riyadh');               -- expect umm_al_qura
reset role;
