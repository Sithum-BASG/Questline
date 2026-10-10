-- T027: forbidden client writes, draft to open, and equip only what you own.
BEGIN;
SELECT plan(20);

INSERT INTO auth.users (id, aud, role, email)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'owner@questline.test');

INSERT INTO catalog_items (id, type, name, source) VALUES
  ('skin_starter', 'skin', 'Starter', 'starter'),
  ('bg_starter', 'background', 'Starter', 'starter'),
  ('frame_apprentice', 'frame', 'Apprentice', 'starter'),
  ('skin_coder', 'skin', 'Coder', 'level'),
  ('badge_deep_worker', 'badge', 'Deep Worker', 'level'),
  ('title_adept', 'title', 'Adept', 'level'),
  ('title_archmage', 'title', 'Archmage', 'level');

INSERT INTO profiles (id, username, friend_code, display_name, body_type)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner_1', 'OWNER001', 'Owner', 'a');
INSERT INTO player_state (user_id, week_id, next_rollover_at, owned_titles)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-W41', now(), ARRAY['title_adept']);
INSERT INTO user_settings (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
INSERT INTO inventory (user_id, catalog_id, source)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'skin_starter', 'starter');
INSERT INTO achievements (user_id, badge_id, tier)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'badge_deep_worker', 0);

INSERT INTO tasks (id, user_id, title, status, difficulty, stat) VALUES
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Judged draft', 'draft', 4, 'intellect'),
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Unjudged draft', 'draft', NULL, NULL);

INSERT INTO inbox (id, user_id, type, payload)
VALUES ('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'system', '{}');
INSERT INTO presence (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
INSERT INTO demo_allowlist (user_id) VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

DO $$ BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);
END $$;
SET ROLE authenticated;

SELECT throws_ok('update profiles set level = 2', '42501', NULL, 'level is server-owned');
SELECT throws_ok('update profiles set username = ''other''', '42501', NULL, 'username is server-owned');
SELECT throws_ok('update user_settings set demo_mode = true', '42501', NULL, 'demo_mode is server-owned');
SELECT throws_ok('update tasks set title = ''renamed''', '42501', NULL, 'title is frozen after insert');
SELECT throws_ok('update tasks set xp_final = 10', '42501', NULL, 'xp is server-owned');
SELECT throws_ok('update player_state set coins = 100', '42501', NULL, 'player_state is server-owned');
SELECT throws_ok('insert into sessions (user_id, task_id, mode) values (''aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'', ''11111111-1111-1111-1111-111111111111'', ''focus'')', '42501', NULL, 'sessions are server-owned');
SELECT throws_ok('update inbox set payload = ''{"x":1}'' where id = ''33333333-3333-3333-3333-333333333333''', '42501', NULL, 'inbox payload is server-owned');
SELECT throws_ok('update presence set user_id = gen_random_uuid()', '42501', NULL, 'presence identity is server-owned');
SELECT throws_ok('select user_id from demo_allowlist', '42501', NULL, 'demo_allowlist is unreadable');

SELECT lives_ok(
  $$ update tasks set status = 'open' where id = '11111111-1111-1111-1111-111111111111' $$,
  'a judged draft can be opened'
);
SELECT throws_ok(
  $$ update tasks set status = 'done' where id = '11111111-1111-1111-1111-111111111111' $$,
  'P0001',
  'only a judged draft can be opened',
  'opening is the only client status change'
);
SELECT throws_ok(
  $$ update tasks set status = 'open' where id = '22222222-2222-2222-2222-222222222222' $$,
  'P0001',
  'only a judged draft can be opened',
  'an unjudged draft stays a draft'
);

SELECT throws_ok(
  $$ update profiles set equipped_skin_id = 'skin_coder' $$,
  'P0001',
  'equipped skin must be an owned skin',
  'unowned skin is rejected'
);

RESET ROLE;
INSERT INTO inventory (user_id, catalog_id, source)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'skin_coder', 'level');
SET ROLE authenticated;

SELECT lives_ok(
  $$ update profiles set equipped_skin_id = 'skin_coder' $$,
  'an owned skin can be equipped'
);
SELECT lives_ok(
  $$ update profiles set title_id = 'title_adept' $$,
  'an owned title can be equipped'
);
SELECT throws_ok(
  $$ update profiles set title_id = 'title_archmage' $$,
  'P0001',
  'title must be owned',
  'an unowned title is rejected'
);
SELECT throws_ok(
  $$ update profiles set pinned_badges = ARRAY['badge_deep_worker'] $$,
  'P0001',
  'pinned badge needs tier 1',
  'a tier 0 badge cannot be pinned'
);

RESET ROLE;
UPDATE achievements SET tier = 1
WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' AND badge_id = 'badge_deep_worker';
SET ROLE authenticated;

SELECT lives_ok(
  $$ update profiles set pinned_badges = ARRAY['badge_deep_worker'] $$,
  'a tier 1 badge can be pinned'
);
SELECT lives_ok(
  $$ update inbox set read_at = now() where id = '33333333-3333-3333-3333-333333333333' $$,
  'the owner can mark inbox read'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
