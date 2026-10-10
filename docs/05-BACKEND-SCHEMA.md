# 05 · Backend Schema — Supabase (Postgres, RLS, Edge Functions)

**Product:** Questline · **Last updated:** 10 Oct 2026 (v4: Groq as the AI provider; strict JSON schemas)
**Read with:** `02-TRD.md` (stack and the server-owns-state rule), `01-PRD.md` §6 (the numbers).

> **For the AI agent:** This is the contract between the app and the server. Table names, column names, action names and allowed string values must match exactly. Columns are **server-written** unless listed in §3 as client-writable. Write every change as a migration in `supabase/migrations/`. Items marked **DECISION** in §13 are proposed defaults the team should confirm; read their values from `game_config` where possible.

---

## 1. Principles

1. **Server-authoritative.** Game state is written only by Edge Functions inside a transaction. The client has `SELECT` (filtered by RLS) plus a handful of column-level grants (§3).
2. **Deny by default.** `revoke all` from `anon` and `authenticated`, RLS enabled on every table, then grant back the minimum.
3. **Public / private split.** `profiles` is readable by any signed-in user; everything else is owner-only or shared through explicit policies (friends, raid members, guild members).
4. **Pure game logic.** Formulas live in `supabase/functions/_shared/game/*` as pure TypeScript with `deno test`.
5. **Day keys** (`date`) are computed in the user's IANA timezone with a **4 a.m.** boundary. The leaderboard week uses one global boundary: **Monday 04:00 in `LEADERBOARD_TZ`** (default `Asia/Colombo`). `week_id` format `2026-W41`.
6. **Every user table** has `user_id uuid references auth.users on delete cascade`, so deleting the Auth user deletes everything.

---

## 2. Tables

Column types are Postgres. `stat` columns use `check (stat in ('intellect','vitality','craft','charisma'))`; `rarity` uses `check (rarity in ('common','rare','epic','legendary','mythic','special'))`. Shown as `-- ✎` where the client may write (see §3).

### 2.1 Reference data (read-only for clients)
```sql
create table catalog_items (
  id text primary key,                 -- namespaced: skin_coder, bg_quad, frame_bookworm, gear_weapon_ink_nib_dagger, badge_deep_worker, title_adept, consumable_focus_potion
  type text not null check (type in ('skin','background','frame','gear','badge','title','consumable')),
  name text not null, rarity text, source text not null check (source in ('starter','level','chest','streak','special')),
  level int, slot text check (slot in ('weapon','armour','accessory')), boost numeric, passive text check (passive in ('deep_focus','boss_slayer')),
  set_id text, assets jsonb not null default '{}'   -- {a, b} for skins, {image} otherwise
);
create table level_rewards (level int primary key check (level between 2 and 50), rewards jsonb not null);  -- [{type:'item',id:'frame_margin_notes'},{type:'coins',amount:150},{type:'title',id:'title_adept'}]
create table game_config (key text primary key, value jsonb not null, updated_at timestamptz not null default now());
create table demo_allowlist (user_id uuid primary key references auth.users on delete cascade);   -- no client access
```

### 2.2 Players
```sql
create table profiles (                          -- public: any signed-in user can read
  id uuid primary key references auth.users on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  friend_code text unique not null,              -- 8 chars, A–Z 2–9 without ambiguous characters
  display_name text not null check (char_length(display_name) between 1 and 24),   -- ✎
  body_type text not null check (body_type in ('a','b')),
  level int not null default 1,
  title_id text references catalog_items(id),    -- ✎ must be owned
  equipped_skin_id text not null default 'skin_starter' references catalog_items(id),          -- ✎ must be owned
  equipped_background_id text not null default 'bg_starter' references catalog_items(id),      -- ✎
  equipped_frame_id text not null default 'frame_apprentice' references catalog_items(id),     -- ✎
  pinned_badges text[] not null default '{}' check (cardinality(pinned_badges) <= 3),          -- ✎ tier ≥ 1
  guild_id uuid,                                  -- FK added after guilds
  hide_radar boolean not null default false,      -- ✎
  show_boss_names boolean not null default false, -- ✎
  created_at timestamptz not null default now()
);

create table player_state (                      -- owner read only
  user_id uuid primary key references auth.users on delete cascade,
  coins int not null default 0 check (coins >= 0),
  xp_total int not null default 0,               -- final XP incl. starter bonus
  weekly_raw_xp int not null default 0, week_id text not null,
  streak_count int not null default 0, streak_last_counted_day date, streak_best int not null default 0,
  shields int not null default 0, last_shield_day date,
  potions int not null default 0, scrolls int not null default 0, free_chests int not null default 0,
  active_potion boolean not null default false,
  comeback_armed boolean not null default false, inactive_days int not null default 0,
  chests_since_legendary int not null default 0,
  boss_coins_this_week int not null default 0,
  ai_calls_today int not null default 0,
  focus_minutes_today int not null default 0,
  onboarding_step text not null default 'signed_in'
    check (onboarding_step in ('signed_in','character','story','study','first_task','first_session','done')),
  onboarding_bonus jsonb not null default '{"character":false,"first_task":false,"first_session":false}',
  owned_titles text[] not null default '{}',
  counters jsonb not null default '{"focus_minutes":0,"bosses_defeated":0,"raids_won":0,"raid_mvps":0,"balanced_weeks":0,"early_bird_sessions":0,"steady_pace_weeks":0,"punctual_tasks":0}',
  milestones_paid int[] not null default '{}',
  timezone text not null default 'Asia/Colombo',
  last_active_day date,
  next_rollover_at timestamptz not null,
  rest_weekday int check (rest_weekday between 0 and 6), pending_rest_weekday int check (pending_rest_weekday between 0 and 6),
  pause_active boolean not null default false, pause_until timestamptz, pause_days_used int not null default 0, pause_month text
);

create table user_settings (                     -- owner read + update (except demo_mode)
  user_id uuid primary key references auth.users on delete cascade,
  notif_bosses boolean not null default true,  notif_streak boolean not null default true,     -- ✎
  notif_raids boolean not null default true,   notif_weekly boolean not null default true,     -- ✎
  notif_leaderboard_nudge boolean not null default false,                                      -- ✎
  quiet_start time not null default '23:00', quiet_end time not null default '07:00',          -- ✎
  appear_offline boolean not null default false,                                               -- ✎
  study_context text check (char_length(study_context) <= 80),                                 -- ✎ sent to the AI provider
  demo_mode boolean not null default false        -- server only; honoured only if in demo_allowlist
);
```

