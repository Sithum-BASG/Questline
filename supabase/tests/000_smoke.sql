-- Smoke check so `supabase test db` has a suite before the schema migrations.
BEGIN;
SELECT plan(1);
SELECT ok(true, 'local database is reachable');
SELECT * FROM finish();
ROLLBACK;
