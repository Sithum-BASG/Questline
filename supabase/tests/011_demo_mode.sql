-- T173: demo time runs at 2 seconds per minute; sessions are only demo when the server marks them.
BEGIN;
SELECT plan(3);

SELECT is((SELECT value FROM game_config WHERE key = 'demo_seconds_per_5_minutes'), '10'::jsonb,
  'demo counts 10 seconds as 5 minutes');
SELECT is(jsonb_typeof((SELECT value FROM game_config WHERE key = 'demo_seconds_per_5_minutes')), 'number',
  'the demo rate is stored as a number');
SELECT col_default_is('public', 'sessions', 'demo', 'false', 'sessions are not demo unless the server says so');

SELECT * FROM finish();
ROLLBACK;
