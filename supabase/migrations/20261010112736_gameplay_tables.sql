-- Tasks, sessions, solo bosses, inventory, achievements and stats (schema §2.3–§2.4).
-- tasks.raid_id gets its foreign key when raids exist.
-- weekly_scores lives with the other per-user stats even though §2.5 groups it with social.

create table bosses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  title text not null,
  type text not null check (type in ('exam', 'assignment', 'project')),
  tier text not null check (tier in ('minion', 'brute', 'warlord', 'titan')),
  hours numeric not null check (hours between 2 and 40),
  max_hp int not null,
  damage int not null default 0,
  deadline timestamptz not null,
  created_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'staggered', 'defeated', 'escaped')),
  last_work_day date,
  coins_eligible boolean not null,
  loot jsonb,
  result_seen boolean not null default false
);

create table tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  notes text check (char_length(notes) <= 1000),
  due_at timestamptz,
  original_due_at timestamptz,
  boss_id uuid references bosses on delete set null,
  raid_id uuid,
  status text not null default 'draft' check (status in ('draft', 'open', 'done')),
  rescheduled boolean not null default false,
  scroll_used boolean not null default false,
  created_at timestamptz not null default now(),
  stat text check (stat in ('intellect', 'vitality', 'craft', 'charisma')),
  difficulty int check (difficulty between 1 and 5),
  est_minutes int check (est_minutes between 5 and 180),
  too_big boolean,
  reason text,
  provisional boolean not null default false,
  challenged boolean not null default false,
  judged_at timestamptz,
  completion_mode text check (completion_mode in ('focus', 'activity', 'tick')),
  completion_minutes int,
  completed_at timestamptz,
  completion_day date,
  xp_raw int,
  xp_final int
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  task_id uuid not null references tasks on delete cascade,
  mode text not null check (mode in ('focus', 'activity')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  interruptions jsonb not null default '[]',
  interruption_seconds int not null default 0,
  verified_minutes int,
  status text not null default 'active' check (status in ('active', 'completed', 'broken')),
  potion boolean not null default false,
  demo boolean not null default false,
  processed boolean not null default false,
  summary jsonb
);

create unique index one_active_session on sessions (user_id) where status = 'active';

create table inventory (
  user_id uuid not null references auth.users on delete cascade,
  catalog_id text not null references catalog_items (id),
  acquired_at timestamptz not null default now(),
  source text not null check (source in ('starter', 'level', 'chest', 'streak', 'mvp', 'leaderboard')),
  attuned_stat text check (attuned_stat in ('intellect', 'vitality', 'craft', 'charisma')),
  equipped_slot text check (equipped_slot in ('weapon', 'armour', 'accessory')),
  primary key (user_id, catalog_id)
);

create table achievements (
  user_id uuid not null references auth.users on delete cascade,
  badge_id text not null references catalog_items (id),
  progress int not null default 0,
  tier int not null default 0 check (tier between 0 and 3),
  updated_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table daily_stats (
  user_id uuid not null references auth.users on delete cascade,
  day date not null,
  xp_intellect int not null default 0,
  xp_vitality int not null default 0,
  xp_craft int not null default 0,
  xp_charisma int not null default 0,
  raw_xp int not null default 0,
  focus_minutes int not null default 0,
  sessions_started int not null default 0,
  met_minimum boolean not null default false,
  rest_day boolean not null default false,
  paused boolean not null default false,
  primary key (user_id, day)
);

create table weekly_scores (
  week_id text not null,
  user_id uuid not null references auth.users on delete cascade,
  raw_xp int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (week_id, user_id)
);
