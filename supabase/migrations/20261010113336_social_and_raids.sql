-- Social, guilds, raids, inbox and request bookkeeping (schema §2.5–§2.6).
-- demo_allowlist has no client access; grants come in the next migration.

create table friendships (
  user_id uuid not null references auth.users on delete cascade,
  friend_id uuid not null references auth.users on delete cascade,
  status text not null check (status in ('pending_out', 'pending_in', 'accepted')),
  since timestamptz not null default now(),
  primary key (user_id, friend_id)
);

create table friend_summaries (
  user_id uuid primary key references auth.users on delete cascade,
  equipped_gear jsonb not null default '[]',
  weekly_raw_xp int not null default 0,
  radar30 jsonb,
  radar7 jsonb,
  updated_at timestamptz not null default now()
);

create table activity_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users on delete cascade,
  type text not null check (type in ('level_up', 'boss_defeated', 'raid_won', 'chest_drop', 'badge')),
  payload jsonb not null,
  visible_to uuid[] not null,
  created_at timestamptz not null default now()
);

create table presence (
  user_id uuid primary key references auth.users on delete cascade,
  state text not null default 'idle' check (state in ('focusing', 'idle')),
  stat text check (stat in ('intellect', 'vitality', 'craft', 'charisma')),
  started_at timestamptz,
  raid_id uuid,
  last_seen timestamptz not null default now()
);

create table guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 3 and 24),
  emblem text not null,
  leader_id uuid not null references auth.users,
  invite_code text unique not null,
  quest_week_id text,
  quest_goal int not null default 5000,
  quest_progress int not null default 0,
  created_at timestamptz not null default now()
);

alter table profiles
  add constraint profiles_guild_fk foreign key (guild_id) references guilds on delete set null;

create table guild_members (
  guild_id uuid not null references guilds on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  joined_at timestamptz not null default now(),
  quest_contribution int not null default 0,
  primary key (guild_id, user_id)
);

create unique index one_guild_per_user on guild_members (user_id);

create table raids (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('guild', 'party')),
  guild_id uuid references guilds on delete set null,
  name text not null,
  title text not null,
  type text not null check (type in ('exam', 'assignment', 'project')),
  tier text not null,
  per_person_minutes int not null,
  participants int not null check (participants between 2 and 8),
  max_hp int not null,
  damage int not null default 0,
  deadline timestamptz not null,
  status text not null default 'active' check (status in ('active', 'victory', 'narrow_win', 'escaped')),
  created_by uuid references auth.users on delete set null,
  invite_code text unique,
  coins_eligible boolean not null,
  created_at timestamptz not null default now()
);

alter table tasks
  add constraint tasks_raid_fk foreign key (raid_id) references raids on delete set null;

create table guild_trophies (
  guild_id uuid references guilds on delete cascade,
  raid_id uuid not null,
  name text,
  won_at timestamptz,
  primary key (guild_id, raid_id)
);

create table raid_members (
  raid_id uuid not null references raids on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  display_name text not null,
  skin_id text,
  frame_id text,
  body_type text,
  title_id text,
  joined_at timestamptz not null default now(),
  left_raid boolean not null default false,
  met_fair_share boolean not null default false,
  is_mvp boolean not null default false,
  primary key (raid_id, user_id)
);

create table raid_damage (
  raid_id uuid not null references raids on delete cascade,
  user_id uuid not null references auth.users on delete cascade,
  damage int not null default 0,
  primary key (raid_id, user_id)
);

create table raid_events (
  id bigint generated always as identity primary key,
  raid_id uuid not null references raids on delete cascade,
  user_id uuid not null,
  display_name text not null,
  amount int not null,
  at timestamptz not null default now()
);

create table inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  type text not null check (type in (
    'guild_fight', 'raid_result', 'weekly_results', 'friend_request', 'boss_result', 'system'
  )),
  payload jsonb not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table demo_allowlist (
  user_id uuid primary key references auth.users on delete cascade
);

create table processed_requests (
  user_id uuid not null references auth.users on delete cascade,
  request_id text not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, request_id)
);
