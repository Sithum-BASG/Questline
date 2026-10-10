-- T026: owner, friend, stranger and party-member reads for every table.
BEGIN;
SELECT plan(108);

INSERT INTO auth.users (id, aud, role, email)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'owner@questline.test'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'friend@questline.test'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'authenticated', 'authenticated', 'stranger@questline.test'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'authenticated', 'authenticated', 'party@questline.test');

INSERT INTO catalog_items (id, type, name, source) VALUES
  ('skin_starter', 'skin', 'Starter', 'starter'),
  ('bg_starter', 'background', 'Starter', 'starter'),
  ('frame_apprentice', 'frame', 'Apprentice', 'starter');
INSERT INTO level_rewards (level, rewards) VALUES (2, '[{"type":"item","id":"frame_margin_notes"}]');
INSERT INTO game_config (key, value) VALUES ('chest_cost', '500');

INSERT INTO profiles (id, username, friend_code, display_name, body_type)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner_1', 'OWNER001', 'Owner', 'a'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'friend_1', 'FRIEND01', 'Friend', 'b'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'stranger1', 'STRAN001', 'Stranger', 'a'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'party_1', 'PARTY001', 'Party', 'b');

INSERT INTO player_state (user_id, week_id, next_rollover_at)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-W41', now());
INSERT INTO user_settings (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

INSERT INTO bosses (user_id, name, title, type, tier, hours, max_hp, deadline, coins_eligible)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Shade', 'Midterm', 'exam', 'minion', 3, 180, now() + interval '7 days', true);

INSERT INTO tasks (user_id, title) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Read chapter');
INSERT INTO sessions (user_id, task_id, mode)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', id, 'focus' FROM tasks LIMIT 1;
INSERT INTO inventory (user_id, catalog_id, source)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'skin_starter', 'starter');
INSERT INTO achievements (user_id, badge_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'skin_starter');
INSERT INTO daily_stats (user_id, day) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-10-10');

INSERT INTO friendships (user_id, friend_id, status) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'accepted'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'accepted');
INSERT INTO friend_summaries (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
INSERT INTO weekly_scores (week_id, user_id) VALUES ('2026-W41', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

INSERT INTO guilds (id, name, emblem, leader_id, invite_code)
VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Study', 'book', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'GUILD001');
INSERT INTO guild_members (guild_id, user_id) VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

INSERT INTO raids (
  id, source, name, title, type, tier, per_person_minutes, participants, max_hp, deadline, created_by, coins_eligible
) VALUES (
  'ffffffff-ffff-ffff-ffff-ffffffffffff', 'party', 'Shade', 'Revision', 'project', 'minion',
  120, 2, 240, now() + interval '7 days', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true
);
INSERT INTO guild_trophies (guild_id, raid_id, name)
VALUES ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'ffffffff-ffff-ffff-ffff-ffffffffffff', 'Revision');
INSERT INTO raid_members (raid_id, user_id, display_name) VALUES
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Owner'),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Party');
INSERT INTO raid_damage (raid_id, user_id, damage) VALUES
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 10),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 4);
INSERT INTO raid_events (raid_id, user_id, display_name, amount)
VALUES ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Owner', 10);

INSERT INTO activity_events (actor_id, type, payload, visible_to)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'level_up', '{"level":2}',
  ARRAY['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']::uuid[]
);
INSERT INTO inbox (user_id, type, payload)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'system', '{}');
INSERT INTO presence (user_id, raid_id)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ffffffff-ffff-ffff-ffff-ffffffffffff');
INSERT INTO demo_allowlist (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
INSERT INTO processed_requests (user_id, request_id, result)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'req-1', '{}');

CREATE FUNCTION pg_temp.count_as(tbl regclass, uid uuid) RETURNS int
LANGUAGE plpgsql AS $$
DECLARE
  n int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', uid::text, true);
  EXECUTE 'set local role authenticated';
  EXECUTE format('select count(*)::int from %s', tbl) INTO n;
  EXECUTE 'reset role';
  RETURN n;
END;
$$;

