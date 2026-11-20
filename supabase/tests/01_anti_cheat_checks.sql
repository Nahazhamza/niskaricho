\set ON_ERROR_STOP 0
insert into auth.users(id,email) values ('11111111-1111-1111-1111-111111111111','a@x.com'),('22222222-2222-2222-2222-222222222222','b@x.com'),('33333333-3333-3333-3333-333333333333','c@x.com');
-- v5: tests below predate invite-only access; approve everyone and let circles join without approval.
update public.profiles set access_status = 'approved'; alter table public.circles alter column approve_joins set default false;
-- find a longitude near lat 11 where Asr window closes in ~10 min (for nudge test)
create temp table L as select lng from generate_series(0,179.9,0.1) lng
 where (select maghrib from compute_prayer_times(11,lng::float8, (now() at time zone 'UTC')::date)) between now()+interval '8 min' and now()+interval '15 min' limit 1;
select * from L;
grant select on L to authenticated;
set role authenticated;
set request.jwt.claim.sub='11111111-1111-1111-1111-111111111111';
select display_name, latitude from get_my_profile();
select id from set_my_location(11.2588,75.7804,'Asia/Kolkata');
select set_my_location(12.0,75.7804,'Asia/Kolkata');  -- expect cooldown
select prayer, window_start, window_end from get_my_prayer_windows();
select start_prayer('fajr');     -- expect outside_window
select start_prayer('asr', current_date+1); -- invalid_qada_date
select status, prayer_date from start_prayer('asr');
select complete_prayer((select id from prayer_logs where prayer='asr'));  -- focus_too_short
insert into prayer_logs(user_id,prayer_date,prayer,status,window_start,window_end) values (auth.uid(),current_date,'asr','on_time',now(),now()); -- RLS deny
update prayer_logs set started_at = now() - interval '6 min';  -- no privilege
select invite_code from create_circle('Hostel Room 4', true) \gset
set request.jwt.claim.sub='22222222-2222-2222-2222-222222222222';
select join_circle('000000')->>'status';
select join_circle(:'invite_code')->>'status' as joined;
select set_my_location(11, (select lng from L), 'Asia/Kolkata') is not null;
select count(*) as visible_logs_before from prayer_logs;
select latitude from profiles;  -- expect permission denied
select display_name from profiles order by 1;
set request.jwt.claim.sub='33333333-3333-3333-3333-333333333333';
select count(*) as outsider_sees from prayer_logs;
select get_circle_matrix((select id from circles limit 1)); -- outsider: not visible -> null id -> not_member
reset role;
update prayer_logs set started_at = now() - interval '6 min';
set role authenticated;
set request.jwt.claim.sub='11111111-1111-1111-1111-111111111111';
select status, focus_seconds, focus_verified from complete_prayer((select id from prayer_logs where prayer='asr'));
select status from start_prayer('asr'); -- already_logged
select current_days, fajr_current_days from streaks where user_id=auth.uid();
-- qada for yesterday's dhuhr
select status, prayer_date from start_prayer('dhuhr', current_date-1);
reset role; update prayer_logs set started_at = now() - interval '5 min 1 sec' where prayer='dhuhr'; set role authenticated;
select status from complete_prayer((select id from prayer_logs where prayer='dhuhr'));
-- photo proof
reset role; insert into storage.objects(bucket_id,name,owner_id) values ('prayer-proofs','11111111-1111-1111-1111-111111111111/a.jpg','11111111-1111-1111-1111-111111111111'); set role authenticated;
select photo_path is not null as has_photo from attach_photo_proof((select id from prayer_logs where prayer='asr' and prayer_date=current_date),'11111111-1111-1111-1111-111111111111/a.jpg');
-- matrix + nudge user 2 (window closing soon)
select display_name, prayer, display_status, can_nudge, focus_verified, photo_path is not null ph from get_circle_matrix((select id from circles limit 1));
select receiver_id from send_nudge((select id from circles limit 1),'22222222-2222-2222-2222-222222222222','asr');
select send_nudge((select id from circles limit 1),'22222222-2222-2222-2222-222222222222','asr'); -- already_nudged
select finalize_missed_prayers(); -- not allowed
reset role;
select finalize_missed_prayers();
select u.email, prayer_date, prayer, status from prayer_logs l join auth.users u on u.id=l.user_id order by 1,2,3;
