import { z } from "zod";

import { AiExhaustedError, getProvider, type AiProvider } from "./ai/index.ts";
import { requestBossEstimate } from "./ai/judge.ts";
import { loadConfig, type GameConfig } from "./config.ts";
import { coinsEligibleAt, dueInDays } from "./create_boss.ts";
import { getSql, type Sql } from "./db.ts";
import { AppError, invalidArgument, notFound } from "./errors.ts";
import { bossTier, raidMaxHp } from "./game/combat.ts";
import { friendCode } from "./onboarding.ts";

const createSchema = z.object({
  source: z.enum(["guild", "party"]),
  guildId: z.string().uuid().optional(),
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().max(1000).nullish(),
  type: z.enum(["exam", "assignment", "project"]),
  deadline: z.string().datetime({ offset: true }),
  participants: z.number().int().min(2).max(8),
  perPersonHours: z.number().min(2).max(40).optional(),
  name: z.string().trim().min(1).max(80).optional(),
  dryRun: z.boolean(),
}).superRefine((value, ctx) => {
  if (value.source === "guild" && !value.guildId) {
    ctx.addIssue({ code: "custom", message: "guildId is required for a guild fight", path: ["guildId"] });
  }
  if (value.source === "party" && value.guildId) {
    ctx.addIssue({ code: "custom", message: "party raids cannot set guildId", path: ["guildId"] });
  }
  if (!value.dryRun && value.perPersonHours == null) {
    ctx.addIssue({
      code: "custom",
      message: "perPersonHours is required to create a raid",
      path: ["perPersonHours"],
    });
  }
});

const joinSchema = z.union([
  z.object({ code: z.string().trim().min(6).max(12) }),
  z.object({ raidId: z.string().uuid() }),
]);

