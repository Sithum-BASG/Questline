import { z } from "zod";

import { loadConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument } from "./errors.ts";
import {
  friendCode,
  levelFromXp,
  nextRollover,
  usernameFromDisplayName,
  weekId,
  type LevelCurve,
} from "./onboarding.ts";

const steps = ["signed_in", "character", "story", "study", "first_task", "first_session", "done"] as const;
type Step = typeof steps[number];

const inputSchema = z.object({
  step: z.enum(steps),
  data: z.object({
    timezone: z.string().optional(),
    bodyType: z.enum(["a", "b"]).optional(),
    displayName: z.string().trim().min(1).max(24).optional(),
  }).optional(),
});

export type OnboardingResult = {
  onboardingStep: Step;
  xpTotal: number;
  level: number;
  rewards: unknown[];
};

type BonusFlags = { character: boolean; first_task: boolean; first_session: boolean };

const stepOrder = new Map(steps.map((step, index) => [step, index]));

function laterStep(current: string, next: Step): Step {
  const currentIndex = stepOrder.get(current as Step) ?? -1;
  return currentIndex > stepOrder.get(next)! ? current as Step : next;
}

function curveFrom(value: unknown): LevelCurve {
  const raw = value as { base: number; coef: number; exp: number; round_to: number; max_level: number };
  return {
    base: Number(raw.base),
    coef: Number(raw.coef),
    exp: Number(raw.exp),
    roundTo: Number(raw.round_to),
    maxLevel: Number(raw.max_level),
  };
}

function assertZone(timeZone: string): void {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone });
  } catch {
    throw invalidArgument("timezone is not a real IANA zone");
  }
}

type Reward = { type: string; id?: string; amount?: number };

export async function completeOnboardingStep(
  userId: string,
  body: Record<string, unknown>,
  sql: Sql = getSql(),
): Promise<OnboardingResult> {
  const input = inputSchema.parse(body);
  const data = input.data ?? {};
  const timeZone = data.timezone ?? "Asia/Colombo";
  assertZone(timeZone);
  if (input.step === "character" && (!data.bodyType || !data.displayName)) {
    throw invalidArgument("character needs a body type and a name");
  }

  const config = await loadConfig();
  const starter = config.starter_bonus as { character: number; first_task: number; first_session: number };
  const curve = curveFrom(config.level_curve);

  return await sql.begin(async (tx) => {
    const now = new Date();
    await tx`
      insert into player_state (user_id, week_id, next_rollover_at, timezone, onboarding_step)
      values (
        ${userId},
        ${weekId(now, "Asia/Colombo")},
        ${nextRollover(now, timeZone).toISOString()},
        ${timeZone},
        'signed_in'
      )
      on conflict (user_id) do update set timezone = excluded.timezone
    `;
    await tx`
      insert into user_settings (user_id) values (${userId})
      on conflict (user_id) do nothing
    `;

    if (input.step === "character" && data.displayName && data.bodyType) {
      await ensureProfile(tx, userId, data.displayName, data.bodyType);
    }

    const [row] = await tx<{
      xp_total: number;
      onboarding_step: string;
      onboarding_bonus: BonusFlags;
      free_chests: number;
      level: number;
    }[]>`
      select
        p.xp_total,
        p.onboarding_step,
        p.onboarding_bonus,
        p.free_chests,
        coalesce(pr.level, 1) as level
      from player_state p
      left join profiles pr on pr.id = p.user_id
      where p.user_id = ${userId}
    `;

    const flags = { ...row.onboarding_bonus };
    let xp = row.xp_total;
    let freeChests = row.free_chests;
    const bonusKey = input.step === "character" || input.step === "first_task" || input.step === "first_session"
      ? input.step
      : null;
    if (bonusKey && flags[bonusKey] !== true) {
      xp += Number(starter[bonusKey]);
      flags[bonusKey] = true;
      if (bonusKey === "first_session") freeChests += 1;
    }

    const nextLevel = levelFromXp(xp, curve);
    const rewards: Reward[] = [];
    if (nextLevel > row.level) {
      const granted = await tx<{ rewards: Reward[] }[]>`
        select rewards from level_rewards
        where level > ${row.level} and level <= ${nextLevel}
        order by level
      `;
      for (const grant of granted) {
        for (const reward of grant.rewards) {
          rewards.push(reward);
          if (reward.type === "item" && reward.id) {
            await tx`
              insert into inventory (user_id, catalog_id, source)
              values (${userId}, ${reward.id}, 'level')
              on conflict (user_id, catalog_id) do nothing
            `;
          } else if (reward.type === "title" && reward.id) {
            await tx`
              update player_state
              set owned_titles = owned_titles || ${tx.array([reward.id])}
              where user_id = ${userId} and not (${reward.id} = any (owned_titles))
            `;
          } else if (reward.type === "coins" && reward.amount) {
            await tx`
              update player_state set coins = coins + ${reward.amount} where user_id = ${userId}
            `;
          }
        }
      }
    }

    const onboardingStep = laterStep(row.onboarding_step, input.step);
    await tx`
      update player_state
      set xp_total = ${xp},
          onboarding_bonus = ${tx.json(flags)},
          onboarding_step = ${onboardingStep},
          free_chests = ${freeChests}
      where user_id = ${userId}
    `;
    if (nextLevel !== row.level) {
      await tx`update profiles set level = ${nextLevel} where id = ${userId}`;
    }

    return { onboardingStep, xpTotal: xp, level: nextLevel, rewards };
  });
}

async function ensureProfile(
  tx: Sql,
  userId: string,
  displayName: string,
  bodyType: string,
): Promise<void> {
  const [existing] = await tx<{ id: string }[]>`select id from profiles where id = ${userId}`;
  if (existing) return;

  for (let attempt = 0; attempt < 6; attempt++) {
    const digits = String(Math.floor(Math.random() * 10000)).padStart(4, "0");
    const username = usernameFromDisplayName(displayName, digits);
    const code = friendCode(Math.random);
    try {
      await tx`
        insert into profiles (id, username, friend_code, display_name, body_type)
        values (${userId}, ${username}, ${code}, ${displayName}, ${bodyType})
      `;
      break;
    } catch (error) {
      const code23505 = (error as { code?: string }).code === "23505";
      if (!code23505 || attempt === 5) throw error;
    }
  }

  await tx`
    insert into inventory (user_id, catalog_id, source) values
      (${userId}, 'skin_starter', 'starter'),
      (${userId}, 'bg_starter', 'starter'),
      (${userId}, 'frame_apprentice', 'starter')
    on conflict (user_id, catalog_id) do nothing
  `;
  await tx`insert into presence (user_id) values (${userId}) on conflict (user_id) do nothing`;
  await tx`insert into friend_summaries (user_id) values (${userId}) on conflict (user_id) do nothing`;
}