### 2.3 Tasks, sessions, solo bosses
```sql
create table bosses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  name text not null, title text not null, type text not null check (type in ('exam','assignment','project')),
  tier text not null check (tier in ('minion','brute','warlord','titan')),
  hours numeric not null check (hours between 2 and 40), max_hp int not null, damage int not null default 0,
  deadline timestamptz not null, created_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active','staggered','defeated','escaped')),
  last_work_day date, coins_eligible boolean not null,
  loot jsonb, result_seen boolean not null default false
);

create table tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  title text not null check (char_length(title) between 1 and 200),   -- ✎ insert only; frozen once judged
  notes text check (char_length(notes) <= 1000),                      -- ✎ insert only
  due_at timestamptz,                                                  -- ✎ insert only; later via rescheduleTask
  original_due_at timestamptz,
  boss_id uuid references bosses on delete set null,                   -- ✎ insert only (must own)
  raid_id uuid,                                                        -- ✎ insert only (must be member); FK below
  status text not null default 'draft' check (status in ('draft','open','done')),   -- ✎ draft→open only
  rescheduled boolean not null default false, scroll_used boolean not null default false,
  created_at timestamptz not null default now(),
  -- judgement (server), except stat
  stat text check (stat in ('intellect','vitality','craft','charisma')),             -- ✎ while draft/open
  difficulty int check (difficulty between 1 and 5), est_minutes int check (est_minutes between 5 and 180),
  too_big boolean, reason text, provisional boolean not null default false, challenged boolean not null default false,
  judged_at timestamptz,
  -- completion (server)
  completion_mode text check (completion_mode in ('focus','activity','tick')), completion_minutes int,
  completed_at timestamptz, completion_day date,
  xp_raw int, xp_final int
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  task_id uuid not null references tasks on delete cascade,
  mode text not null check (mode in ('focus','activity')),
  started_at timestamptz not null default now(), ended_at timestamptz,
  interruptions jsonb not null default '[]', interruption_seconds int not null default 0,
  verified_minutes int, status text not null default 'active' check (status in ('active','completed','broken')),
  potion boolean not null default false, demo boolean not null default false,
  processed boolean not null default false, summary jsonb        -- idempotency: retry returns the stored summary
);
create unique index one_active_session on sessions (user_id) where status = 'active';
```

### 2.4 Inventory, achievements, daily stats
```sql
create table inventory (
  user_id uuid not null references auth.users on delete cascade,
  catalog_id text not null references catalog_items(id),
  acquired_at timestamptz not null default now(),
  source text not null check (source in ('starter','level','chest','streak','mvp','leaderboard')),
  attuned_stat text check (attuned_stat in ('intellect','vitality','craft','charisma')),   -- gear only
  equipped_slot text check (equipped_slot in ('weapon','armour','accessory')),            -- gear only
  primary key (user_id, catalog_id)                 -- one copy per item; duplicates are refunded, never stored
);
create table achievements (
  user_id uuid not null references auth.users on delete cascade, badge_id text not null references catalog_items(id),
  progress int not null default 0, tier int not null default 0 check (tier between 0 and 3), updated_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);
create table daily_stats (
  user_id uuid not null references auth.users on delete cascade, day date not null,
  xp_intellect int not null default 0, xp_vitality int not null default 0, xp_craft int not null default 0, xp_charisma int not null default 0,
  raw_xp int not null default 0, focus_minutes int not null default 0, sessions_started int not null default 0,
  met_minimum boolean not null default false, rest_day boolean not null default false, paused boolean not null default false,
  primary key (user_id, day)
);
create table friend_summaries (                   -- what friends may see beyond the public profile
  user_id uuid primary key references auth.users on delete cascade,
  equipped_gear jsonb not null default '[]',      -- [{slot, catalog_id, attuned_stat}]
  weekly_raw_xp int not null default 0,
  radar30 jsonb, radar7 jsonb,                    -- null when hide_radar
  updated_at timestamptz not null default now()
);
```
Radar = sum of `xp_<stat>` (raw XP) over the last 30 or 7 `daily_stats` rows.

