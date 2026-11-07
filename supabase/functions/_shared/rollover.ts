import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { healBoss } from "./game/combat.ts";
import { closeDay, defaultMilestones, type StreakMilestone, type StreakState } from "./game/streaks.ts";
import { dayKey, nextRollover, zonedParts, zonedTime } from "./game/time.ts";

const inputSchema = z.object({
  /** Local / test only: ISO timestamp used as "now" for who is due and which day closes. */
  now: z.string().datetime({ offset: true }).optional(),
  limit: z.number().int().min(1).max(200).optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function dateString(value: unknown): string | null {
  if (value == null) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  const text = String(value);
  return text.length >= 10 ? text.slice(0, 10) : text;
}

function milestonesFrom(config: GameConfig): StreakMilestone[] {
  const raw = config.streak_milestones as Record<string, Record<string, unknown>>;
  if (!raw || typeof raw !== "object") return defaultMilestones;
  return Object.entries(raw).map(([days, reward]) => ({
    days: Number(days),
    coins: reward.coins != null ? Number(reward.coins) : undefined,
    freeChest: reward.freeChest != null ? Number(reward.freeChest) : undefined,
    item: typeof reward.item === "string" ? reward.item : undefined,
    title: typeof reward.title === "string" ? reward.title : undefined,
  }));
}

function previousDayKey(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  const prev = new Date(Date.UTC(year, month - 1, date) - 86_400_000);
  const pad = (value: number) => String(value).padStart(2, "0");
  return `${prev.getUTCFullYear()}-${pad(prev.getUTCMonth() + 1)}-${pad(prev.getUTCDate())}`;
}

function weekdayOfDayKey(day: string, timeZone: string): number {
  const [year, month, date] = day.split("-").map(Number);
  const noon = zonedTime(year, month, date, 12, timeZone);
  return zonedParts(noon, timeZone).weekday;
}

async function refreshRadar(tx: Tx, userId: string, hideRadar: boolean): Promise<void> {
  if (hideRadar) {
    await tx`
      update friend_summaries set radar30 = null, radar7 = null, updated_at = now()
      where user_id = ${userId}
    `;
    return;
  }
  await tx`
    update friend_summaries set
      radar30 = (
        select jsonb_build_object(
          'intellect', coalesce(sum(xp_intellect), 0),
          'vitality', coalesce(sum(xp_vitality), 0),
          'craft', coalesce(sum(xp_craft), 0),
          'charisma', coalesce(sum(xp_charisma), 0)
        )
        from daily_stats
        where user_id = ${userId} and day >= (current_date - 29)
      ),
      radar7 = (
        select jsonb_build_object(
          'intellect', coalesce(sum(xp_intellect), 0),
          'vitality', coalesce(sum(xp_vitality), 0),
          'craft', coalesce(sum(xp_craft), 0),
          'charisma', coalesce(sum(xp_charisma), 0)
        )
        from daily_stats
        where user_id = ${userId} and day >= (current_date - 6)
      ),
      updated_at = now()
    where user_id = ${userId}
  `;
}

/// Closes one due player's day. Pure SQL side-effects go through [tx].
export async function rolloverPlayer(
  tx: Tx,
  row: Record<string, unknown>,
  now: Date,
  config: GameConfig,
): Promise<void> {
  const userId = String(row.user_id);
  const timeZone = String(row.timezone || "Asia/Colombo");
  const boundary = numberFrom(config.day_boundary_hour, 4);
  // next_rollover_at is 04:00 of the new game day; close the day that just ended.
  const closing = previousDayKey(dayKey(now, timeZone, boundary));

  let pauseActive = row.pause_active === true;
  if (pauseActive && row.pause_until != null && new Date(String(row.pause_until)).getTime() <= now.getTime()) {
    pauseActive = false;
  }

  const restWeekday = row.rest_weekday == null ? null : numberFrom(row.rest_weekday, -1);
  const isRest = restWeekday != null && restWeekday >= 0 && weekdayOfDayKey(closing, timeZone) === restWeekday;

  const stats = await tx`
    select raw_xp, rest_day, paused from daily_stats
    where user_id = ${userId} and day = ${closing}::date
  `;
  const rawXp = numberFrom(stats[0]?.raw_xp, 0);
  const rest = isRest || stats[0]?.rest_day === true;
  const paused = pauseActive || stats[0]?.paused === true;

  const streakBefore: StreakState = {
    count: numberFrom(row.streak_count, 0),
    best: numberFrom(row.streak_best, 0),
    lastCountedDay: dateString(row.streak_last_counted_day),
    shields: numberFrom(row.shields, 0),
    lastShieldDay: dateString(row.last_shield_day),
    paidMilestones: Array.isArray(row.milestones_paid)
      ? (row.milestones_paid as unknown[]).map((value) => numberFrom(value, 0))
      : [],
  };
  const closed = closeDay(streakBefore, closing, rawXp, {
    rest,
    paused,
    minimumRawXp: numberFrom(config.streak_min_raw_xp, 40),
    milestones: milestonesFrom(config),
  });

  let coins = numberFrom(row.coins, 0);
  let freeChests = numberFrom(row.free_chests, 0);
  const ownedTitles = Array.isArray(row.owned_titles) ? [...(row.owned_titles as string[])] : [];
  const milestone = closed.milestone;
  if (milestone?.coins) coins += milestone.coins;
  if (milestone?.freeChest) freeChests += milestone.freeChest;
  if (milestone?.title && !ownedTitles.includes(milestone.title)) ownedTitles.push(milestone.title);
  if (milestone?.item) {
    await tx`
      insert into inventory (user_id, catalog_id, source)
      values (${userId}, ${milestone.item}, 'streak')
      on conflict (user_id, catalog_id) do nothing
    `;
  }

  const minimum = numberFrom(config.streak_min_raw_xp, 40);
  let inactiveDays = numberFrom(row.inactive_days, 0);
  let comebackArmed = row.comeback_armed === true;
  if (rawXp >= minimum) {
    inactiveDays = 0;
  } else if (!rest && !paused) {
    inactiveDays += 1;
    if (inactiveDays >= numberFrom(config.comeback_inactive_days, 3)) comebackArmed = true;
  }

  const healRate = numberFrom(config.boss_heal_per_day, 0.03);
  const bosses = await tx`
    select id, status, damage, max_hp, last_work_day
    from bosses
    where user_id = ${userId} and status = 'active'
    for update
  `;
  for (const boss of bosses) {
    const nextDamage = healBoss(
      {
        status: String(boss.status),
        damage: numberFrom(boss.damage, 0),
        maxHp: numberFrom(boss.max_hp, 0),
        lastWorkDay: dateString(boss.last_work_day),
        staggered: false,
      },
      closing,
      { rest, paused, rate: healRate },
    );
    if (nextDamage !== numberFrom(boss.damage, 0)) {
      await tx`update bosses set damage = ${nextDamage} where id = ${boss.id} and user_id = ${userId}`;
    }
  }

  const nextAt = nextRollover(now, timeZone, boundary);
  await tx`
    update player_state set
      streak_count = ${closed.state.count},
      streak_best = ${closed.state.best},
      streak_last_counted_day = ${closed.state.lastCountedDay},
      shields = ${closed.state.shields},
      last_shield_day = ${closed.state.lastShieldDay},
      milestones_paid = ${closed.state.paidMilestones},
      coins = ${coins},
      free_chests = ${freeChests},
      owned_titles = ${ownedTitles},
      inactive_days = ${inactiveDays},
      comeback_armed = ${comebackArmed},
      ai_calls_today = 0,
      focus_minutes_today = 0,
      pause_active = ${pauseActive},
      next_rollover_at = ${nextAt.toISOString()}
    where user_id = ${userId}
  `;

  const profile = await tx`select hide_radar from profiles where id = ${userId}`;
  await refreshRadar(tx, userId, profile[0]?.hide_radar === true);
}

export async function runRolloverDraft(
  body: unknown,
  tx: Tx,
  config: GameConfig,
  nowOverride?: Date,
): Promise<{ processed: number }> {
  const input = inputSchema.parse(body ?? {});
  const now = nowOverride ?? (input.now ? new Date(input.now) : new Date());
  const limit = input.limit ?? 200;

  const due = await tx`
    select
      user_id, coins, streak_count, streak_best, streak_last_counted_day, shields, last_shield_day,
      milestones_paid, free_chests, owned_titles, inactive_days, comeback_armed, timezone,
      rest_weekday, pause_active, pause_until, next_rollover_at
    from player_state
    where next_rollover_at <= ${now.toISOString()}
    order by next_rollover_at
    limit ${limit}
    for update skip locked
  `;

  for (const row of due) {
    await rolloverPlayer(tx, row, now, config);
  }
  return { processed: due.length };
}

export async function runRollover(
  body: unknown,
  sql: Sql = getSql(),
  nowOverride?: Date,
): Promise<{ processed: number }> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => runRolloverDraft(body, tx as unknown as Tx, config, nowOverride));
}
