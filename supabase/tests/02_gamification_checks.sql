set role authenticated;
set request.jwt.claim.sub='11111111-1111-1111-1111-111111111111';
select jsonb_pretty(get_my_progress() - 'history') ;
select jsonb_array_length(get_my_progress()->'history') as history_days;
select * from get_circle_leaderboard((select id from circles limit 1));
select get_circle_quest((select id from circles limit 1));
select react_to_log((select id from prayer_logs where prayer='asr' and prayer_date=current_date), '🤲'); -- self -> error
set request.jwt.claim.sub='22222222-2222-2222-2222-222222222222';
select react_to_log((select id from prayer_logs where prayer='asr' and prayer_date=current_date and user_id='11111111-1111-1111-1111-111111111111'), '🤲');
select react_to_log((select id from prayer_logs where prayer='asr' and prayer_date=current_date and user_id='11111111-1111-1111-1111-111111111111'), '😈'); -- bad emoji
insert into reactions values ((select id from prayer_logs limit 1), auth.uid(), '🔥'); -- denied
set request.jwt.claim.sub='11111111-1111-1111-1111-111111111111';
select display_name, prayer, reaction_count, my_reaction from get_circle_matrix((select id from circles limit 1)) where prayer='asr';