### 2.5 Social
```sql
create table friendships (                        -- two rows per pair, written by social functions
  user_id uuid not null references auth.users on delete cascade,
  friend_id uuid not null references auth.users on delete cascade,
  status text not null check (status in ('pending_out','pending_in','accepted')),
  since timestamptz not null default now(),
  primary key (user_id, friend_id)
);
create table guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 3 and 24), emblem text not null,
  leader_id uuid not null references auth.users, invite_code text unique not null,
  quest_week_id text, quest_goal int not null default 5000, quest_progress int not null default 0,
  created_at timestamptz not null default now()
);
alter table profiles add constraint profiles_guild_fk foreign key (guild_id) references guilds on delete set null;
create table guild_members (
  guild_id uuid not null references guilds on delete cascade, user_id uuid not null references auth.users on delete cascade,
  joined_at timestamptz not null default now(), quest_contribution int not null default 0,
  primary key (guild_id, user_id)
);
create unique index one_guild_per_user on guild_members (user_id);
create table guild_trophies (guild_id uuid references guilds on delete cascade, raid_id uuid, name text, won_at timestamptz, primary key (guild_id, raid_id));

create table activity_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users on delete cascade,
  type text not null check (type in ('level_up','boss_defeated','raid_won','chest_drop','badge')),
  payload jsonb not null,                          -- never a task title; boss name only if actor allows
  visible_to uuid[] not null,                      -- actor's accepted friends at write time
  created_at timestamptz not null default now()
);
create table weekly_scores (
  week_id text not null, user_id uuid not null references auth.users on delete cascade,
  raw_xp int not null default 0, updated_at timestamptz not null default now(),
  primary key (week_id, user_id)
);
create table inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  type text not null check (type in ('guild_fight','raid_result','weekly_results','friend_request','boss_result','system')),
  payload jsonb not null, created_at timestamptz not null default now(),
  read_at timestamptz                              -- ✎ owner may set
);
create table presence (                           -- "focusing now"; not game state
  user_id uuid primary key references auth.users on delete cascade,
  state text not null default 'idle' check (state in ('focusing','idle')),   -- ✎
  stat text, started_at timestamptz, raid_id uuid,                            -- ✎
  last_seen timestamptz not null default now()                                -- ✎ heartbeat every 60 s while focusing
);
```
"Focusing now" is shown only when `state = 'focusing' and last_seen > now() - interval '2 minutes'`. When `appear_offline` is on, the client never sets `focusing`.

### 2.6 Raids
```sql
create table raids (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('guild','party')), guild_id uuid references guilds on delete set null,
  name text not null, title text not null, type text not null check (type in ('exam','assignment','project')),
  tier text not null, per_person_minutes int not null, participants int not null check (participants between 2 and 8),
  max_hp int not null, damage int not null default 0,                 -- max_hp = per_person_minutes × participants
  deadline timestamptz not null,
  status text not null default 'active' check (status in ('active','victory','narrow_win','escaped')),
  created_by uuid references auth.users on delete set null, invite_code text unique,
  coins_eligible boolean not null, created_at timestamptz not null default now()
);
alter table tasks add constraint tasks_raid_fk foreign key (raid_id) references raids on delete set null;
create table raid_members (                      -- visible to all members
  raid_id uuid not null references raids on delete cascade, user_id uuid not null references auth.users on delete cascade,
  display_name text not null, skin_id text, frame_id text, body_type text, title_id text,
  joined_at timestamptz not null default now(), left_raid boolean not null default false,
  met_fair_share boolean not null default false,   -- live "pulled their weight" check
  is_mvp boolean not null default false,
  primary key (raid_id, user_id)
);
create table raid_damage (                       -- exact totals: the member themself + the raid creator only
  raid_id uuid not null references raids on delete cascade, user_id uuid not null references auth.users on delete cascade,
  damage int not null default 0, primary key (raid_id, user_id)
);
create table raid_events (                       -- damage ticker; deleted after the raid resolves
  id bigint generated always as identity primary key,
  raid_id uuid not null references raids on delete cascade, user_id uuid not null, display_name text not null,
  amount int not null, at timestamptz not null default now()
);
create table processed_requests (                -- idempotency for openChest and similar
  user_id uuid not null references auth.users on delete cascade, request_id text not null,
  result jsonb not null, created_at timestamptz not null default now(), primary key (user_id, request_id)
);
```

---

## 3. Grants (column-level) — the client's only write paths

```sql
revoke all on all tables in schema public from anon, authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;
revoke all on all functions in schema public from anon;          -- RPC helpers below are granted explicitly

grant select on catalog_items, level_rewards, game_config,
  profiles, player_state, user_settings, tasks, sessions, bosses, inventory, achievements, daily_stats,
  friend_summaries, friendships, guilds, guild_members, guild_trophies, activity_events, weekly_scores,
  inbox, presence, raids, raid_members, raid_damage, raid_events to authenticated;

grant update (display_name, equipped_skin_id, equipped_background_id, equipped_frame_id,
              pinned_badges, title_id, hide_radar, show_boss_names) on profiles to authenticated;
grant update (notif_bosses, notif_streak, notif_raids, notif_weekly, notif_leaderboard_nudge,
              quiet_start, quiet_end, appear_offline, study_context) on user_settings to authenticated;
grant insert (title, notes, due_at, boss_id, raid_id) on tasks to authenticated;
grant update (stat, status) on tasks to authenticated;
grant delete on tasks to authenticated;
grant update (state, stat, started_at, raid_id, last_seen) on presence to authenticated;
grant update (read_at) on inbox to authenticated;
-- nothing for anon. Nothing on demo_allowlist or processed_requests.
```
Rows in `player_state`, `user_settings`, `presence`, `friend_summaries` are created by the server during onboarding.

---

## 4. Row Level Security

Enable RLS on **every** table. Helper functions are `security definer`, `stable`, `set search_path = public`, so policies don't recurse:

```sql
create function is_friend(a uuid, b uuid) returns boolean ... as $$
  select exists (select 1 from friendships where user_id = a and friend_id = b and status = 'accepted') $$;
create function is_raid_member(r uuid, u uuid) returns boolean ... as $$
  select exists (select 1 from raid_members where raid_id = r and user_id = u and not left_raid) $$;
create function is_raid_creator(r uuid, u uuid) returns boolean ... as $$
  select exists (select 1 from raids where id = r and created_by = u) $$;
create function is_guild_member(g uuid, u uuid) returns boolean ... as $$
  select exists (select 1 from guild_members where guild_id = g and user_id = u) $$;
create function radar_hidden(u uuid) returns boolean ... as $$ select hide_radar from profiles where id = u $$;
```

