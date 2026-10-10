-- Column grants (schema §3). RLS policies land in the next security migration.
-- anon gets nothing. demo_allowlist and processed_requests stay server-only.

revoke all on all tables in schema public from anon, authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;
revoke all on all functions in schema public from anon;

grant select on catalog_items, level_rewards, game_config,
  profiles, player_state, user_settings, tasks, sessions, bosses, inventory, achievements, daily_stats,
  friend_summaries, friendships, guilds, guild_members, guild_trophies, activity_events, weekly_scores,
  inbox, presence, raids, raid_members, raid_damage, raid_events to authenticated;

grant update (
  display_name, equipped_skin_id, equipped_background_id, equipped_frame_id,
  pinned_badges, title_id, hide_radar, show_boss_names
) on profiles to authenticated;

grant update (
  notif_bosses, notif_streak, notif_raids, notif_weekly, notif_leaderboard_nudge,
  quiet_start, quiet_end, appear_offline, study_context
) on user_settings to authenticated;

grant insert (title, notes, due_at, boss_id, raid_id) on tasks to authenticated;
grant update (stat, status) on tasks to authenticated;
grant delete on tasks to authenticated;

grant update (state, stat, started_at, raid_id, last_seen) on presence to authenticated;
grant update (read_at) on inbox to authenticated;
