-- Invite-only access: first account is super admin, others wait; invite codes; circle join approval.
\set ON_ERROR_STOP 0
alter table public.circles alter column approve_joins set default true;
insert into auth.users(id,email) values ('a0000000-0000-0000-0000-000000000001','admin@x.com');
insert into auth.users(id,email) values ('a0000000-0000-0000-0000-000000000002','new@x.com');
insert into auth.users(id,email,raw_user_meta_data) values ('a0000000-0000-0000-0000-000000000003','bad@x.com','{"invite_code":"ZZZZZZZZ"}');
select display_name, is_admin, access_status from profiles order by id;   -- admin approved, others pending
set role authenticated;
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000002';
select create_circle('Sneaky', false);                                  -- expect not_approved
select start_prayer('fajr');                                            -- expect not_approved
select admin_list_users();                                              -- expect not_admin
select redeem_invite('WRONG123');                                       -- invalid_invite
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000001';
select code, max_uses from admin_create_invite(1, 7, 'For Umma') \gset
select :'code' ~ '^[A-Z2-9]{8}$' as code_ok;
select admin_set_access('a0000000-0000-0000-0000-000000000001', 'removed');   -- expect cannot_change_admin
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000002';
select redeem_invite(lower(:'code'));                                   -- approved (case-insensitive)
select set_my_location(11.2588,75.7804,'Asia/Kolkata') is not null as can_use_app;
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000003';
select redeem_invite(:'code');                                          -- invite_used_up
-- Admin approves #3 by hand, then a circle with join approval.
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000001';
select admin_set_access('a0000000-0000-0000-0000-000000000003', 'approved');
select invite_code, id as circle from create_circle('Family', false) \gset
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000002';
select join_circle(:'invite_code')->>'status';                         -- requested
select count(*) as matrix_rows_before from get_circle_matrix(:'circle');  -- 0, not a member yet
select get_circle_join_requests(:'circle');                             -- expect not_owner
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000001';
select display_name from get_circle_join_requests(:'circle');           -- new
select answer_join_request(:'circle', 'a0000000-0000-0000-0000-000000000002', true);
select count(*) as members from circle_members where circle_id = :'circle';   -- 2
select remove_circle_member(:'circle', 'a0000000-0000-0000-0000-000000000002');
select count(*) as members_after_remove from circle_members where circle_id = :'circle';  -- 1
-- Removing an account takes it out of every circle and blocks it.
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000003';
select set_circle_approve_joins(:'circle', false);                      -- expect not_owner
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000001';
select set_circle_approve_joins(:'circle', false);
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000003';
select join_circle(:'invite_code')->>'status' as joined;                           -- joins directly now
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000001';
select admin_set_access('a0000000-0000-0000-0000-000000000003', 'removed');
select count(*) as members_after_ban from circle_members where circle_id = :'circle';  -- 1
select admin_revoke_invite(:'code');
select revoked_at is not null as revoked from admin_list_invites() where code = :'code';
set request.jwt.claim.sub='a0000000-0000-0000-0000-000000000003';
select redeem_invite('ABCDEFGH');                                       -- expect access_denied
select start_prayer('fajr');                                            -- expect not_approved
