import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { notFound } from "./errors.ts";
import { sessionXp, type XpRates } from "./game/xp.ts";
import { dayKey, weekId } from "./game/time.ts";

const inputSchema = z.object({
  sessionId: z.string().uuid(),
  interruptions: z.array(z.object({
    leftAt: z.string().datetime({ offset: true }),
    returnedAt: z.string().datetime({ offset: true }).optional(),
  })).default([]),
  broken: z.boolean().optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface SessionSummary {
  rawXp: number;
  finalXp: number;
  verifiedMinutes: number;
  countedMinutes: number;
  broken: boolean;
}

const leaderboardTz = "Asia/Colombo";
const minimumMinutes = 5;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function ratesFrom(config: GameConfig): XpRates {
  return {
    multipliers: config.xp_difficulty_multipliers as number[],
    focusCapRatio: numberFrom(config.xp_focus_cap_ratio, 1.5),
    activityCapRatio: numberFrom(config.xp_activity_cap_ratio, 1),
    activityShare: numberFrom(config.xp_activity_share, 0.8),
    tickShare: numberFrom(config.xp_tick_share, 0.5),
    onTimeBonus: numberFrom(config.xp_on_time_bonus, 0.1),
    latePenaltyPerDay: numberFrom(config.xp_late_penalty_per_day, 0.1),
    lateFloor: numberFrom(config.xp_late_floor, 0.5),
    reschedulePenalty: numberFrom(config.xp_reschedule_penalty, 0.2),
    dailyFocusMinutes: numberFrom(config.xp_daily_focus_minutes_limit, 480),
    gearStatCap: numberFrom(config.gear_stat_cap, 0.25),
    deepFocusMinutes: numberFrom(config.deep_focus_min_minutes, 45),
    deepFocusBonus: numberFrom(config.deep_focus_bonus, 0.1),
    potionMultiplier: numberFrom(config.potion_multiplier, 1.5),
    potionMinMinutes: numberFrom(config.potion_min_minutes, 25),
    comebackMultiplier: numberFrom(config.comeback_multiplier, 2),
  };
}

function gearBoost(rows: Record<string, unknown>[], stat: string, rates: Record<string, number>): number {
  let total = 0;
  for (const row of rows) {
    if (row.attuned_stat !== stat) continue;
    const rarity = String(row.rarity ?? "");
    total += numberFrom(rates[rarity], 0);
  }
  return total;
}

function daysAfter(earlier: string, later: string): number {
  const start = Date.parse(`${earlier}T00:00:00Z`);
  const end = Date.parse(`${later}T00:00:00Z`);
  return Math.max(0, Math.round((end - start) / 86_400_000));
}

/// Closes the caller's session and records raw XP for the day and the week.
export async function endDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
): Promise<SessionSummary> {
  const input = inputSchema.parse(body);
  const sessions = await tx`
    select id, task_id, mode, started_at, status, potion, processed, summary
    from sessions where id = ${input.sessionId} and user_id = ${userId} for update
  `;
  const session = sessions[0];
  if (!session) throw notFound("Session not found");
  if (session.processed && session.summary) return session.summary as SessionSummary;

  const tasks = await tx`
    select difficulty, est_minutes, stat, due_at, rescheduled, scroll_used, status
    from tasks where id = ${session.task_id} and user_id = ${userId} for update
  `;
  const task = tasks[0];
  if (!task) throw notFound("Task not found");

  const stateRows = await tx`
    select timezone, focus_minutes_today, weekly_raw_xp, week_id, comeback_armed, potions, onboarding_step
    from player_state where user_id = ${userId} for update
  `;
  const state = stateRows[0] ?? {};
  const zone = typeof state.timezone === "string" ? state.timezone : leaderboardTz;
  let awayMs = 0;
  for (const interruption of input.interruptions) {
    const left = Date.parse(interruption.leftAt);
    const back = interruption.returnedAt ? Date.parse(interruption.returnedAt) : now.getTime();
    if (Number.isFinite(left) && Number.isFinite(back) && back > left) awayMs += back - left;
  }
  const elapsedMs = now.getTime() - Date.parse(String(session.started_at));
  const verifiedMinutes = Math.max(0, Math.floor((elapsedMs - awayMs) / 60_000));
  const broken = input.broken === true;
  const onboarding = state.onboarding_step === "first_session";
  const earns = onboarding || verifiedMinutes >= minimumMinutes;

  const day = dayKey(now, zone);
  const dueAt = task.due_at ? new Date(String(task.due_at)) : null;
  const dueDay = dueAt ? dayKey(dueAt, zone) : null;
  const onTime = dueDay != null && day <= dueDay;
  const gear = await tx`
    select inventory.attuned_stat, catalog_items.rarity
    from inventory join catalog_items on catalog_items.id = inventory.catalog_id
    where inventory.user_id = ${userId} and inventory.equipped_slot is not null
  `;
  const rates = ratesFrom(config);
  const xp = earns
    ? sessionXp({
      difficulty: numberFrom(task.difficulty, 1),
      estimatedMinutes: numberFrom(task.est_minutes, verifiedMinutes),
      verifiedMinutes,
      mode: session.mode === "activity" ? "activity" : "focus",
      dated: dueAt != null,
      onTime,
      overdueDays: dueDay && !onTime ? daysAfter(dueDay, day) : 0,
      rescheduled: task.rescheduled === true,
      scrollUsed: task.scroll_used === true,
      focusMinutesToday: numberFrom(state.focus_minutes_today, 0),
      gearBoost: gearBoost(gear, String(task.stat ?? ""), config.gear_boost as Record<string, number>),
      comebackArmed: state.comeback_armed === true,
      potion: session.potion === true,
      rates,
    })
    : { countedMinutes: 0, raw: 0, final: 0 };

  const summary: SessionSummary = {
    rawXp: xp.raw,
    finalXp: xp.final,
    verifiedMinutes,
    countedMinutes: xp.countedMinutes,
    broken,
  };
  const stat = String(task.stat ?? "intellect");
  const week = weekId(now, leaderboardTz);
  if (stat === "vitality") {
    await tx`
      insert into daily_stats (user_id, day, xp_vitality, raw_xp, focus_minutes, sessions_started, met_minimum)
      values (${userId}, ${day}, ${xp.raw}, ${xp.raw}, ${xp.countedMinutes}, 1, ${xp.raw >= 40})
      on conflict (user_id, day) do update set
        xp_vitality = daily_stats.xp_vitality + excluded.xp_vitality,
        raw_xp = daily_stats.raw_xp + excluded.raw_xp,
        focus_minutes = daily_stats.focus_minutes + excluded.focus_minutes,
        sessions_started = daily_stats.sessions_started + 1,
        met_minimum = daily_stats.raw_xp + excluded.raw_xp >= 40
    `;
  } else if (stat === "craft") {
    await tx`
      insert into daily_stats (user_id, day, xp_craft, raw_xp, focus_minutes, sessions_started, met_minimum)
      values (${userId}, ${day}, ${xp.raw}, ${xp.raw}, ${xp.countedMinutes}, 1, ${xp.raw >= 40})
      on conflict (user_id, day) do update set
        xp_craft = daily_stats.xp_craft + excluded.xp_craft,
        raw_xp = daily_stats.raw_xp + excluded.raw_xp,
        focus_minutes = daily_stats.focus_minutes + excluded.focus_minutes,
        sessions_started = daily_stats.sessions_started + 1,
        met_minimum = daily_stats.raw_xp + excluded.raw_xp >= 40
    `;
  } else if (stat === "charisma") {
    await tx`
      insert into daily_stats (user_id, day, xp_charisma, raw_xp, focus_minutes, sessions_started, met_minimum)
      values (${userId}, ${day}, ${xp.raw}, ${xp.raw}, ${xp.countedMinutes}, 1, ${xp.raw >= 40})
      on conflict (user_id, day) do update set
        xp_charisma = daily_stats.xp_charisma + excluded.xp_charisma,
        raw_xp = daily_stats.raw_xp + excluded.raw_xp,
        focus_minutes = daily_stats.focus_minutes + excluded.focus_minutes,
        sessions_started = daily_stats.sessions_started + 1,
        met_minimum = daily_stats.raw_xp + excluded.raw_xp >= 40
    `;
  } else {
    await tx`
      insert into daily_stats (user_id, day, xp_intellect, raw_xp, focus_minutes, sessions_started, met_minimum)
      values (${userId}, ${day}, ${xp.raw}, ${xp.raw}, ${xp.countedMinutes}, 1, ${xp.raw >= 40})
      on conflict (user_id, day) do update set
        xp_intellect = daily_stats.xp_intellect + excluded.xp_intellect,
        raw_xp = daily_stats.raw_xp + excluded.raw_xp,
        focus_minutes = daily_stats.focus_minutes + excluded.focus_minutes,
        sessions_started = daily_stats.sessions_started + 1,
        met_minimum = daily_stats.raw_xp + excluded.raw_xp >= 40
    `;
  }
  await tx`
    insert into weekly_scores (week_id, user_id, raw_xp)
    values (${week}, ${userId}, ${xp.raw})
    on conflict (week_id, user_id) do update set
      raw_xp = weekly_scores.raw_xp + excluded.raw_xp, updated_at = now()
  `;
  const spentPotion = session.potion === true && earns && state.comeback_armed !== true;
  await tx`
    update player_state set
      focus_minutes_today = focus_minutes_today + ${xp.countedMinutes},
      weekly_raw_xp = case when week_id = ${week} then weekly_raw_xp + ${xp.raw} else ${xp.raw} end,
      week_id = ${week},
      comeback_armed = ${state.comeback_armed === true && !earns},
      potions = potions - ${spentPotion ? 1 : 0},
      active_potion = ${session.potion === true && !spentPotion}
    where user_id = ${userId}
  `;
  if (!broken && earns) {
    await tx`
      update tasks set status = 'done', completion_mode = ${session.mode}, completion_minutes = ${verifiedMinutes},
        completed_at = ${now.toISOString()}, completion_day = ${day}, xp_raw = ${xp.raw}, xp_final = ${xp.final}
      where id = ${session.task_id} and user_id = ${userId}
    `;
  }
  const status = broken ? "broken" : "completed";
  await tx`
    update sessions set status = ${status}, ended_at = ${now.toISOString()}, verified_minutes = ${verifiedMinutes},
      interruption_seconds = ${Math.round(awayMs / 1000)}, processed = true, summary = ${JSON.stringify(summary)}::jsonb
    where id = ${input.sessionId} and user_id = ${userId}
  `;
  return summary;
}

export async function endSession(userId: string, body: unknown, sql: Sql = getSql()): Promise<SessionSummary> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => endDraft(userId, body, tx as unknown as Tx, config));
}
