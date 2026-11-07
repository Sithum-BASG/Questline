// Recreates the Phase 16 demo cohort in one command (plan 16.1 / overview §25).
// Requires catalog + config already loaded (`scripts/seed-cloud.ts`).
//
// Env (never print these):
//   SUPABASE_DB_URL            — direct Postgres connection string
//   SUPABASE_URL               — project URL
//   SUPABASE_SERVICE_ROLE_KEY  — service role for Auth admin
// Optional:
//   DEMO_PASSWORD              — shared password for all demo accounts (default below)
//
// PowerShell:
//   $env:SUPABASE_DB_URL = '<url>'
//   $env:SUPABASE_URL = '<url>'
//   $env:SUPABASE_SERVICE_ROLE_KEY = '<key>'
//   deno run --allow-env --allow-net --allow-read scripts/seed-demo.ts

import { createClient } from "npm:@supabase/supabase-js@2.49.8";
import postgres from "npm:postgres@3.4.5";

import { totalForLevel } from "../supabase/functions/_shared/game/rewards.ts";
import { dayKey, nextRollover, weekId } from "../supabase/functions/_shared/game/time.ts";
import { friendCode, usernameFromDisplayName } from "../supabase/functions/_shared/onboarding.ts";

const DEMO_DOMAIN = "questline.demo";
const TIMEZONE = "Asia/Colombo";
const HERO_LEVEL = 42;
const DEFAULT_PASSWORD = "QuestlineDemo1!";

/** Stable uids so re-runs replace the same rows. */
const IDS = {
  hero: "d1000000-0000-4000-8000-000000000001",
  party: "d1000000-0000-4000-8000-000000000002",
  friends: [
    "d1000000-0000-4000-8000-000000000011",
    "d1000000-0000-4000-8000-000000000012",
    "d1000000-0000-4000-8000-000000000013",
    "d1000000-0000-4000-8000-000000000014",
    "d1000000-0000-4000-8000-000000000015",
    "d1000000-0000-4000-8000-000000000016",
    "d1000000-0000-4000-8000-000000000017",
    "d1000000-0000-4000-8000-000000000018",
    "d1000000-0000-4000-8000-000000000019",
  ],
} as const;

type Account = {
  id: string;
  email: string;
  displayName: string;
  bodyType: "a" | "b";
  level: number;
  weeklyXp: number;
  role: "hero" | "party" | "friend";
};

const FRIEND_WEEKLY = [180, 320, 450, 520, 610, 740, 880, 1020, 1250];

function accounts(): Account[] {
  const friends: Account[] = IDS.friends.map((id, index) => ({
    id,
    email: `friend${index + 1}@${DEMO_DOMAIN}`,
    displayName: [
      "Asha",
      "Nimal",
      "Priya",
      "Kasun",
      "Maya",
      "Ravi",
      "Anika",
      "Dilshan",
      "Sera",
    ][index]!,
    bodyType: index % 2 === 0 ? "a" : "b",
    level: 8 + index * 3,
    weeklyXp: FRIEND_WEEKLY[index]!,
    role: "friend",
  }));
  return [
    {
      id: IDS.hero,
      email: `hero@${DEMO_DOMAIN}`,
      displayName: "Hero",
      bodyType: "a",
      level: HERO_LEVEL,
      weeklyXp: 920,
      role: "hero",
    },
    {
      id: IDS.party,
      email: `party@${DEMO_DOMAIN}`,
      displayName: "Raid Mate",
      bodyType: "b",
      level: 28,
      weeklyXp: 640,
      role: "party",
    },
    ...friends,
  ];
}