| Table | SELECT | UPDATE / INSERT / DELETE (client) |
|---|---|---|
| `catalog_items`, `level_rewards`, `game_config` | `true` (authenticated) | — |
| `profiles` | `auth.uid() is not null` | update: `id = auth.uid()` + trigger `validate_profile_update` (equipped items owned and of the right type; title in `owned_titles`; pinned badges tier ≥ 1) |
| `player_state`, `sessions`, `bosses`, `inventory`, `achievements`, `friendships` | `user_id = auth.uid()` | — |
| `user_settings` | `user_id = auth.uid()` | update: `user_id = auth.uid()` |
| `tasks` | `user_id = auth.uid()` | insert: `user_id = auth.uid() and status = 'draft'` and boss owned / raid member; update: own and `status in ('draft','open')` + trigger `validate_task_update` (only `draft→open` with `difficulty is not null`; stat change only before done); delete: own and `status in ('draft','open')` |
| `daily_stats` | own **or** (`is_friend(user_id, auth.uid())` and not `radar_hidden(user_id)`) | — |
| `friend_summaries`, `weekly_scores` | own or `is_friend(user_id, auth.uid())` | — |
| `guilds` | `is_guild_member(id, auth.uid())` | — |
| `guild_members`, `guild_trophies` | `is_guild_member(guild_id, auth.uid())` | — |
| `activity_events` | `auth.uid() = any(visible_to)` | — |
| `inbox` | `user_id = auth.uid()` | update `read_at`: own |
| `presence` | own **or** `is_friend(user_id, auth.uid())` **or** (`raid_id is not null and is_raid_member(raid_id, auth.uid())`) | update: own |
| `raids`, `raid_members`, `raid_events` | `is_raid_member(raid_id/id, auth.uid())` | — |
| `raid_damage` | `user_id = auth.uid()` or `is_raid_creator(raid_id, auth.uid())` | — |
| `demo_allowlist`, `processed_requests` | none | — |

**Privacy matrix → enforcement**

| Information | Anyone | Party member (not friend) | Friend / guild | Enforced by |
|---|---|---|---|---|
| Name, character, level, title, frame | ✓ | ✓ | ✓ | `profiles` policy |
| Raid damage | — | check mark only | check mark (creator: exact) | `raid_members.met_fair_share`; exact in `raid_damage` |
| Focusing now | — | only on that raid | ✓ (stat + time) | `presence` policy |
| Weekly XP | — | — | ✓ | `weekly_scores`, `friend_summaries` |
| Activity feed | — | — | ✓ | `visible_to` |
| Gear, radar, pinned badges | — | — | ✓ (radar unless hidden) | `friend_summaries`, `daily_stats` |
| Task titles/details | never | never | never | `tasks` owner-only; payloads never include titles |

**pgTAP tests** (`supabase/tests/`) must cover owner / friend / stranger / party member for every table, every column a client must not write (expect `permission denied`), and every trigger rule.

---

## 5. Realtime and indexes

```sql
alter publication supabase_realtime add table raids, raid_members, raid_events, presence, inbox;
```
Realtime applies RLS to these subscriptions. Subscribe only on the screens that need them (raid detail, guild home, Home/Social for presence, the app shell for inbox) and unsubscribe on leave.

| Index | Used by |
|---|---|
| `tasks (user_id, status, due_at)` | Quests Today/Upcoming |
| `tasks (provisional) where provisional` | Re-judge sweep |
| `bosses (status, deadline) where status in ('active','staggered')` | Deadline resolver |
| `raids (status, deadline) where status = 'active'` | Deadline resolver |
| `raid_members (user_id)` | Bosses tab ("my raids") |
| `activity_events using gin (visible_to)` + `(created_at desc)` | Feed |
| `player_state (next_rollover_at)` | Hourly rollover |
| `sessions (status, started_at) where status = 'active'` | Stale session sweep |
| `daily_stats (user_id, day desc)` | Radar, recap |
| `weekly_scores (week_id, raw_xp desc)` | Leaderboard |

Leaderboard (RLS already limits rows to me + friends):
```dart
supabase.from('weekly_scores')
  .select('user_id, raw_xp, profiles!inner(display_name, equipped_frame_id, equipped_skin_id, title_id, level)')
  .eq('week_id', weekId).order('raw_xp', ascending: false);
```

---

## 6. Edge Functions

All client-facing calls follow `02-TRD.md` §6: `supabase.functions.invoke('<function>', body: {'action': '<action>', ...})`.

