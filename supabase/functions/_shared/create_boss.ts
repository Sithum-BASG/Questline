import { z } from "zod";

import { AiExhaustedError, getProvider, type AiProvider } from "./ai/index.ts";
import { requestBossEstimate } from "./ai/judge.ts";
import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { AppError, invalidArgument } from "./errors.ts";
import { bossTier, maxHp } from "./game/combat.ts";

const inputSchema = z.object({
  title: z.string().trim().min(1).max(200),
  description: z.string().trim().max(1000).nullish(),
  type: z.enum(["exam", "assignment", "project"]),
  deadline: z.string().datetime({ offset: true }),
  hours: z.number().min(2).max(40).optional(),
  /// From the dryRun preview; clamped to 2–4 words on write.
  name: z.string().trim().min(1).max(80).optional(),
  /// Optional owned task to attach after create (onboarding boss toggle).
  taskId: z.string().uuid().optional(),
  dryRun: z.boolean(),
}).superRefine((value, ctx) => {
  if (!value.dryRun && value.hours == null) {
    ctx.addIssue({
      code: "custom",
      message: "hours is required to create a boss",
      path: ["hours"],
    });
  }
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface BossPreview {
  name: string;
  title: string;
  type: "exam" | "assignment" | "project";
  hours: number;
  tier: string;
  maxHp: number;
  coinsEligible: boolean;
  defeatCoins: number;
  reason: string;
  deadline: string;
}

export interface CreatedBoss {
  id: string;
  name: string;
  title: string;
  type: string;
  tier: string;
  hours: number;
  maxHp: number;
  damage: number;
  deadline: string;
  status: string;
  coinsEligible: boolean;
}

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function coinsEligibleAt(deadline: Date, now: Date, minHoursBefore: number): boolean {
  const hoursUntil = (deadline.getTime() - now.getTime()) / 3_600_000;
  return hoursUntil >= minHoursBefore;
}

export function dueInDays(deadline: Date, now: Date): number {
  return Math.round((deadline.getTime() - now.getTime()) / 86_400_000);
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

function previewFrom(
  input: z.infer<typeof inputSchema>,
  name: string,
  hours: number,
  reason: string,
  config: GameConfig,
  now: Date,
): BossPreview {
  const clamped = clampHours(hours, config);
  const tier = bossTier(clamped);
  const deadline = new Date(input.deadline);
  const minHours = numberFrom(config.boss_min_hours_before_deadline_for_coins, 48);
  return {
    name,
    title: input.title,
    type: input.type,
    hours: clamped,
    tier: tier.tier,
    maxHp: maxHp(clamped),
    coinsEligible: coinsEligibleAt(deadline, now, minHours),
    defeatCoins: tier.coins,
    reason,
    deadline: input.deadline,
  };
}

/// dryRun returns an AI estimate; confirm writes the boss with the chosen hours.
export async function createBossDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  provider: AiProvider,
  config: GameConfig,
  now = new Date(),
): Promise<{ preview: BossPreview } | { boss: CreatedBoss }> {
  const input = inputSchema.parse(body);
  const deadline = new Date(input.deadline);
  if (Number.isNaN(deadline.getTime())) throw invalidArgument("Invalid deadline");
  if (deadline.getTime() <= now.getTime()) throw invalidArgument("Deadline must be in the future");

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
        participants: 1,
        studentContext: (settings[0]?.study_context as string | null) ?? null,
      });
    } catch (error) {
      if (error instanceof AiExhaustedError) {
        throw new AppError("unavailable", "Could not estimate this boss right now. Try again.", 503);
      }
      throw error;
    }

    await tx`
      update player_state set ai_calls_today = ai_calls_today + 1
      where user_id = ${userId}
    `;

    return {
      preview: previewFrom(input, estimate.boss_name, estimate.total_hours, estimate.reason, config, now),
    };
  }

  const hours = clampHours(input.hours!, config);
  const tier = bossTier(hours);
  const hp = maxHp(hours);
  const minHours = numberFrom(config.boss_min_hours_before_deadline_for_coins, 48);
  const eligible = coinsEligibleAt(deadline, now, minHours);
  const rawName = (input.name ?? "").trim();
  const words = rawName.split(/\s+/).filter((word) => word.length > 0);
  const bossName = words.length >= 2 && words.length <= 4 ? words.join(" ") : "The Deadline Shade";

  const rows = await tx`
    insert into bosses (
      user_id, name, title, type, tier, hours, max_hp, damage, deadline,
      status, last_work_day, coins_eligible, loot, result_seen
    ) values (
      ${userId}, ${bossName}, ${input.title}, ${input.type}, ${tier.tier}, ${hours}, ${hp}, 0,
      ${input.deadline}, 'active', null, ${eligible}, null, false
    )
    returning id, name, title, type, tier, hours, max_hp, damage, deadline, status, coins_eligible
  `;
  const row = rows[0];
  if (!row) throw new AppError("internal", "Failed to create boss", 500);
  const bossId = String(row.id);

  if (input.taskId) {
    const tasks = await tx`
      select id from tasks
      where id = ${input.taskId} and user_id = ${userId} and status in ('draft', 'open')
      for update
    `;
    if (!tasks[0]) throw invalidArgument("Task not found for this boss");
    await tx`
      update tasks set boss_id = ${bossId}
      where id = ${input.taskId} and user_id = ${userId}
    `;
  }

  return {
    boss: {
      id: bossId,
      name: String(row.name),
      title: String(row.title),
      type: String(row.type),
      tier: String(row.tier),
      hours: numberFrom(row.hours, hours),
      maxHp: numberFrom(row.max_hp, hp),
      damage: numberFrom(row.damage, 0),
      deadline: String(row.deadline),
      status: String(row.status),
      coinsEligible: row.coins_eligible === true,
    },
  };
}

export async function createBoss(
  userId: string,
  body: unknown,
  sql: Sql = getSql(),
): Promise<{ preview: BossPreview } | { boss: CreatedBoss }> {
  const config = await loadConfig();
  const provider = getProvider({ timeoutMs: numberFrom(config.ai_timeout_ms, 10_000) });
  return await sql.begin(async (tx) =>
    createBossDraft(userId, body, tx as unknown as Tx, provider, config)
  );
}
