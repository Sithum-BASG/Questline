-- T021: social, guild, raid and inbox tables exist.
BEGIN;
SELECT plan(16);

SELECT has_table('public', 'friendships', 'friendships exists');
SELECT has_table('public', 'friend_summaries', 'friend_summaries exists');
SELECT has_table('public', 'activity_events', 'activity_events exists');
SELECT has_table('public', 'presence', 'presence exists');
SELECT has_table('public', 'guilds', 'guilds exists');
SELECT has_table('public', 'guild_members', 'guild_members exists');
SELECT has_table('public', 'guild_trophies', 'guild_trophies exists');
SELECT has_table('public', 'raids', 'raids exists');
SELECT has_table('public', 'raid_members', 'raid_members exists');
SELECT has_table('public', 'raid_damage', 'raid_damage exists');
SELECT has_table('public', 'raid_events', 'raid_events exists');
SELECT has_table('public', 'inbox', 'inbox exists');
SELECT has_table('public', 'demo_allowlist', 'demo_allowlist exists');
SELECT has_table('public', 'processed_requests', 'processed_requests exists');
SELECT has_index('public', 'guild_members', 'one_guild_per_user', 'one guild per user');
SELECT col_is_fk('public', 'profiles', 'guild_id', 'profiles.guild_id references guilds');

SELECT * FROM finish();
ROLLBACK;