SELECT is(pg_temp.count_as('catalog_items', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 3, 'owner catalog');
SELECT is(pg_temp.count_as('catalog_items', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 3, 'friend catalog');
SELECT is(pg_temp.count_as('catalog_items', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 3, 'stranger catalog');
SELECT is(pg_temp.count_as('catalog_items', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 3, 'party catalog');

SELECT is(pg_temp.count_as('level_rewards', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner level rewards');
SELECT is(pg_temp.count_as('level_rewards', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend level rewards');
SELECT is(pg_temp.count_as('level_rewards', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 1, 'stranger level rewards');
SELECT is(pg_temp.count_as('level_rewards', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party level rewards');

SELECT is(pg_temp.count_as('game_config', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner game config');
SELECT is(pg_temp.count_as('game_config', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend game config');
SELECT is(pg_temp.count_as('game_config', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 1, 'stranger game config');
SELECT is(pg_temp.count_as('game_config', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party game config');

SELECT is(pg_temp.count_as('profiles', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 4, 'owner profiles');
SELECT is(pg_temp.count_as('profiles', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 4, 'friend profiles');
SELECT is(pg_temp.count_as('profiles', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 4, 'stranger profiles');
SELECT is(pg_temp.count_as('profiles', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 4, 'party profiles');

SELECT is(pg_temp.count_as('player_state', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner player_state');
SELECT is(pg_temp.count_as('player_state', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend player_state');
SELECT is(pg_temp.count_as('player_state', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger player_state');
SELECT is(pg_temp.count_as('player_state', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party player_state');

SELECT is(pg_temp.count_as('user_settings', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner settings');
SELECT is(pg_temp.count_as('user_settings', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend settings');
SELECT is(pg_temp.count_as('user_settings', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger settings');
SELECT is(pg_temp.count_as('user_settings', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party settings');

SELECT is(pg_temp.count_as('bosses', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner bosses');
SELECT is(pg_temp.count_as('bosses', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend bosses');
SELECT is(pg_temp.count_as('bosses', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger bosses');
SELECT is(pg_temp.count_as('bosses', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party bosses');

SELECT is(pg_temp.count_as('tasks', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner tasks');
SELECT is(pg_temp.count_as('tasks', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend tasks');
SELECT is(pg_temp.count_as('tasks', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger tasks');
SELECT is(pg_temp.count_as('tasks', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party tasks');

SELECT is(pg_temp.count_as('sessions', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner sessions');
SELECT is(pg_temp.count_as('sessions', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend sessions');
SELECT is(pg_temp.count_as('sessions', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger sessions');
SELECT is(pg_temp.count_as('sessions', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party sessions');

SELECT is(pg_temp.count_as('inventory', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner inventory');
SELECT is(pg_temp.count_as('inventory', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend inventory');
SELECT is(pg_temp.count_as('inventory', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger inventory');
SELECT is(pg_temp.count_as('inventory', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party inventory');

SELECT is(pg_temp.count_as('achievements', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner achievements');
SELECT is(pg_temp.count_as('achievements', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend achievements');
SELECT is(pg_temp.count_as('achievements', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger achievements');
SELECT is(pg_temp.count_as('achievements', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party achievements');

SELECT is(pg_temp.count_as('daily_stats', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner daily stats');
SELECT is(pg_temp.count_as('daily_stats', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend daily stats');
SELECT is(pg_temp.count_as('daily_stats', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger daily stats');
SELECT is(pg_temp.count_as('daily_stats', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party daily stats');

SELECT is(pg_temp.count_as('friendships', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner friendships');
SELECT is(pg_temp.count_as('friendships', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend friendships');
SELECT is(pg_temp.count_as('friendships', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger friendships');
SELECT is(pg_temp.count_as('friendships', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party friendships');

SELECT is(pg_temp.count_as('friend_summaries', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner summaries');
SELECT is(pg_temp.count_as('friend_summaries', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend summaries');
SELECT is(pg_temp.count_as('friend_summaries', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger summaries');
SELECT is(pg_temp.count_as('friend_summaries', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party summaries');

SELECT is(pg_temp.count_as('weekly_scores', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner weekly scores');
SELECT is(pg_temp.count_as('weekly_scores', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend weekly scores');
SELECT is(pg_temp.count_as('weekly_scores', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger weekly scores');
SELECT is(pg_temp.count_as('weekly_scores', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party weekly scores');

SELECT is(pg_temp.count_as('guilds', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner guilds');
SELECT is(pg_temp.count_as('guilds', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend guilds');
SELECT is(pg_temp.count_as('guilds', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger guilds');
SELECT is(pg_temp.count_as('guilds', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party guilds');

SELECT is(pg_temp.count_as('guild_members', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 2, 'owner guild members');
SELECT is(pg_temp.count_as('guild_members', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 2, 'friend guild members');
SELECT is(pg_temp.count_as('guild_members', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger guild members');
SELECT is(pg_temp.count_as('guild_members', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party guild members');

SELECT is(pg_temp.count_as('guild_trophies', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner trophies');
SELECT is(pg_temp.count_as('guild_trophies', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend trophies');
SELECT is(pg_temp.count_as('guild_trophies', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger trophies');
SELECT is(pg_temp.count_as('guild_trophies', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party trophies');

SELECT is(pg_temp.count_as('activity_events', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 0, 'owner feed hides own event');
SELECT is(pg_temp.count_as('activity_events', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend feed');
SELECT is(pg_temp.count_as('activity_events', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger feed');
SELECT is(pg_temp.count_as('activity_events', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party feed');

SELECT is(pg_temp.count_as('inbox', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner inbox');
SELECT is(pg_temp.count_as('inbox', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend inbox');
SELECT is(pg_temp.count_as('inbox', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger inbox');
SELECT is(pg_temp.count_as('inbox', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 0, 'party inbox');

SELECT is(pg_temp.count_as('presence', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner presence');
SELECT is(pg_temp.count_as('presence', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 1, 'friend presence');
SELECT is(pg_temp.count_as('presence', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger presence');
SELECT is(pg_temp.count_as('presence', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party presence');

SELECT is(pg_temp.count_as('raids', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner raids');
SELECT is(pg_temp.count_as('raids', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend raids');
SELECT is(pg_temp.count_as('raids', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger raids');
SELECT is(pg_temp.count_as('raids', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party raids');

SELECT is(pg_temp.count_as('raid_members', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 2, 'owner raid members');
SELECT is(pg_temp.count_as('raid_members', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend raid members');
SELECT is(pg_temp.count_as('raid_members', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger raid members');
SELECT is(pg_temp.count_as('raid_members', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 2, 'party raid members');

SELECT is(pg_temp.count_as('raid_damage', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 2, 'owner sees both damage rows');
SELECT is(pg_temp.count_as('raid_damage', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend raid damage');
SELECT is(pg_temp.count_as('raid_damage', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger raid damage');
SELECT is(pg_temp.count_as('raid_damage', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party sees own damage');

SELECT is(pg_temp.count_as('raid_events', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'), 1, 'owner raid events');
SELECT is(pg_temp.count_as('raid_events', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'), 0, 'friend raid events');
SELECT is(pg_temp.count_as('raid_events', 'cccccccc-cccc-cccc-cccc-cccccccccccc'), 0, 'stranger raid events');
SELECT is(pg_temp.count_as('raid_events', 'dddddddd-dddd-dddd-dddd-dddddddddddd'), 1, 'party raid events');

SELECT throws_ok(
  $$ SELECT pg_temp.count_as('demo_allowlist', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '42501', NULL, 'owner cannot read demo_allowlist'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('demo_allowlist', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') $$,
  '42501', NULL, 'friend cannot read demo_allowlist'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('demo_allowlist', 'cccccccc-cccc-cccc-cccc-cccccccccccc') $$,
  '42501', NULL, 'stranger cannot read demo_allowlist'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('demo_allowlist', 'dddddddd-dddd-dddd-dddd-dddddddddddd') $$,
  '42501', NULL, 'party cannot read demo_allowlist'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('processed_requests', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '42501', NULL, 'owner cannot read processed_requests'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('processed_requests', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') $$,
  '42501', NULL, 'friend cannot read processed_requests'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('processed_requests', 'cccccccc-cccc-cccc-cccc-cccccccccccc') $$,
  '42501', NULL, 'stranger cannot read processed_requests'
);
SELECT throws_ok(
  $$ SELECT pg_temp.count_as('processed_requests', 'dddddddd-dddd-dddd-dddd-dddddddddddd') $$,
  '42501', NULL, 'party cannot read processed_requests'
);

SELECT * FROM finish();
ROLLBACK;