| Function | Action | Input | Does | Returns |
|---|---|---|---|---|
| `account` | `completeOnboardingStep` | `{ step, data? }` | `signed_in`: create `player_state`, `user_settings` (timezone from data). `character`: create `profiles` (generated username + friend code), starter inventory (`skin_starter`, `bg_starter`, `frame_apprentice`), `presence`, `friend_summaries`. Starter XP once per step: 20 character, 20 first task, 40 first session (not on leaderboard; level rewards granted normally); `first_session` also grants 1 free chest | `{ onboardingStep, xpTotal, level, rewards[] }` |
| `account` | `setRestDay` | `{ weekday }` | Takes effect next leaderboard week | ok |
| `account` | `setPause` | `{ active, until? }` | Max 7 days per calendar month | ok |
| `account` | `deleteAccount` | `{}` | `auth.admin.deleteUser(uid)`; cascades; clean raid/guild leftovers | ok |
| `tasks` | `judgeTask` | `{ taskId }` | Own draft task; daily AI limit; AI judge (`_shared/ai`, provider per `02-TRD.md` §7); validate/clamp; write judgement or provisional | `Judgement + xpPreview` |
| `tasks` | `challengeTask` | `{ taskId, context }` | Once per task; re-judge from scratch; final | `Judgement` |
| `tasks` | `tickTask` | `{ taskId }` | 50% path, no damage | `SessionSummary` |
| `tasks` | `rescheduleTask` | `{ taskId, newDueAt, useScroll }` | Penalty flag unless a scroll is spent | task |
| `sessions` | `startSession` | `{ taskId, mode, usePotion? }` | Task open; activity only for Vitality/Charisma; one active session (unique index); arm potion | `{ sessionId, startedAt, capMinutes }` |
| `sessions` | `endSession` | `{ sessionId, interruptions[], broken? }` | **XP engine** (§10.1) in one transaction: verified minutes → caps → raw → final → boss/raid damage → `daily_stats` → `weekly_scores` → guild quest → level-ups and rewards → achievements → `activity_events` → `friend_summaries` | `SessionSummary` |
| `bosses` | `createBoss` | `{ title, description?, type, deadline, hours?, dryRun }` | `dryRun`: AI estimate + name, no write. Else create with hours 2–40, tier, HP, `coins_eligible`; 15-fight limit | preview / boss |
| `bosses` | `submitBoss` | `{ bossId }` | Defeated before deadline; full (≥ 75%) or half loot; weekly coin cap | result + rewards |
| `raids` | `createRaid` | `{ source, guildId?, title, description?, type, deadline, participants, perPersonHours?, dryRun }` | Like `createBoss` with per-person estimate; party gets `invite_code`; guild fight → inbox for all guild members | preview / raid |
| `raids` | `joinRaid` | `{ code }` or `{ raidId }` | Party: anyone with the code; guild fight: guild members; size + 15-fight limits | raid |
| `raids` | `leaveRaid` | `{ raidId }` | `left_raid = true`; damage stays; loot forfeited | ok |
| `loot` | `openChest` | `{ requestId, useFreeChest? }` | 500 coins or a free chest; roll (§10.4); idempotent via `processed_requests` | `{ rarity, item \| pouch \| consumable, refund?, pityCounter }` |
| `loot` | `equipGear` | `{ catalogId, slot }` | Must own; one per slot; refresh `friend_summaries` | ok |
| `loot` | `attuneGear` | `{ catalogId, stat }` | First attunement free; re-attune 200 coins | ok |
| `loot` | `usePotion` | `{}` | Arm `active_potion` | ok |
| `social` | `sendFriendRequest` | `{ username } \| { friendCode }` | Pending rows both sides + inbox `friend_request` | ok |
| `social` | `respondFriendRequest` | `{ fromUid, accept }` | Accept → both `accepted` | ok |
| `social` | `removeFriend` | `{ friendUid }` | Not while in the same guild | ok |
| `social` | `createGuild` | `{ name, emblem }` | One guild per user; invite code | guild |
| `social` | `joinGuild` | `{ code }` | Max 10; friends with leader; auto-befriend members (**DECISION D7**) | guild |
| `social` | `leaveGuild` | `{}` | Leader leaving passes leadership to the oldest member or deletes an empty guild | ok |

**Function skeleton** (every action follows it):
```ts
// supabase/functions/sessions/index.ts
Deno.serve(handler(async (req, user) => {          // _shared/http.ts: CORS, JWT → user, zod, error mapping
  const body = EndSessionInput.parse(await req.json());
  return await sql.begin(async (tx) => {             // _shared/db.ts: postgres() on SUPABASE_DB_URL (pooler, prepare: false)
    const [s] = await tx`select * from sessions where id = ${body.sessionId} and user_id = ${user.id} for update`;
    if (!s) throw notFound();
    if (s.processed) return s.summary;                // idempotent retry
    // ... pure game/xp.ts calls, then writes, all filtered by user.id
  });
}));
```

### Scheduled (pg_cron → pg_net → Edge Function)
```sql
select cron.schedule('rollover-hourly', '0 * * * *', $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url') || '/functions/v1/cron-rollover',
    headers := jsonb_build_object('x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')),
    body := '{}'::jsonb) $$);
-- 'deadlines-15m'  '*/15 * * * *'  → cron-deadlines
-- 'weekly-reset'   '30 22 * * 0'   → cron-weekly   (pg_cron runs in UTC: Sunday 22:30 UTC = Monday 04:00 Asia/Colombo)
```

| Function | Does |
|---|---|
| `cron-rollover` | For `player_state` with `next_rollover_at <= now()` (batch ≤ 200 per call): close the day (streak with rest day / pause / shield, milestones), boss healing (§10.3), inactive days → `comeback_armed`, reset `ai_calls_today` and `focus_minutes_today`, refresh `friend_summaries` radar, pause expiry, set next `next_rollover_at` |
| `cron-deadlines` | Solo bosses past deadline → escaped (−100 coins, floor 0) + inbox `boss_result`; raids past deadline → result, fair share, loot, penalty, MVP roll, guild trophy, feed `raid_won`, inbox `raid_result` for members, delete `raid_events`; close stale active sessions (> 3× estimate) as broken; re-judge provisional tasks (≤ 20 per run) |
| `cron-weekly` | Leaderboard rank rewards (§10.7), weekly target coins, guild quest payout, Balanced / Steady Pace counters, inbox `weekly_results` with recap data, reset weekly counters, new `week_id`, apply `pending_rest_weekday` |

Free-plan note: if pg_cron isn't available on the project, run the same three URLs from a GitHub Actions `schedule:` workflow with the `x-cron-secret` header.

---

## 7. Supabase Auth setup

- Providers: Email (confirm email **off** for the course build so onboarding stays under 3 minutes; mention in the report) and Google.
- Google: create OAuth client IDs (Web + Android, + iOS) in Google Cloud console (free, no billing); add the Web client ID/secret to Supabase Auth; Flutter uses `google_sign_in` with `serverClientId` = Web client ID, then `signInWithIdToken`.
- Redirect URL for email links: `questline://auth-callback`.

---

## 8. `game_config` rows (defaults also in `_shared/config.ts`)

