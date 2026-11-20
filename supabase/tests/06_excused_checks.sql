-- Haid / nifas: excused prayers, privacy in the circle, Shafi'i limits.
\set ON_ERROR_STOP 0
insert into auth.users(id,email) values ('77777777-7777-7777-7777-777777777777','fa@x.com'),('88888888-8888-8888-8888-888888888888','am@x.com');
-- v5: tests below predate invite-only access; approve everyone and let circles join without approval.
update public.profiles set access_status = 'approved'; alter table public.circles alter column approve_joins set default false;
set role authenticated;
set request.jwt.claim.sub='77777777-7777-7777-7777-777777777777';
select onboarded, gender from update_my_profile('Fathima','female',1998,'Kallai Juma Masjid','ml',false);
select set_my_location(11.2588,75.7804,'Asia/Kolkata') is not null;
select invite_code from create_circle('Family', false) \gset
set request.jwt.claim.sub='88888888-8888-8888-8888-888888888888';
select update_my_profile('Ameen','male',1995,null,'en',false) is not null;
select set_my_location(25.2048,55.2708,'Asia/Dubai') is not null;
select join_circle(:'invite_code')->>'status' as joined;
select start_excused('haid');                                   -- expect not_applicable (male)
set request.jwt.claim.sub='77777777-7777-7777-7777-777777777777';
select kind from start_excused('haid');
select kind from start_excused('haid');                         -- expect period_open
reset role;
-- Pretend the period began 2 days ago and the location 3 days ago; four earlier days were all on time.
update excused_periods set started_at = now() - interval '2 days' where user_id = '77777777-7777-7777-7777-777777777777';
update profiles set location_updated_at = now() - interval '3 days' where id = '77777777-7777-7777-7777-777777777777';
insert into prayer_logs (user_id, prayer_date, prayer, status, window_start, window_end, started_at, completed_at)
select '77777777-7777-7777-7777-777777777777', _local_date('77777777-7777-7777-7777-777777777777') - k, p, 'on_time', now(), now(), now(), now()
  from generate_series(2,5) k, unnest(enum_range(null::prayer_name)) p;
select finalize_missed_prayers() > 0 as finalized;
select status, count(*) from prayer_logs where user_id = '77777777-7777-7777-7777-777777777777'
  and prayer_date >= _local_date('77777777-7777-7777-7777-777777777777') - 1 group by 1;   -- only 'excused'
select current_days as streak_kept from streaks where user_id = '77777777-7777-7777-7777-777777777777';  -- 4: the excused day is skipped, not a break
set role authenticated;
set request.jwt.claim.sub='88888888-8888-8888-8888-888888888888';
select distinct display_status as peer_sees from get_circle_matrix((select id from circles where name='Family'))
  where user_id = '77777777-7777-7777-7777-777777777777';           -- private only
select send_nudge((select id from circles where name='Family'), '77777777-7777-7777-7777-777777777777', 'isha');  -- not_available / window rule
set request.jwt.claim.sub='77777777-7777-7777-7777-777777777777';
select distinct display_status as i_see from get_circle_matrix((select id from circles where name='Family'))
  where user_id = '77777777-7777-7777-7777-777777777777';           -- excused (and upcoming)
select status from start_prayer('isha');                        -- excused_no_prayer if Isha is live
select ended_at is not null as ended from end_excused();
select start_excused('haid');                                   -- expect purity_gap
select kind from start_excused('nifas');                        -- nifas after haid is allowed
select ended_at is not null from end_excused();
reset role;
-- Max length: a haid left open 20 days counts only 15.
update excused_periods set started_at = now() - interval '40 days', ended_at = null
 where id = (select id from excused_periods where user_id = '77777777-7777-7777-7777-777777777777' and kind = 'haid');
select _excused_kind('77777777-7777-7777-7777-777777777777', now() - interval '30 days', now() - interval '29 days') as day10,
       _excused_kind('77777777-7777-7777-7777-777777777777', now() - interval '20 days', now() - interval '19 days') as day20;  -- haid, null
