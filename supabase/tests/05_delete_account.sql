-- Account deletion keeps shared circles alive for the other members.
\set ON_ERROR_STOP 0
insert into auth.users(id,email) values ('55555555-5555-5555-5555-555555555555','e@x.com'),('66666666-6666-6666-6666-666666666666','f@x.com');
-- v5: tests below predate invite-only access; approve everyone and let circles join without approval.
update public.profiles set access_status = 'approved'; alter table public.circles alter column approve_joins set default false;
set role authenticated;
set request.jwt.claim.sub='55555555-5555-5555-5555-555555555555';
select set_my_location(9.93,76.27,'Asia/Kolkata') is not null;
select invite_code from create_circle('Family test', false) \gset
select id from create_circle('Solo circle', false);
set request.jwt.claim.sub='66666666-6666-6666-6666-666666666666';
select join_circle(:'invite_code')->>'status' as joined;
set request.jwt.claim.sub='55555555-5555-5555-5555-555555555555';
select delete_my_account();
reset role;
select count(*) as profile_left from profiles where id='55555555-5555-5555-5555-555555555555';   -- 0
select name, created_by = '66666666-6666-6666-6666-666666666666' as handed_over from circles where name in ('Family test','Solo circle'); -- Family test only, t