One row per key; `value` is JSON. Changing a row in the Table Editor retunes the game within ~60 s, no app update.

```json
{
  "xp_difficulty_multipliers": [0.5, 0.75, 1.0, 1.3, 1.6],
  "xp_focus_cap_ratio": 1.5, "xp_activity_cap_ratio": 1.0,
  "xp_activity_share": 0.8, "xp_tick_share": 0.5,
  "xp_on_time_bonus": 0.10, "xp_late_penalty_per_day": 0.10, "xp_late_floor": 0.5, "xp_reschedule_penalty": 0.20,
  "xp_daily_focus_minutes_limit": 480, "xp_grace_seconds": 30,
  "level_curve": { "base": 80, "coef": 5.5, "exp": 1.4, "round_to": 10, "max_level": 50 },
  "starter_bonus": { "character": 20, "first_task": 20, "first_session": 40 },
  "potion_multiplier": 1.5, "potion_min_minutes": 25, "comeback_multiplier": 2.0, "comeback_inactive_days": 3,
  "gear_boost": { "common": 0.03, "rare": 0.05, "epic": 0.07, "legendary": 0.09 }, "gear_stat_cap": 0.25,
  "deep_focus_min_minutes": 45, "deep_focus_bonus": 0.10, "boss_slayer_bonus": 0.20, "reattune_cost": 200,
  "chest_cost": 500,
  "chest_rarity_rates": { "common": 0.55, "rare": 0.30, "epic": 0.12, "legendary": 0.025, "mythic": 0.005 },
  "chest_legendary_pity": 30,
  "chest_common_pouches": [[50, 0.60], [100, 0.30], [200, 0.09], [500, 0.01]],
  "chest_rare_cosmetic_chance": 0.5,
  "chest_rare_consumables": { "streak_shield": 0.40, "focus_potion": 0.35, "reschedule_scroll": 0.25 },
  "consumable_overflow_coins": 100,
  "duplicate_refund": { "rare": 100, "epic": 200, "legendary": 400, "mythic": 500 },
  "hold_limits": { "streak_shield": 2, "focus_potion": 3 },
  "streak_min_raw_xp": 40, "day_boundary_hour": 4,
  "streak_milestones": { "7": {"coins": 100}, "14": {"coins": 150}, "30": {"freeChest": 1}, "60": {"item": "frame_unbroken"}, "100": {"title": "title_unbroken"} },
  "boss_hours_min": 2, "boss_hours_max": 40,
  "boss_tiers": [["minion", 0, 4, 100], ["brute", 4, 12, 150], ["warlord", 12, 25, 200], ["titan", 25, 999, 300]],
  "boss_full_loot_threshold": 0.75, "boss_heal_per_day": 0.03, "boss_escape_penalty": 100,
  "boss_weekly_coin_cap": 600, "boss_min_hours_before_deadline_for_coins": 48, "max_active_fights": 15,
  "raid_victory_bonus": 0.25, "raid_narrow_threshold": 0.75, "raid_fair_share_ratio": 0.5,
  "raid_mvp_item_chance": 0.30, "party_min": 2, "party_max": 8, "guild_max": 10,
  "guild_quest_goal": 5000, "guild_quest_min_contribution": 200, "guild_quest_coins": 100,
  "weekly_target_raw_xp": 500, "weekly_target_coins": 200,
  "leaderboard_min_friends": 4,
  "leaderboard_rewards": [[300, 0.50], [200, 0.30], [150, 0.20]],
  "special_item_pool": { "streak_shield": 0.40, "focus_potion": 0.35, "reschedule_scroll": 0.20, "free_chest": 0.05 },
  "badge_tier_coins": [50, 100, 200],
  "pause_max_days_per_month": 7,
  "ai_daily_limit": 50, "ai_timeout_ms": 10000,
  "notif_daily_cap": 2,
  "presence_stale_seconds": 120,
  "demo_seconds_per_5_minutes": 30
}
```
`guild_quest_coins` isn't in the overview: **DECISION D8**. The app reads the same table for display (rates on the chest screen, level road, penalties), but only the server's values count.

---

## 9. Catalog seed (ids)

Ids are **namespaced** because short names repeat across types (`sunscholar` is a skin and a frame). The same id is used in `catalog_items`, `inventory.catalog_id`, `profiles.equipped_*` and `level_rewards`, and matches the asset file base name in `game_assets.dart`. The short names below drop the prefix.

**Skins** (`skin_<id>`, assets `_a`/`_b`): `starter` (starter) · `coder` L4 Common · `alchemist` L14 Rare · `sigil_runner` L24 Rare · `starweaver` L36 Epic · `awakened` L50 Epic · `sunscholar` chest Legendary · `elfwarden` chest Legendary · `chronomancer` chest Mythic (set `chrono`).
**Backgrounds** (`bg_<id>`): `starter` (starter) · `quad` L6 C · `study_room` L8 C · `chem_lab` L18 R · `running_track` L22 R · `observatory` L28 E · `lecture_hall` L34 E · `lake_bridge` L44 E · `grand_library` L48 E · chest: `cafe`, `greenhouse` (R) · `cloister`, `archive_vault` (E) · `sky_library`, `elderwood` (L) · `chronosphere` (M, set `chrono`).
**Frames** (`frame_<id>`): `apprentice` (starter) · `margin_notes` L2 C · `bookworm` L7 C · `silver_quill` L12 R · `constellation` L26 E · `spellwire` L38 E · chest: `alchemist_glass`, `runestone` (R) · `amethyst_bloom`, `lunar_moth`, `wyrmscale` (E) · `sunscholar`, `elfwarden` (L) · `chronomancer` (M, set `chrono`) · `unbroken` (special, 60-day streak).
**Gear**: L5 `gear_weapon_apprentice_wand` C · L10 `gear_armour_patched_jacket` C · L15 `gear_accessory_focus_lens` R · L20 `gear_weapon_ink_nib_dagger` R · L25 `gear_armour_scholar_coat` R · L30 `gear_accessory_starlit_headphones` E · L35 `gear_weapon_arcane_grimoire` E · L40 `gear_armour_moonweave_cloak` E · L45 `gear_accessory_deep_focus` L (`deep_focus`) · L50 `gear_weapon_deadline_breaker` L (`boss_slayer`).
**Badges** (`badge_<id>`): `deep_worker`, `boss_hunter`, `team_player`, `unbroken`, `balanced`, `early_bird`, `steady_pace`, `punctual`.
**Titles** (`title_<id>`): `freshly_awakened` L3 · `adept` L25 · `deadline_slayer` L32 · `archmage` L46 · `fully_awakened` L50 · one per Tier III badge (title = badge name; `unbroken` also comes from the 100-day streak) · 10× raid MVP (**name TBD, DECISION D9**).
**Consumables** (`consumable_<id>`): `streak_shield`, `focus_potion`, `reschedule_scroll`, `free_chest`.

