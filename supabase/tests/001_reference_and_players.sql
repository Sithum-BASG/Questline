-- T018: reference data and player tables exist.
BEGIN;
SELECT plan(6);

SELECT has_table('public', 'catalog_items', 'catalog_items exists');
SELECT has_table('public', 'level_rewards', 'level_rewards exists');
SELECT has_table('public', 'game_config', 'game_config exists');
SELECT has_table('public', 'profiles', 'profiles exists');
SELECT has_table('public', 'player_state', 'player_state exists');
SELECT has_table('public', 'user_settings', 'user_settings exists');

SELECT * FROM finish();
ROLLBACK;