const HERO_LEVEL_ITEMS = [
  "skin_starter",
  "bg_starter",
  "frame_apprentice",
  "frame_margin_notes",
  "skin_coder",
  "gear_weapon_apprentice_wand",
  "bg_quad",
  "frame_bookworm",
  "bg_study_room",
  "gear_armour_patched_jacket",
  "frame_silver_quill",
  "skin_alchemist",
  "gear_accessory_focus_lens",
  "bg_chem_lab",
  "gear_weapon_ink_nib_dagger",
  "bg_running_track",
  "skin_sigil_runner",
  "gear_armour_scholar_coat",
  "frame_constellation",
  "bg_observatory",
  "gear_accessory_starlit_headphones",
  "bg_lecture_hall",
  "gear_weapon_arcane_grimoire",
  "skin_starweaver",
  "frame_spellwire",
] as const;

/** Legendary + epic cosmetics for the stage look (true legendary gear unlocks at 45/50). */
const HERO_CHEST_ITEMS = [
  "skin_sunscholar",
  "skin_elfwarden",
  "bg_sky_library",
  "bg_elderwood",
  "bg_cafe",
  "bg_cloister",
  "frame_sunscholar",
  "frame_elfwarden",
  "frame_amethyst_bloom",
  "frame_unbroken",
] as const;

const HERO_BADGES: { id: string; progress: number; tier: number }[] = [
  { id: "badge_deep_worker", progress: 220, tier: 3 },
  { id: "badge_boss_hunter", progress: 18, tier: 2 },
  { id: "badge_team_player", progress: 12, tier: 2 },
  { id: "badge_unbroken", progress: 45, tier: 2 },
  { id: "badge_balanced", progress: 8, tier: 2 },
  { id: "badge_early_bird", progress: 40, tier: 2 },
  { id: "badge_steady_pace", progress: 10, tier: 2 },
  { id: "badge_punctual", progress: 35, tier: 2 },
];

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    console.error(`${name} is not set`);
    Deno.exit(1);
  }
  return value;
}

function isoDayOffset(base: Date, daysBack: number): string {
  const d = new Date(base.getTime() - daysBack * 86_400_000);
  return d.toISOString().slice(0, 10);
}

type AdminClient = {
  auth: { admin: { deleteUser: (id: string) => Promise<{ error: { message: string } | null }> } };
};

type Sql = ReturnType<typeof postgres>;

async function wipeDemoUsers(admin: AdminClient, sql: Sql): Promise<void> {
  const rows = await sql<{ id: string; email: string }[]>`
    select id::text as id, email
    from auth.users
    where email like ${`%@${DEMO_DOMAIN}`}
       or id = any (${sql.array(Object.values(IDS).flatMap((v) => Array.isArray(v) ? v : [v]))}::uuid[])
  `;
  for (const row of rows) {
    const { error } = await admin.auth.admin.deleteUser(row.id);
    if (error) {
      // Fall back to SQL if Auth admin rejects a stale row.
      await sql`delete from auth.users where id = ${row.id}::uuid`;
    }
  }
}

async function createAuthUsers(
  admin: {
    auth: {
      admin: {
        createUser: (attrs: Record<string, unknown>) => Promise<{ error: { message: string } | null }>;
      };
    };
  },
  cohort: Account[],
  password: string,
): Promise<void> {
  for (const account of cohort) {
    const { error } = await admin.auth.admin.createUser({
      id: account.id,
      email: account.email,
      password,
      email_confirm: true,
      user_metadata: { display_name: account.displayName },
    });
    if (error) throw new Error(`createUser ${account.email}: ${error.message}`);
  }
}