const leaveSchema = z.object({
  raidId: z.string().uuid(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface RaidPreview {
  name: string;
  title: string;
  type: "exam" | "assignment" | "project";
  source: "guild" | "party";
  participants: number;
  perPersonHours: number;
  tier: string;
  maxHp: number;
  coinsEligible: boolean;
  defeatCoins: number;
  reason: string;
  deadline: string;
}

export interface CreatedRaid {
  id: string;
  source: string;
  guildId: string | null;
  name: string;
  title: string;
  type: string;
  tier: string;
  perPersonMinutes: number;
  participants: number;
  maxHp: number;
  damage: number;
  deadline: string;
  status: string;
  inviteCode: string | null;
  coinsEligible: boolean;
}

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function clampHours(hours: number, config: GameConfig): number {
  const min = numberFrom(config.boss_hours_min, 2);
  const max = numberFrom(config.boss_hours_max, 40);
  return Math.min(max, Math.max(min, hours));
}

async function countActiveFights(userId: string, tx: Tx): Promise<number> {
  const solo = await tx`
    select count(*)::int as n from bosses
    where user_id = ${userId} and status in ('active', 'staggered')
  `;
  const raids = await tx`
    select count(*)::int as n
    from raid_members rm
    join raids r on r.id = rm.raid_id
    where rm.user_id = ${userId} and rm.left_raid = false and r.status = 'active'
  `;
  return numberFrom(solo[0]?.n, 0) + numberFrom(raids[0]?.n, 0);
}

async function profileSnapshot(userId: string, tx: Tx): Promise<{
  display_name: string;
  skin_id: string | null;
  frame_id: string | null;
  body_type: string | null;
  title_id: string | null;
}> {
  const rows = await tx`
    select display_name, equipped_skin_id, equipped_frame_id, body_type, title_id
    from profiles where id = ${userId}
  `;
  const row = rows[0];
  if (!row) throw invalidArgument("Profile missing");
  return {
    display_name: String(row.display_name),
    skin_id: row.equipped_skin_id == null ? null : String(row.equipped_skin_id),
    frame_id: row.equipped_frame_id == null ? null : String(row.equipped_frame_id),
    body_type: row.body_type == null ? null : String(row.body_type),
    title_id: row.title_id == null ? null : String(row.title_id),
  };
}

async function addMember(raidId: string, userId: string, tx: Tx): Promise<void> {
  const profile = await profileSnapshot(userId, tx);
  await tx`
    insert into raid_members (
      raid_id, user_id, display_name, skin_id, frame_id, body_type, title_id
    ) values (
      ${raidId}, ${userId}, ${profile.display_name}, ${profile.skin_id},
      ${profile.frame_id}, ${profile.body_type}, ${profile.title_id}
    )
    on conflict (raid_id, user_id) do update
      set left_raid = false,
          display_name = excluded.display_name,
          skin_id = excluded.skin_id,
          frame_id = excluded.frame_id,
          body_type = excluded.body_type,
          title_id = excluded.title_id
  `;
  await tx`
    insert into raid_damage (raid_id, user_id, damage)
    values (${raidId}, ${userId}, 0)
    on conflict (raid_id, user_id) do nothing
  `;
}

function raidFromRow(row: Record<string, unknown>): CreatedRaid {
  return {
    id: String(row.id),
    source: String(row.source),
    guildId: row.guild_id == null ? null : String(row.guild_id),
    name: String(row.name),
    title: String(row.title),
    type: String(row.type),
    tier: String(row.tier),
    perPersonMinutes: numberFrom(row.per_person_minutes, 0),
    participants: numberFrom(row.participants, 0),
    maxHp: numberFrom(row.max_hp, 0),
    damage: numberFrom(row.damage, 0),
    deadline: row.deadline instanceof Date ? row.deadline.toISOString() : String(row.deadline),
    status: String(row.status),
    inviteCode: row.invite_code == null ? null : String(row.invite_code),
    coinsEligible: row.coins_eligible === true,
  };
}

export async function createRaidDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  provider: AiProvider,
  config: GameConfig,
  now = new Date(),
): Promise<{ preview: RaidPreview } | { raid: CreatedRaid }> {
  const input = createSchema.parse(body);
  const deadline = new Date(input.deadline);
  if (Number.isNaN(deadline.getTime())) throw invalidArgument("Invalid deadline");
  if (deadline.getTime() <= now.getTime()) throw invalidArgument("Deadline must be in the future");

  const partyMin = numberFrom(config.party_min, 2);
  const partyMax = numberFrom(config.party_max, 8);
  if (input.participants < partyMin || input.participants > partyMax) {
    throw invalidArgument(`Participants must be between ${partyMin} and ${partyMax}`);
  }

  if (input.source === "guild") {
    const membership = await tx`
      select guild_id from guild_members
      where user_id = ${userId} and guild_id = ${input.guildId}
      limit 1
    `;
    if (!membership[0]) throw invalidArgument("You must be in that guild to start a guild fight");
  }

  const limit = numberFrom(config.max_active_fights, 15);
  const active = await countActiveFights(userId, tx);
  if (!input.dryRun && active >= limit) {
    throw invalidArgument(`You already have ${limit} active fights`);
  }

  if (input.dryRun) {
    const calls = await tx`select ai_calls_today from player_state where user_id = ${userId} for update`;
    if (!calls[0]) throw invalidArgument("Player state missing");
    const used = numberFrom(calls[0].ai_calls_today, 0);
    const daily = numberFrom(config.ai_daily_limit, 50);
    if (used >= daily) {
      throw new AppError("unavailable", "AI judge resting until tomorrow", 503);
    }

    const settings = await tx`select study_context from user_settings where user_id = ${userId}`;
    let estimate;
    try {
      estimate = await requestBossEstimate(provider, {
        title: input.title,
        description: input.description ?? null,
        type: input.type,
        dueInDays: dueInDays(deadline, now),
        participants: input.participants,
        studentContext: (settings[0]?.study_context as string | null) ?? null,
      });
    } catch (error) {
      if (error instanceof AiExhaustedError) {
        throw new AppError("unavailable", "Could not estimate this raid right now. Try again.", 503);
      }
      throw error;
    }

    await tx`
      update player_state set ai_calls_today = ai_calls_today + 1
      where user_id = ${userId}
    `;

    const hours = clampHours(estimate.per_person_hours, config);
    const tier = bossTier(hours);
    const minutes = Math.round(hours * 60);
    const minHours = numberFrom(config.boss_min_hours_before_deadline_for_coins, 48);
    return {
      preview: {
        name: estimate.boss_name,
        title: input.title,
        type: input.type,
        source: input.source,
        participants: input.participants,
        perPersonHours: hours,
        tier: tier.tier,
        maxHp: raidMaxHp(minutes, input.participants),
        coinsEligible: coinsEligibleAt(deadline, now, minHours),
        defeatCoins: tier.coins,
        reason: estimate.reason,
        deadline: input.deadline,
      },
    };
  }

  const hours = clampHours(input.perPersonHours!, config);
  const tier = bossTier(hours);
  const minutes = Math.round(hours * 60);
  const hp = raidMaxHp(minutes, input.participants);
  const minHours = numberFrom(config.boss_min_hours_before_deadline_for_coins, 48);
  const eligible = coinsEligibleAt(deadline, now, minHours);
  const rawName = (input.name ?? "").trim();
  const words = rawName.split(/\s+/).filter((word) => word.length > 0);
  const raidName = words.length >= 2 && words.length <= 4 ? words.join(" ") : "The Shared Deadline";

  let inviteCode: string | null = null;
  if (input.source === "party") {
    for (let attempt = 0; attempt < 6; attempt++) {
      inviteCode = friendCode(Math.random);
      const clash = await tx`select 1 from raids where invite_code = ${inviteCode} limit 1`;
      if (clash.length === 0) break;
      if (attempt === 5) throw invalidArgument("Could not allocate an invite code");
    }
  }

  const rows = await tx`
    insert into raids (
      source, guild_id, name, title, type, tier, per_person_minutes, participants,
      max_hp, damage, deadline, status, created_by, invite_code, coins_eligible
    ) values (
      ${input.source},
      ${input.source === "guild" ? input.guildId! : null},
      ${raidName},
      ${input.title},
      ${input.type},
      ${tier.tier},
      ${minutes},
      ${input.participants},
      ${hp},
      0,
      ${input.deadline},
      'active',
      ${userId},
      ${inviteCode},
      ${eligible}
    )
    returning *
  `;
  const row = rows[0];
  if (!row) throw new AppError("internal", "Failed to create raid", 500);
  const raid = raidFromRow(row);
  await addMember(raid.id, userId, tx);

  if (input.source === "guild" && input.guildId) {
    const payload = JSON.stringify({
      raidId: raid.id,
      name: raid.name,
      title: raid.title,
      deadline: raid.deadline,
      createdBy: userId,
    });
    await tx`
      insert into inbox (user_id, type, payload)
      select user_id, 'guild_fight', ${payload}::jsonb
      from guild_members
      where guild_id = ${input.guildId} and user_id <> ${userId}
    `;
  }

  return { raid };
}

export async function joinRaidDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
): Promise<{ raid: CreatedRaid }> {
  const input = joinSchema.parse(body);

  const raids = "code" in input
    ? await tx`
        select * from raids
        where upper(invite_code) = ${input.code.toUpperCase()} and status = 'active'
        limit 1 for update
      `
    : await tx`
        select * from raids where id = ${input.raidId} and status = 'active' limit 1 for update
      `;
  const row = raids[0];
  if (!row) throw notFound("Raid not found");
  const raid = raidFromRow(row);

  if (raid.source === "party" && !("code" in input)) {
    throw invalidArgument("Join a party raid with its invite code");
  }
  if (raid.source === "guild") {
    if (!raid.guildId) throw invalidArgument("Guild fight is missing a guild");
    const membership = await tx`
      select 1 from guild_members
      where guild_id = ${raid.guildId} and user_id = ${userId}
      limit 1
    `;
    if (!membership[0]) throw invalidArgument("Only guild members can join this fight");
  }

  const existing = await tx`
    select left_raid from raid_members
    where raid_id = ${raid.id} and user_id = ${userId}
  `;
  if (existing[0] && existing[0].left_raid === false) {
    return { raid };
  }

  const activeMembers = await tx`
    select count(*)::int as n from raid_members
    where raid_id = ${raid.id} and left_raid = false
  `;
  if (numberFrom(activeMembers[0]?.n, 0) >= raid.participants) {
    throw invalidArgument("This raid is full");
  }

  const limit = numberFrom(config.max_active_fights, 15);
  const active = await countActiveFights(userId, tx);
  if (active >= limit) {
    throw invalidArgument(`You already have ${limit} active fights`);
  }

  await addMember(raid.id, userId, tx);
  return { raid };
}

export async function leaveRaidDraft(
  userId: string,
  body: unknown,
  tx: Tx,
): Promise<{ ok: true }> {
  const input = leaveSchema.parse(body);
  const membership = await tx`
    select left_raid from raid_members
    where raid_id = ${input.raidId} and user_id = ${userId}
    for update
  `;
  if (!membership[0]) throw notFound("You are not in this raid");
  if (membership[0].left_raid === true) return { ok: true };

  await tx`
    update raid_members set left_raid = true
    where raid_id = ${input.raidId} and user_id = ${userId}
  `;
  return { ok: true };
}

export async function createRaid(
  userId: string,
  body: unknown,
  sql: Sql = getSql(),
): Promise<{ preview: RaidPreview } | { raid: CreatedRaid }> {
  const config = await loadConfig();
  const provider = getProvider({ timeoutMs: numberFrom(config.ai_timeout_ms, 10_000) });
  return await sql.begin(async (tx) =>
    createRaidDraft(userId, body, tx as unknown as Tx, provider, config)
  );
}

export async function joinRaid(userId: string, body: unknown, sql: Sql = getSql()) {
  const config = await loadConfig();
  return await sql.begin(async (tx) => joinRaidDraft(userId, body, tx as unknown as Tx, config));
}

export async function leaveRaid(userId: string, body: unknown, sql: Sql = getSql()) {
  return await sql.begin(async (tx) => leaveRaidDraft(userId, body, tx as unknown as Tx));
}
