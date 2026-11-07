import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { notFound } from "./errors.ts";
import { metFairShare, sessionDamage } from "./game/combat.ts";
import { applyGuildQuestProgress } from "./guild_quest.ts";
import { sessionXp, type XpRates } from "./game/xp.ts";
import { levelFromXp, rewardsForLevels, type LevelCurve } from "./game/rewards.ts";
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
  xpTotal: number;
  level: number;
  rewards: unknown[];
  bossDamage?: number;
  raidDamage?: number;
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
    select difficulty, est_minutes, stat, due_at, rescheduled, scroll_used, status, boss_id, raid_id
    from tasks where id = ${session.task_id} and user_id = ${userId} for update
  `;
  const task = tasks[0];
  if (!task) throw notFound("Task not found");

  const stateRows = await tx`
    select timezone, focus_minutes_today, weekly_raw_xp, week_id, comeback_armed, potions, onboarding_step, xp_total
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
  let verifiedMinutes = Math.max(0, Math.floor((elapsedMs - awayMs) / 60_000));
  const settings = await tx`select demo_mode from user_settings where user_id = ${userId}`;
  const allowed = await tx`select user_id from demo_allowlist where user_id = ${userId}`;
  if (settings[0]?.demo_mode === true && allowed.length > 0) {
    const elapsedSeconds = Math.max(0, Math.floor((elapsedMs - awayMs) / 1000));
    verifiedMinutes = Math.floor(elapsedSeconds / 6);
  }
  const broken = input.broken === true;
  const onboarding = state.onboarding_step === "first_session";
  const earns = onboarding || verifiedMinutes >= minimumMinutes;

  const day = dayKey(now, zone);
  const dueAt = task.due_at ? new Date(String(task.due_at)) : null;
  const dueDay = dueAt ? dayKey(dueAt, zone) : null;
  const onTime = dueDay != null && day <= dueDay;
  const gear = await tx`
    select inventory.attuned_stat, catalog_items.rarity, catalog_items.passive
    from inventory join catalog_items on catalog_items.id = inventory.catalog_id
    where inventory.user_id = ${userId} and inventory.equipped_slot is not null
  `;
  const bossSlayer = gear.some((row) => row.passive === "boss_slayer");
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

  const previousXp = numberFrom(state.xp_total, 0);
  const xpTotal = previousXp + xp.final;
  const curve = curveFrom(config.level_curve);
  const previousLevel = levelFromXp(previousXp, curve);
  const nextLevel = levelFromXp(xpTotal, curve);
  const rewardRows = nextLevel > previousLevel
    ? await tx`
      select level, rewards from level_rewards
      where level > ${previousLevel} and level <= ${nextLevel}
      order by level
    `
    : [];
  const table = rewardRows.map((row) => ({
    level: numberFrom(row.level, 0),
    rewards: Array.isArray(row.rewards) ? row.rewards : JSON.parse(String(row.rewards ?? "[]")),
  }));
  const rewards = rewardsForLevels(previousLevel, nextLevel, table);
  for (const reward of rewards as { type?: string; id?: string; amount?: number }[]) {
    if (reward.type === "item" && reward.id) {
      await tx`
        insert into inventory (user_id, catalog_id, source)
        values (${userId}, ${reward.id}, 'level')
        on conflict (user_id, catalog_id) do nothing
      `;
    } else if (reward.type === "title" && reward.id) {
      await tx`
        update player_state
        set owned_titles = owned_titles || ${`{${reward.id}}`}::text[]
        where user_id = ${userId} and not (${reward.id} = any (owned_titles))
      `;
    } else if (reward.type === "coins" && reward.amount) {
      await tx`update player_state set coins = coins + ${reward.amount} where user_id = ${userId}`;
    }
  }
  if (nextLevel !== previousLevel) {
    await tx`update profiles set level = ${nextLevel} where id = ${userId}`;
    await tx`
      insert into activity_events (actor_id, type, payload, visible_to)
      values (
        ${userId}, 'level_up', ${JSON.stringify({ level: nextLevel })}::jsonb,
        coalesce((select array_agg(friend_id) from friendships where user_id = ${userId} and status = 'accepted'), '{}')
      )
    `;
  }

  let bossDamageDealt = 0;
  let raidDamageDealt = 0;
  const mode = session.mode === "activity" ? "activity" : "focus";
  const hit = xp.countedMinutes > 0 ? sessionDamage(xp.countedMinutes, mode, bossSlayer) : 0;
  const bossId = typeof task.boss_id === "string" ? task.boss_id : null;
  if (bossId && hit > 0) {
    bossDamageDealt = hit;
    const bosses = await tx`
      select id, status, damage, max_hp
      from bosses
      where id = ${bossId} and user_id = ${userId} and status in ('active', 'staggered')
      for update
    `;
    const boss = bosses[0];
    if (boss) {
      const max = numberFrom(boss.max_hp, 0);
      const nextDamage = Math.min(max, numberFrom(boss.damage, 0) + bossDamageDealt);
      const nextStatus = nextDamage >= max && max > 0 ? "staggered" : String(boss.status);
      await tx`
        update bosses set
          damage = ${nextDamage},
          last_work_day = ${day},
          status = ${nextStatus}
        where id = ${bossId} and user_id = ${userId}
      `;
    } else {
      bossDamageDealt = 0;
    }
  }

  const raidId = typeof task.raid_id === "string" ? task.raid_id : null;
  if (raidId && hit > 0) {
    const membership = await tx`
      select display_name, left_raid from raid_members
      where raid_id = ${raidId} and user_id = ${userId}
      for update
    `;
    const member = membership[0];
    if (member && member.left_raid !== true) {
      const raids = await tx`
        select id, status, damage, max_hp, participants
        from raids
        where id = ${raidId} and status = 'active'
        for update
      `;
      const raid = raids[0];
      if (raid) {
        raidDamageDealt = hit;
        const personal = await tx`
          select damage from raid_damage
          where raid_id = ${raidId} and user_id = ${userId}
          for update
        `;
        const personalNext = numberFrom(personal[0]?.damage, 0) + raidDamageDealt;
        await tx`
          insert into raid_damage (raid_id, user_id, damage)
          values (${raidId}, ${userId}, ${personalNext})
          on conflict (raid_id, user_id) do update set damage = ${personalNext}
        `;
        const max = numberFrom(raid.max_hp, 0);
        const raidNext = Math.min(max, numberFrom(raid.damage, 0) + raidDamageDealt);
        await tx`
          update raids set damage = ${raidNext}
          where id = ${raidId}
        `;
        await tx`
          insert into raid_events (raid_id, user_id, display_name, amount)
          values (${raidId}, ${userId}, ${String(member.display_name)}, ${raidDamageDealt})
        `;
        const fair = metFairShare(personalNext, max, numberFrom(raid.participants, 1));
        await tx`
          update raid_members set met_fair_share = ${fair}
          where raid_id = ${raidId} and user_id = ${userId}
        `;
      }
    }
  }

  const summary: SessionSummary = {
    rawXp: xp.raw,
    finalXp: xp.final,
    verifiedMinutes,
    countedMinutes: xp.countedMinutes,
    broken,
    xpTotal,
    level: nextLevel,
    rewards,
    ...(bossDamageDealt > 0 ? { bossDamage: bossDamageDealt } : {}),
    ...(raidDamageDealt > 0 ? { raidDamage: raidDamageDealt } : {}),
  };
  const stat = String(task.stat ?? "intellect");
  const week = weekId(now, leaderboardTz);
  const weeklyRaw = (state.week_id === week ? numberFrom(state.weekly_raw_xp, 0) : 0) + xp.raw;
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
  await applyGuildQuestProgress(userId, xp.raw, week, tx, config);
  const spentPotion = session.potion === true && earns && state.comeback_armed !== true;
  await tx`
    update player_state set
      focus_minutes_today = focus_minutes_today + ${xp.countedMinutes},
      weekly_raw_xp = case when week_id = ${week} then weekly_raw_xp + ${xp.raw} else ${xp.raw} end,
      week_id = ${week},
      xp_total = ${xpTotal},
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
  await tx`
    update friend_summaries set weekly_raw_xp = ${weeklyRaw}, updated_at = now()
    where user_id = ${userId}
  `;
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