**Level rewards** (`level_rewards`):

| L | Reward | L | Reward | L | Reward |
|---|---|---|---|---|---|
| 2 | frame `margin_notes` | 19 | 150 coins | 36 | skin `starweaver` |
| 3 | title `freshly_awakened` | 20 | gear weapon `ink_nib_dagger` | 37 | 200 coins |
| 4 | skin `coder` | 21 | 150 coins | 38 | frame `spellwire` |
| 5 | gear weapon `apprentice_wand` | 22 | bg `running_track` | 39 | 200 coins |
| 6 | bg `quad` | 23 | 150 coins | 40 | gear armour `moonweave_cloak` |
| 7 | frame `bookworm` | 24 | skin `sigil_runner` | 41 | 300 coins |
| 8 | bg `study_room` | 25 | gear armour `scholar_coat` + title `adept` | 42 | 300 coins |
| 9 | 150 coins | 26 | frame `constellation` | 43 | 300 coins |
| 10 | gear armour `patched_jacket` | 27 | 200 coins | 44 | bg `lake_bridge` |
| 11 | 150 coins | 28 | bg `observatory` | 45 | gear accessory `deep_focus` |
| 12 | frame `silver_quill` | 29 | 200 coins | 46 | title `archmage` |
| 13 | 150 coins | 30 | gear accessory `starlit_headphones` | 47 | 300 coins |
| 14 | skin `alchemist` | 31 | 200 coins | 48 | bg `grand_library` |
| 15 | gear accessory `focus_lens` | 32 | title `deadline_slayer` | 49 | 300 coins |
| 16 | 150 coins | 33 | 200 coins | 50 | gear weapon `deadline_breaker` + skin `awakened` + title `fully_awakened` |
| 17 | 150 coins | 34 | bg `lecture_hall` | | |
| 18 | bg `chem_lab` | 35 | gear weapon `arcane_grimoire` | | |

---

## 10. Game logic (pure modules in `supabase/functions/_shared/game/`)

Rounding: compute in floats, round half up once per output value.

### 10.1 `xp.ts`
```
mult = difficulty_multipliers[difficulty - 1]
minutes:
  focus:    min(verified, 1.5 × est)
  activity: min(actual,   1.0 × est)
  tick:     est
  then (focus/activity): min(minutes, max(0, 480 − focus_minutes_today))
share   = focus 1.0 | activity 0.8 | tick 0.5
timing  = onTime ? 1.10 : late ? max(0.5, 1 − 0.10 × overdueDays) : 1.0     // dated tasks only; days by 4 a.m. day keys
resched = rescheduled && !scroll_used ? 0.80 : 1.0
raw     = round(minutes × mult × share × timing × resched)
boost   = min(0.25, Σ gear boosts attuned to the task stat) + (deepFocus && mode = focus && minutes ≥ 45 ? 0.10 : 0)
special = comeback_armed ? 2.0 : (potion && minutes ≥ 25 ? 1.5 : 1.0)      // DECISION D3: don't stack
final   = round(raw × (1 + boost) × special)
```
Tests (must pass): d4 / 60 est / 60 verified / on time → raw **86**; ticked → **39**; d3 / 30 est / 90 verified focus → capped 45 → **45**; activity d2 / 40 est / 60 actual → **24**; late 3 days d3 / 60 → **42**; late 8 days → floor → **30**.

### 10.2 `rewards.ts` (levels)
```
xpForLevel(L)    = round10(80 + 5.5 × (L − 2)^1.4)     // XP to go from L−1 to L, L ≥ 2
totalForLevel(L) = Σ_{k=2..L} xpForLevel(k)
levelFromXp(xp)  = max L ≤ 50 with totalForLevel(L) ≤ xp
```
Tests: totals L2 80 · L5 370 · L10 1,110 · L15 2,310 · L20 4,040 · L25 6,390 · L30 9,420 · L35 13,170 · L40 17,730 · L45 23,110 · L50 29,360. Multi-level jumps grant every level's reward in order.

### 10.3 `combat.ts`
```
bossTier(hours): < 4 minion, < 12 brute, < 25 warlord, else titan
maxHp = round(hours × 60)                     // raid: per_person_minutes × participants
damage(session) = mode == 'focus' ? round(minutesCounted × (bossSlayer ? 1.2 : 1.0)) : 0     // DECISION D4
heal(boss, closedDay): if status = 'active' and last_work_day <> closedDay and not rest day and not paused:
                         damage = max(0, damage − round(0.03 × maxHp))
soloLoot(ratio) = ratio ≥ 0.75 ? full : half; coins = tierCoins × (full ? 1 : 0.5), within weekly cap and coins_eligible
raidResult = damage ≥ maxHp before deadline ? victory : ratio ≥ 0.75 ? narrow_win : escaped
metFairShare(member) = damage ≥ 0.5 × maxHp / participants
raidLoot(member) = metFairShare ? (victory ? coins × 1.25 : narrow ? coins × 0.5 : 0) : 0
raidPenalty(member) = escaped && !metFairShare ? −100 (floor 0) : 0
mvp = top damage; 30% roll on special_item_pool
```
"Staggered" when HP reaches 0 before a solo boss is submitted; a staggered boss doesn't heal (**DECISION D5**).

