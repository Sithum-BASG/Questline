-- T122: security pass — anon coin/level writes, stranger task reads.
BEGIN;
SELECT plan(8);

INSERT INTO auth.users (id, aud, role, email) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'owner@questline.test'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'authenticated', 'authenticated', 'stranger@questline.test');

INSERT INTO profiles (id, username, friend_code, display_name, body_type) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'owner_sec', 'OWNSEC01', 'Owner', 'a'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'stranger_sec', 'STRSEC01', 'Stranger', 'a');

INSERT INTO player_state (user_id, week_id, next_rollover_at, coins)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '2026-W41', now(), 50),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '2026-W41', now(), 0);

INSERT INTO tasks (id, user_id, title, notes, status, difficulty, stat) VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'Secret exam notes chapter 7',
    'Do not share this title',
    'open',
    4,
    'intellect'
  );

-- Anon key cannot mint coins or levels (plan 15.4).
SET ROLE anon;
SELECT throws_ok(
  $$ update public.player_state set coins = 999999 $$,
  '42501',
  NULL,
  'anon cannot write coins'
);
SELECT throws_ok(
  $$ update public.profiles set level = 50 $$,
  '42501',
  NULL,
  'anon cannot write level'
);
SELECT throws_ok(
  $$ update public.player_state set coins = 999999 where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
  '42501',
  NULL,
  'anon cannot target another player coins'
);
RESET ROLE;

-- Stranger cannot read another player's tasks or titles.
DO $$ BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'cccccccc-cccc-cccc-cccc-cccccccccccc', true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
END $$;
SET ROLE authenticated;

SELECT is(
  (SELECT count(*)::int FROM tasks WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  0,
  'stranger sees zero of the owner tasks'
);
SELECT is(
  (SELECT count(*)::int FROM tasks WHERE title ILIKE '%Secret exam%'),
  0,
  'stranger cannot find a private task title'
);
SELECT throws_ok(
  $$ update player_state set coins = 100 where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
  '42501',
  NULL,
  'authenticated client cannot write another player coins'
);
SELECT throws_ok(
  $$ update profiles set level = 40 where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' $$,
  '42501',
  NULL,
  'authenticated client cannot write another player level'
);
SELECT throws_ok(
  $$ update profiles set level = 40 $$,
  '42501',
  NULL,
  'authenticated client cannot write own level either'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
