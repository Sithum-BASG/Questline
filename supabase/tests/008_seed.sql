-- T028: seed covers the catalog, every level reward and game_config.
BEGIN;
SELECT plan(6);

SELECT is((SELECT count(*)::int FROM catalog_items), 76, 'catalog has every item');
SELECT is((SELECT count(*)::int FROM level_rewards), 49, 'levels 2 through 50 are seeded');
SELECT is((SELECT count(*)::int FROM game_config), 66, 'game_config has every key');
SELECT is(
  (SELECT value::text FROM game_config WHERE key = 'guild_quest_coins'),
  '100',
  'D8 guild quest coins are 100'
);
SELECT ok(
  (SELECT id = 'title_raid_champion' FROM catalog_items WHERE id = 'title_raid_champion'),
  'D9 raid MVP title placeholder exists'
);
SELECT ok(
  (SELECT rewards @> '[{"type":"title","id":"title_fully_awakened"}]'::jsonb FROM level_rewards WHERE level = 50),
  'level 50 grants the final title'
);

SELECT * FROM finish();
ROLLBACK;
