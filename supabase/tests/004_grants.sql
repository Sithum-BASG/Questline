-- T022: clients get only the column grants in schema §3.
BEGIN;
SELECT plan(8);

SET ROLE anon;
SELECT throws_ok(
  'select id from public.profiles',
  '42501',
  NULL,
  'anon cannot read profiles'
);
RESET ROLE;

SET ROLE authenticated;
SELECT throws_ok(
  'select user_id from public.demo_allowlist',
  '42501',
  NULL,
  'demo_allowlist is unreadable'
);
SELECT throws_ok(
  'select user_id from public.processed_requests',
  '42501',
  NULL,
  'processed_requests is unreadable'
);
SELECT throws_ok(
  'update public.profiles set level = 2',
  '42501',
  NULL,
  'level is not a client column'
);
SELECT lives_ok(
  'update public.profiles set display_name = ''Ada''',
  'display_name is a client column'
);
SELECT throws_ok(
  'insert into public.player_state (user_id, week_id, next_rollover_at) values (gen_random_uuid(), ''2026-W41'', now())',
  '42501',
  NULL,
  'player_state is not client-writable'
);
SELECT throws_ok(
  'update public.user_settings set demo_mode = true',
  '42501',
  NULL,
  'demo_mode is server-only'
);
SELECT lives_ok(
  'update public.user_settings set notif_streak = false',
  'notification toggles are client columns'
);
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
