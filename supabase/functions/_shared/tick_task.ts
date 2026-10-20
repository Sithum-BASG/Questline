import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import { sessionXp } from "./game/xp.ts";
import { dayKey, weekId } from "./game/time.ts";
import { type SessionSummary } from "./end_session.ts";

const inputSchema = z.object({ taskId: z.string().uuid() });

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Marks an open task done at half credit. It never deals boss damage.
export async function tickDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
): Promise<SessionSummary> {
  const { taskId } = inputSchema.parse(body);
  const tasks = await tx`
    select difficulty, est_minutes, stat, status, xp_raw, xp_final
    from tasks where id = ${taskId} and user_id = ${userId} for update
  `;
  const task = tasks[0];
  if (!task) throw notFound("Task not found");
  if (task.status === "done") {
    return {
      rawXp: numberFrom(task.xp_raw, 0),
      finalXp: numberFrom(task.xp_final, 0),
      verifiedMinutes: numberFrom(task.est_minutes, 0),
      countedMinutes: numberFrom(task.est_minutes, 0),
      broken: false,
      xpTotal: 0,
      level: 1,
      rewards: [],
    };
  }
  if (task.status !== "open" || task.difficulty == null || task.est_minutes == null) {
    throw invalidArgument("Only a judged open task can be ticked");
  }

  const stateRows = await tx`
    select timezone, week_id, weekly_raw_xp, xp_total from player_state where user_id = ${userId} for update
  `;
  const state = stateRows[0] ?? {};
  const zone = typeof state.timezone === "string" ? state.timezone : "Asia/Colombo";
  const estimate = numberFrom(task.est_minutes, 0);
  const xp = sessionXp({
    difficulty: numberFrom(task.difficulty, 1),
    estimatedMinutes: estimate,
    verifiedMinutes: estimate,
    mode: "tick",
    rates: {
      multipliers: config.xp_difficulty_multipliers as number[],
      focusCapRatio: 1.5,
      activityCapRatio: 1,
      activityShare: numberFrom(config.xp_activity_share, 0.8),
      tickShare: numberFrom(config.xp_tick_share, 0.5),
      onTimeBonus: 0.1,
      latePenaltyPerDay: 0.1,
      lateFloor: 0.5,
      reschedulePenalty: 0.2,
      dailyFocusMinutes: 480,
      gearStatCap: 0.25,
      deepFocusMinutes: 45,
      deepFocusBonus: 0.1,
      potionMultiplier: 1.5,
      potionMinMinutes: 25,
      comebackMultiplier: 2,
    },
  });
  const day = dayKey(now, zone);
  const week = weekId(now, "Asia/Colombo");
  const summary: SessionSummary = {
    rawXp: xp.raw,
    finalXp: xp.final,
    verifiedMinutes: estimate,
    countedMinutes: estimate,
    broken: false,
    xpTotal: numberFrom(state.xp_total, 0) + xp.final,
    level: 1,
    rewards: [],
  };
  await tx`
    update tasks set status = 'done', completion_mode = 'tick', completion_minutes = ${estimate},
      completed_at = ${now.toISOString()}, completion_day = ${day}, xp_raw = ${xp.raw}, xp_final = ${xp.final}
    where id = ${taskId} and user_id = ${userId}
  `;
  await tx`
    insert into daily_stats (user_id, day, raw_xp, sessions_started, met_minimum)
    values (${userId}, ${day}, ${xp.raw}, 1, ${xp.raw >= 40})
    on conflict (user_id, day) do update set
      raw_xp = daily_stats.raw_xp + excluded.raw_xp,
      sessions_started = daily_stats.sessions_started + 1,
      met_minimum = daily_stats.raw_xp + excluded.raw_xp >= 40
  `;
  await tx`
    insert into weekly_scores (week_id, user_id, raw_xp)
    values (${week}, ${userId}, ${xp.raw})
    on conflict (week_id, user_id) do update set raw_xp = weekly_scores.raw_xp + excluded.raw_xp, updated_at = now()
  `;
  await tx`
    update player_state set xp_total = xp_total + ${xp.final},
      weekly_raw_xp = case when week_id = ${week} then weekly_raw_xp + ${xp.raw} else ${xp.raw} end,
      week_id = ${week}
    where user_id = ${userId}
  `;
  return summary;
}

export async function tickTask(userId: string, body: unknown, sql: Sql = getSql()): Promise<SessionSummary> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => tickDraft(userId, body, tx as unknown as Tx, config));
}