### 10.4 `loot.ts` (chest)
```
pity = chests_since_legendary + 1
rarity = pity ≥ 30 ? 'legendary' : weighted(rates)
chests_since_legendary = rarity == 'legendary' ? 0 : pity
common    → pouch weighted(50/100/200/500)
rare      → 50%: unowned rare cosmetic; else (or none left) consumable weighted; at hold limit → 100 coins
epic/leg  → unowned item of that rarity; all owned → refund (200 / 400)
mythic    → whole set (skin + background + frame) if not owned; else 500 refund
```
Injectable RNG so tests and demo mode can force results.

### 10.5 `streaks.ts`
```
closeDay(D):
  if raw_xp(D) ≥ 40:                          count += 1; last_counted_day = D; best = max(best, count)
  elif D is the rest day or paused:           no change
  elif shields > 0 and last_shield_day ≠ D−1: shields −= 1; last_shield_day = D
  else:                                       count = 0
  milestones 7/14/30/60/100 paid once per account (DECISION D6)
```

### 10.6 `time.ts`
Day key from a timestamp + IANA timezone with the 4 a.m. boundary (`Intl.DateTimeFormat` works in Deno); `weekId` from `LEADERBOARD_TZ`. Tests across 03:59/04:00, midnight and DST zones.

### 10.7 Weekly leaderboard rewards
For each user U with ≥ 4 active friends (raw XP > 0 this week) and weekly raw XP ≥ 500: rank U among {U + friends}; top 3 get 300/200/150 coins + special item roll (50/30/20%). Each user is ranked within **their own** friend group. Ties: earlier `updated_at` wins.

### 10.8 `achievements.ts`
Thresholds from `01-PRD.md` §6.13. Tier up → coins 50/100/200; Tier III adds the title; feed `badge`. Early Bird = session started before 08:00 local (after 4 a.m.). Balanced and Steady Pace are evaluated in `cron-weekly`.

---

## 11. AI response schemas (exact)

Prompts and few-shots copied verbatim from `00-PROJECT-OVERVIEW.md` §23 into `_shared/ai/prompts.ts`. These schemas go to Groq as `response_format: { type: 'json_schema', json_schema: { name, strict: true, schema } }` (`02-TRD.md` §7). Strict mode needs every property required and `additionalProperties: false`; numeric ranges are enforced by the zod clamp, not the schema.
```ts
// name: 'task_judgement' — task judge + challenge
{ type: 'object', additionalProperties: false,
  properties: {
    stat: { type: 'string', enum: ['intellect','vitality','craft','charisma'] },
    difficulty: { type: 'integer' },          // clamp 1–5
    estimated_minutes: { type: 'integer' },   // clamp 5–180
    too_big: { type: 'boolean' },
    reason: { type: 'string' } },             // truncate to 20 words
  required: ['stat','difficulty','estimated_minutes','too_big','reason'] }
// name: 'boss_estimate'
{ type: 'object', additionalProperties: false,
  properties: {
    boss_name: { type: 'string' },            // 2–4 words else "The Deadline Shade"
    total_hours: { type: 'number' },          // clamp 2–40
    per_person_hours: { type: 'number' },     // clamp 2–40
    reason: { type: 'string' } },
  required: ['boss_name','total_hours','per_person_hours','reason'] }
```
Always re-validate with zod and clamp (difficulty 1–5, minutes 5–180, hours 2–40, reason ≤ 20 words, boss name 2–4 words else "The Deadline Shade"). Invalid output → next model / backup / provisional (`02-TRD.md` §7.2).

---

## 12. Account deletion

`account/deleteAccount` → `auth.admin.deleteUser`. Every user table cascades from `auth.users`. Leftovers handled in the same action before deletion: leave guilds (pass leadership), mark raid memberships left, remove the user's uuid from other users' friendship rows (cascade does this) and from `activity_events.visible_to` arrays.

---

## 13. Decisions the docs left open (proposed defaults — confirm at kickoff)

| ID | Question | Proposed default |
|---|---|---|
| D1 | What does a **broken** focus session earn? | Verified minutes up to the moment the user left count at full focus rate; no Deep Focus bonus |
| D2 | Minimum session length outside onboarding? | 5 verified minutes; shorter sessions earn nothing |
| D3 | Do Focus Potion and comeback stack? | No. Comeback (2×) wins; the potion stays armed |
| D4 | Does **activity mode** damage bosses? | No: only focus minutes deal damage |
| D5 | Does a staggered boss heal? | No |
| D6 | Streak milestones paid every time? | Once per account |
| D7 | "Guild members are always friends" — how? | Joining requires friendship with the leader and auto-befriends all members |
| D8 | Guild weekly quest coins per contributor | 100 coins |
| D9 | Name of the 10× raid MVP title | Team to name (placeholder `title_raid_champion`) |
| D10 | Raid tier for loot coins uses which hours? | Per-person hours |
| D11 | Ticker shows per-hit amounts to all members, so totals can be inferred | Accept; exact totals still only for the creator |
| D12 | Do tasks need a due date? | Optional; timing modifiers apply only to dated tasks |
| D13 | Stat change after completion | Not allowed |
| D14 | How is the username chosen? (not in onboarding) | Generated from the display name + 4 digits; editable later in Settings if time allows |
| D15 | Email confirmation | Off for the course build |
