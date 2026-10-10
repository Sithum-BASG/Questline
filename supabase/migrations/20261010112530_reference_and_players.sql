-- Reference data and player tables (schema §2.1–§2.2).
-- profiles.guild_id gets its foreign key when guilds exist.

create table catalog_items (
  id text primary key,
  type text not null check (type in ('skin', 'background', 'frame', 'gear', 'badge', 'title', 'consumable')),
  name text not null,
  rarity text check (rarity in ('common', 'rare', 'epic', 'legendary', 'mythic', 'special')),
  source text not null check (source in ('starter', 'level', 'chest', 'streak', 'special')),
  level int,
  slot text check (slot in ('weapon', 'armour', 'accessory')),
  boost numeric,
  passive text check (passive in ('deep_focus', 'boss_slayer')),
  set_id text,
  assets jsonb not null default '{}'
);

create table level_rewards (
  level int primary key check (level between 2 and 50),
  rewards jsonb not null
);

create table game_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  friend_code text unique not null,
  display_name text not null check (char_length(display_name) between 1 and 24),
  body_type text not null check (body_type in ('a', 'b')),
  level int not null default 1,
  title_id text references catalog_items (id),
  equipped_skin_id text not null default 'skin_starter' references catalog_items (id),
  equipped_background_id text not null default 'bg_starter' references catalog_items (id),
  equipped_frame_id text not null default 'frame_apprentice' references catalog_items (id),
  pinned_badges text[] not null default '{}',
  guild_id uuid,
  hide_radar boolean not null default false,
  show_boss_names boolean not null default false,
  created_at timestamptz not null default now(),
  constraint profiles_pinned_badges_max check (cardinality(pinned_badges) <= 3)
);

create table player_state (
  user_id uuid primary key references auth.users on delete cascade,
  coins int not null default 0 check (coins >= 0),
  xp_total int not null default 0,
  weekly_raw_xp int not null default 0,
  week_id text not null,
  streak_count int not null default 0,
  streak_last_counted_day date,
  streak_best int not null default 0,
  shields int not null default 0,
  last_shield_day date,
  potions int not null default 0,
  scrolls int not null default 0,
  free_chests int not null default 0,
  active_potion boolean not null default false,
  comeback_armed boolean not null default false,
  inactive_days int not null default 0,
  chests_since_legendary int not null default 0,
  boss_coins_this_week int not null default 0,
  ai_calls_today int not null default 0,
  focus_minutes_today int not null default 0,
  onboarding_step text not null default 'signed_in'
    check (onboarding_step in ('signed_in', 'character', 'story', 'study', 'first_task', 'first_session', 'done')),
  onboarding_bonus jsonb not null default '{"character":false,"first_task":false,"first_session":false}',
  owned_titles text[] not null default '{}',
  counters jsonb not null default '{"focus_minutes":0,"bosses_defeated":0,"raids_won":0,"raid_mvps":0,"balanced_weeks":0,"early_bird_sessions":0,"steady_pace_weeks":0,"punctual_tasks":0}',
  milestones_paid int[] not null default '{}',
  timezone text not null default 'Asia/Colombo',
  last_active_day date,
  next_rollover_at timestamptz not null,
  rest_weekday int check (rest_weekday between 0 and 6),
  pending_rest_weekday int check (pending_rest_weekday between 0 and 6),
  pause_active boolean not null default false,
  pause_until timestamptz,
  pause_days_used int not null default 0,
  pause_month text
);

create table user_settings (
  user_id uuid primary key references auth.users on delete cascade,
  notif_bosses boolean not null default true,
  notif_streak boolean not null default true,
  notif_raids boolean not null default true,
  notif_weekly boolean not null default true,
  notif_leaderboard_nudge boolean not null default false,
  quiet_start time not null default '23:00',
  quiet_end time not null default '07:00',
  appear_offline boolean not null default false,
  study_context text check (char_length(study_context) <= 80),
  demo_mode boolean not null default false
);
