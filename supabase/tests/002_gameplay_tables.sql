-- T019: gameplay tables exist.
BEGIN;
SELECT plan(8);

SELECT has_table('public', 'bosses', 'bosses exists');
SELECT has_table('public', 'tasks', 'tasks exists');
SELECT has_table('public', 'sessions', 'sessions exists');
SELECT has_table('public', 'inventory', 'inventory exists');
SELECT has_table('public', 'achievements', 'achievements exists');
SELECT has_table('public', 'daily_stats', 'daily_stats exists');
SELECT has_table('public', 'weekly_scores', 'weekly_scores exists');

SELECT has_index('public', 'sessions', 'one_active_session', 'one active session per user');

SELECT * FROM finish();
ROLLBACK;
