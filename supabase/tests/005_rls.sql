-- T024: every table has RLS, helpers exist, and the §5 indexes are present.
BEGIN;
SELECT plan(5);

SELECT ok(
  (
    SELECT bool_and(c.relrowsecurity)
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'r'
  ),
  'every public table has row level security'
);

SELECT has_function('public', 'is_friend', ARRAY['uuid', 'uuid'], 'is_friend exists');
SELECT has_function('public', 'validate_profile_update', 'validate_profile_update exists');
SELECT has_function('public', 'validate_task_update', 'validate_task_update exists');
SELECT has_index('public', 'tasks', 'tasks_user_status_due', 'quests index exists');

SELECT * FROM finish();
ROLLBACK;