async function seedSql(
  sql: Sql,
  cohort: Account[],
): Promise<{ guildInvite: string; raidInvite: string; heroFriendCode: string }> {
  const now = new Date();
  const week = weekId(now, TIMEZONE);
  const heroXp = totalForLevel(HERO_LEVEL);
  const rollover = nextRollover(now, TIMEZONE).toISOString();
  const todayKey = dayKey(now, TIMEZONE);
  const guildId = "d2000000-0000-4000-8000-000000000001";
  const raidId = "d3000000-0000-4000-8000-000000000001";
  const guildInvite = "DEMOGUILD";
  const raidInvite = "DEMORAID1";
  let heroFriendCode = "";

  await sql.begin(async (tx) => {
    for (const account of cohort) {
      const digits = account.id.slice(-4);
      const username = usernameFromDisplayName(account.displayName, digits);
      // Mulberry32 seeded from the account id so friend codes stay stable across re-runs.
      let seed = Number.parseInt(account.id.replace(/\D/g, "").slice(-8), 10) || 1;
      const code = friendCode(() => {
        seed |= 0;
        seed = (seed + 0x6d2b79f5) | 0;
        let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
      });
      if (account.role === "hero") heroFriendCode = code;

      const xp = account.role === "hero" ? heroXp : totalForLevel(account.level);
      const titles = account.role === "hero"
        ? ["title_freshly_awakened", "title_adept", "title_deadline_slayer", "title_deep_worker"]
        : account.level >= 25
        ? ["title_freshly_awakened", "title_adept"]
        : account.level >= 3
        ? ["title_freshly_awakened"]
        : [];

      await tx`
        insert into player_state (
          user_id, coins, xp_total, weekly_raw_xp, week_id,
          streak_count, streak_best, streak_last_counted_day,
          potions, scrolls, free_chests, chests_since_legendary,
          onboarding_step, onboarding_bonus, owned_titles, counters,
          milestones_paid, timezone, last_active_day, next_rollover_at
        ) values (
          ${account.id}::uuid,
          ${account.role === "hero" ? 2400 : 400 + account.weeklyXp},
          ${xp},
          ${account.weeklyXp},
          ${week},
          ${account.role === "hero" ? 32 : 5 + (account.weeklyXp % 10)},
          ${account.role === "hero" ? 40 : 12},
          ${todayKey}::date,
          ${account.role === "hero" ? 3 : 1},
          ${account.role === "hero" ? 2 : 0},
          ${account.role === "hero" ? 2 : 0},
          ${account.role === "hero" ? 4 : 0},
          'done',
          ${tx.json({ character: true, first_task: true, first_session: true })},
          ${tx.array(titles)},
          ${tx.json({
            focus_minutes: account.role === "hero" ? 18_000 : 600 + account.weeklyXp,
            bosses_defeated: account.role === "hero" ? 14 : 1,
            raids_won: account.role === "hero" ? 6 : 0,
            raid_mvps: account.role === "hero" ? 2 : 0,
            balanced_weeks: account.role === "hero" ? 8 : 0,
            early_bird_sessions: account.role === "hero" ? 40 : 2,
            steady_pace_weeks: account.role === "hero" ? 10 : 0,
            punctual_tasks: account.role === "hero" ? 35 : 3,
          })},
          ${tx.array(account.role === "hero" ? [7, 14, 30] : [7])},
          ${TIMEZONE},
          ${todayKey}::date,
          ${rollover}
        )
      `;

      await tx`
        insert into user_settings (user_id, demo_mode, study_context)
        values (
          ${account.id}::uuid,
          ${account.role === "hero" || account.role === "party"},
          ${account.role === "hero" ? "Final-year CS, viva in two weeks" : null}
        )
      `;

      const skin = account.role === "hero"
        ? "skin_sunscholar"
        : account.level >= 24
        ? "skin_sigil_runner"
        : account.level >= 14
        ? "skin_alchemist"
        : account.level >= 4
        ? "skin_coder"
        : "skin_starter";
      const bg = account.role === "hero"
        ? "bg_sky_library"
        : account.level >= 28
        ? "bg_observatory"
        : "bg_starter";
      const frame = account.role === "hero"
        ? "frame_sunscholar"
        : account.level >= 26
        ? "frame_constellation"
        : "frame_apprentice";
      const titleId = titles.includes("title_deadline_slayer")
        ? "title_deadline_slayer"
        : titles.includes("title_adept")
        ? "title_adept"
        : titles.includes("title_freshly_awakened")
        ? "title_freshly_awakened"
        : null;

      await tx`
        insert into profiles (
          id, username, friend_code, display_name, body_type, level, title_id,
          equipped_skin_id, equipped_background_id, equipped_frame_id, pinned_badges
        ) values (
          ${account.id}::uuid,
          ${username},
          ${code},
          ${account.displayName},
          ${account.bodyType},
          ${account.level},
          ${titleId},
          ${skin},
          ${bg},
          ${frame},
          ${tx.array(
            account.role === "hero"
              ? ["badge_deep_worker", "badge_boss_hunter", "badge_unbroken"]
              : [],
          )}
        )
      `;

      await tx`insert into presence (user_id) values (${account.id}::uuid)`;
      await tx`
        insert into friend_summaries (user_id, weekly_raw_xp, equipped_gear)
        values (
          ${account.id}::uuid,
          ${account.weeklyXp},
          ${tx.json(
            account.role === "hero"
              ? [
                { slot: "weapon", catalogId: "gear_weapon_arcane_grimoire", attunedStat: "intellect" },
                { slot: "armour", catalogId: "gear_armour_moonweave_cloak", attunedStat: "craft" },
                { slot: "accessory", catalogId: "gear_accessory_starlit_headphones", attunedStat: "intellect" },
              ]
              : [],
          )}
        )
      `;

      await tx`
        insert into weekly_scores (week_id, user_id, raw_xp, updated_at)
        values (${week}, ${account.id}::uuid, ${account.weeklyXp}, ${now.toISOString()})
      `;

      // Starter cosmetics so every friend can sign in without empty wardrobe.
      await tx`
        insert into inventory (user_id, catalog_id, source) values
          (${account.id}::uuid, 'skin_starter', 'starter'),
          (${account.id}::uuid, 'bg_starter', 'starter'),
          (${account.id}::uuid, 'frame_apprentice', 'starter')
        on conflict do nothing
      `;
    }

    // Hero loadout: level gear through 42 + legendary cosmetics, epic set equipped.
    for (const catalogId of HERO_LEVEL_ITEMS) {
      await tx`
        insert into inventory (user_id, catalog_id, source)
        values (${IDS.hero}::uuid, ${catalogId}, 'level')
        on conflict do nothing
      `;
    }
    for (const catalogId of HERO_CHEST_ITEMS) {
      await tx`
        insert into inventory (user_id, catalog_id, source)
        values (${IDS.hero}::uuid, ${catalogId}, 'chest')
        on conflict do nothing
      `;
    }
    await tx`
      update inventory set equipped_slot = 'weapon', attuned_stat = 'intellect'
      where user_id = ${IDS.hero}::uuid and catalog_id = 'gear_weapon_arcane_grimoire'
    `;
    await tx`
      update inventory set equipped_slot = 'armour', attuned_stat = 'craft'
      where user_id = ${IDS.hero}::uuid and catalog_id = 'gear_armour_moonweave_cloak'
    `;
    await tx`
      update inventory set equipped_slot = 'accessory', attuned_stat = 'intellect'
      where user_id = ${IDS.hero}::uuid and catalog_id = 'gear_accessory_starlit_headphones'
    `;

    for (const badge of HERO_BADGES) {
      await tx`
        insert into achievements (user_id, badge_id, progress, tier)
        values (${IDS.hero}::uuid, ${badge.id}, ${badge.progress}, ${badge.tier})
      `;
    }

    // 60 days of daily_stats for the hero radar / history.
    for (let i = 0; i < 60; i++) {
      const day = isoDayOffset(now, i);
      const intellect = 20 + (i % 7) * 8;
      const vitality = 10 + (i % 5) * 6;
      const craft = 12 + (i % 6) * 5;
      const charisma = 8 + (i % 4) * 7;
      const raw = intellect + vitality + craft + charisma;
      await tx`
        insert into daily_stats (
          user_id, day, xp_intellect, xp_vitality, xp_craft, xp_charisma,
          raw_xp, focus_minutes, sessions_started, met_minimum
        ) values (
          ${IDS.hero}::uuid, ${day}::date,
          ${intellect}, ${vitality}, ${craft}, ${charisma},
          ${raw}, ${40 + (i % 9) * 10}, ${1 + (i % 3)}, ${raw >= 40}
        )
      `;
    }

    // Bidirectional friendships: hero ↔ everyone else; party ↔ a few friends.
    const others = cohort.filter((a) => a.role !== "hero");
    for (const friend of others) {
      await tx`
        insert into friendships (user_id, friend_id, status) values
          (${IDS.hero}::uuid, ${friend.id}::uuid, 'accepted'),
          (${friend.id}::uuid, ${IDS.hero}::uuid, 'accepted')
      `;
    }
    for (const friend of cohort.filter((a) => a.role === "friend").slice(0, 4)) {
      await tx`
        insert into friendships (user_id, friend_id, status) values
          (${IDS.party}::uuid, ${friend.id}::uuid, 'accepted'),
          (${friend.id}::uuid, ${IDS.party}::uuid, 'accepted')
        on conflict do nothing
      `;
    }

    // Guild: hero leads, party + three friends join.
    const guildMemberIds = [IDS.hero, IDS.party, ...IDS.friends.slice(0, 3)];
    await tx`
      insert into guilds (id, name, emblem, leader_id, invite_code, quest_week_id, quest_goal, quest_progress)
      values (
        ${guildId}::uuid,
        'Demo Guild',
        'crest_3',
        ${IDS.hero}::uuid,
        ${guildInvite},
        ${week},
        5000,
        2100
      )
    `;
    for (const memberId of guildMemberIds) {
      await tx`
        insert into guild_members (guild_id, user_id, quest_contribution)
        values (
          ${guildId}::uuid,
          ${memberId}::uuid,
          ${memberId === IDS.hero ? 900 : 300}
        )
      `;
      await tx`update profiles set guild_id = ${guildId}::uuid where id = ${memberId}::uuid`;
    }

    // Party raid due in 4 days (coins eligible — more than 48 h out).
    const deadline = new Date(now.getTime() + 4 * 86_400_000).toISOString();
    const perPerson = 120;
    const participants = 3;
    const maxHp = perPerson * participants;
    const raidMembers = [IDS.hero, IDS.party, IDS.friends[0]!];
    await tx`
      insert into raids (
        id, source, name, title, type, tier, per_person_minutes, participants,
        max_hp, damage, deadline, status, created_by, invite_code, coins_eligible
      ) values (
        ${raidId}::uuid,
        'party',
        'The Shared Deadline',
        'Group project viva prep',
        'project',
        'brute',
        ${perPerson},
        ${participants},
        ${maxHp},
        40,
        ${deadline},
        'active',
        ${IDS.hero}::uuid,
        ${raidInvite},
        true
      )
    `;
    for (const memberId of raidMembers) {
      const [profile] = await tx<{
        display_name: string;
        equipped_skin_id: string;
        equipped_frame_id: string;
        body_type: string;
        title_id: string | null;
      }[]>`
        select display_name, equipped_skin_id, equipped_frame_id, body_type, title_id
        from profiles where id = ${memberId}::uuid
      `;
      await tx`
        insert into raid_members (
          raid_id, user_id, display_name, skin_id, frame_id, body_type, title_id
        ) values (
          ${raidId}::uuid,
          ${memberId}::uuid,
          ${profile.display_name},
          ${profile.equipped_skin_id},
          ${profile.equipped_frame_id},
          ${profile.body_type},
          ${profile.title_id}
        )
      `;
      await tx`
        insert into raid_damage (raid_id, user_id, damage)
        values (${raidId}::uuid, ${memberId}::uuid, ${memberId === IDS.hero ? 40 : 0})
      `;
    }

    // Pre-judged backup task if Groq is down during the demo.
    await tx`
      insert into tasks (
        user_id, title, notes, due_at, original_due_at, status,
        stat, difficulty, est_minutes, too_big, reason, provisional, judged_at, raid_id
      ) values (
        ${IDS.hero}::uuid,
        'Polish viva slides',
        'Backup demo task — already judged so focus works offline from Groq.',
        ${deadline},
        ${deadline},
        'open',
        'intellect',
        4,
        45,
        false,
        'Slide polish with speaker notes for a graded viva.',
        false,
        ${now.toISOString()},
        ${raidId}::uuid
      )
    `;

    // Solo boss for the Home card — deadline 3+ days, coins eligible.
    const bossDeadline = new Date(now.getTime() + 3 * 86_400_000).toISOString();
    const bossHours = 3;
    const bossHp = bossHours * 60;
    const [boss] = await tx<{ id: string }[]>`
      insert into bosses (
        user_id, name, title, type, tier, hours, max_hp, damage,
        deadline, status, coins_eligible
      ) values (
        ${IDS.hero}::uuid,
        'Viva Titan',
        'End-of-semester viva',
        'exam',
        'minion',
        ${bossHours},
        ${bossHp},
        35,
        ${bossDeadline},
        'active',
        true
      )
      returning id
    `;
    await tx`
      insert into tasks (
        user_id, title, notes, due_at, original_due_at, status, boss_id,
        stat, difficulty, est_minutes, too_big, reason, provisional, judged_at
      ) values (
        ${IDS.hero}::uuid,
        'Rehearse viva answers',
        'Linked to the demo boss.',
        ${bossDeadline},
        ${bossDeadline},
        'open',
        ${boss.id}::uuid,
        'charisma',
        3,
        60,
        false,
        'Spoken practice for a viva panel.',
        false,
        ${now.toISOString()}
      )
    `;

    await tx`
      insert into demo_allowlist (user_id) values
        (${IDS.hero}::uuid),
        (${IDS.party}::uuid)
      on conflict do nothing
    `;
  });

  return { guildInvite, raidInvite, heroFriendCode };
}

const dbUrl = requireEnv("SUPABASE_DB_URL");
const supabaseUrl = requireEnv("SUPABASE_URL");
const serviceKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
const password = Deno.env.get("DEMO_PASSWORD") ?? DEFAULT_PASSWORD;

const cohort = accounts();
const admin = createClient(supabaseUrl, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});
const sql = postgres(dbUrl, { prepare: false });

try {
  const [catalog] = await sql<{ n: number }[]>`select count(*)::int as n from catalog_items`;
  if (!catalog || catalog.n < 50) {
    console.error("catalog_items looks empty — run scripts/seed-cloud.ts first");
    Deno.exit(1);
  }

  console.log("Wiping previous @questline.demo users…");
  await wipeDemoUsers(admin, sql);

  console.log(`Creating ${cohort.length} Auth users…`);
  await createAuthUsers(admin, cohort, password);

  console.log("Seeding profiles, guild, raid, tasks…");
  const { guildInvite, raidInvite, heroFriendCode } = await seedSql(sql, cohort);

  console.log("");
  console.log("Demo seed ready.");
  console.log(`  Hero (Phone B):  hero@${DEMO_DOMAIN}  /  ${password}`);
  console.log(`  Party (Phone C): party@${DEMO_DOMAIN} /  ${password}`);
  console.log(`  Friends:         friend1..9@${DEMO_DOMAIN}`);
  console.log(`  Hero friend code: ${heroFriendCode}`);
  console.log(`  Guild invite:     ${guildInvite}`);
  console.log(`  Raid invite:      ${raidInvite}`);
  console.log(`  Hero level:       ${HERO_LEVEL} (xp_total=${totalForLevel(HERO_LEVEL)})`);
  console.log("  demo_allowlist:   hero + party (demo_mode on)");
} finally {
  await sql.end();
}
