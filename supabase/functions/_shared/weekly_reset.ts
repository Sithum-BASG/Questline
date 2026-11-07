import { z } from "zod";

import { applyAchievementProgress, bumpCounters } from "./apply_achievements.ts";
import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { isBalancedWeek, isSteadyWeek } from "./game/achievements.ts";
import { weekId } from "./game/time.ts";
import {
  isoWeekDateRange,
  leaderboardRank,
  pickWeightedItem,
  priorWeekId,
  qualifiesForRankRewards,
  rankRewardForPlace,
  winsSpecialItem,
  type WeeklyScoreRow,
} from "./game/weekly.ts";
import { guildQuestEligible, guildQuestPayoutCoins } from "./guild_quest.ts";

const inputSchema = z.object({
  now: z.string().datetime({ offset: true }).optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

const leaderboardTz = "Asia/Colombo";

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

async function grantSpecial(userId: string, item: string, tx: Tx): Promise<void> {
  if (item === "streak_shield") {
    await tx`update player_state set shields = shields + 1 where user_id = ${userId}`;
  } else if (item === "focus_potion") {
    await tx`update player_state set potions = potions + 1 where user_id = ${userId}`;
  } else if (item === "reschedule_scroll") {
    await tx`update player_state set scrolls = scrolls + 1 where user_id = ${userId}`;
  } else if (item === "free_chest") {
    await tx`update player_state set free_chests = free_chests + 1 where user_id = ${userId}`;
  }
}

async function weekStatSplit(
  userId: string,
  week: string,
  tx: Tx,
): Promise<{ intellect: number; vitality: number; craft: number; charisma: number; bestDay: string | null; bestDayXp: number }> {
  const { start, end } = isoWeekDateRange(week);
  const rows = await tx`
    select day, xp_intellect, xp_vitality, xp_craft, xp_charisma, raw_xp
    from daily_stats
    where user_id = ${userId} and day >= ${start}::date and day <= ${end}::date
  `;
  let intellect = 0;
  let vitality = 0;
  let craft = 0;
  let charisma = 0;
  let bestDay: string | null = null;
  let bestDayXp = 0;
  for (const row of rows) {
    intellect += numberFrom(row.xp_intellect, 0);
    vitality += numberFrom(row.xp_vitality, 0);
    craft += numberFrom(row.xp_craft, 0);
    charisma += numberFrom(row.xp_charisma, 0);
    const raw = numberFrom(row.raw_xp, 0);
    if (raw > bestDayXp) {
      bestDayXp = raw;
      bestDay = String(row.day).slice(0, 10);
    }
  }
  return { intellect, vitality, craft, charisma, bestDay, bestDayXp };
}

async function trailing30Stats(
  userId: string,
  endDay: string,
  tx: Tx,
): Promise<{ intellect: number; vitality: number; craft: number; charisma: number; total: number }> {
  const rows = await tx`
    select xp_intellect, xp_vitality, xp_craft, xp_charisma
    from daily_stats
    where user_id = ${userId} and day > (${endDay}::date - 30) and day <= ${endDay}::date
  `;
  let intellect = 0;
  let vitality = 0;
  let craft = 0;
  let charisma = 0;
  for (const row of rows) {
    intellect += numberFrom(row.xp_intellect, 0);
    vitality += numberFrom(row.xp_vitality, 0);
    craft += numberFrom(row.xp_craft, 0);
    charisma += numberFrom(row.xp_charisma, 0);
  }
  return { intellect, vitality, craft, charisma, total: intellect + vitality + craft + charisma };
}

async function steadyDaysInWeek(userId: string, week: string, tx: Tx): Promise<number> {
  const { start, end } = isoWeekDateRange(week);
  const rows = await tx`
    select count(*)::int as n from daily_stats
    where user_id = ${userId}
      and day >= ${start}::date and day <= ${end}::date
      and (sessions_started > 0 or focus_minutes > 0)
  `;
  return numberFrom(rows[0]?.n, 0);
}

async function bossesBeatenInWeek(userId: string, week: string, tx: Tx): Promise<number> {
  const { start, end } = isoWeekDateRange(week);
  // No defeated_at column — approximate with deadlines that fell in the closed week.
  const rows = await tx`
    select count(*)::int as n from bosses
    where user_id = ${userId}
      and status = 'defeated'
      and deadline::date >= ${start}::date
      and deadline::date <= ${end}::date
  `;
  return numberFrom(rows[0]?.n, 0);
}

/**
 * Closes the leaderboard week: rank/target/guild payouts, Balanced/Steady badges,
 * weekly_results inbox, then rolls everyone onto the new week_id.
 */
export async function runWeeklyResetDraft(
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
  random: () => number = Math.random,
): Promise<{ users: number; guildsPaid: number }> {
  inputSchema.parse(body ?? {});
  const newWeek = weekId(now, leaderboardTz);
  const closingWeek = priorWeekId(newWeek);
  const targetXp = numberFrom(config.weekly_target_raw_xp, 500);
  const targetCoins = numberFrom(config.weekly_target_coins, 200);
  const minFriends = numberFrom(config.leaderboard_min_friends, 4);
  const questMin = numberFrom(config.guild_quest_min_contribution, 200);
  const questCoins = guildQuestPayoutCoins({
    guild_quest_coins: numberFrom(config.guild_quest_coins, 100),
  });
  const pool = (config.special_item_pool ?? {}) as Record<string, number>;
  const { end: weekEnd } = isoWeekDateRange(closingWeek);

  const scores = await tx`
    select user_id, raw_xp, updated_at from weekly_scores where week_id = ${closingWeek}
  `;
  const scoreByUser = new Map<string, WeeklyScoreRow>();
  for (const row of scores) {
    scoreByUser.set(String(row.user_id), {
      userId: String(row.user_id),
      rawXp: numberFrom(row.raw_xp, 0),
      updatedAt: String(row.updated_at),
    });
  }

  const players = await tx`
    select user_id, pending_rest_weekday from player_state
  `;

  let guildsPaid = 0;
  const guildPayoutByUser = new Map<string, number>();
  const guilds = await tx`
    select id, quest_progress, quest_goal, quest_week_id from guilds
    where quest_week_id = ${closingWeek}
  `;
  for (const guild of guilds) {
    const guildId = String(guild.id);
    const progress = numberFrom(guild.quest_progress, 0);
    const goal = numberFrom(guild.quest_goal, numberFrom(config.guild_quest_goal, 5000));
    const members = await tx`
      select user_id, quest_contribution from guild_members where guild_id = ${guildId}
    `;
    for (const member of members) {
      const userId = String(member.user_id);
      const contribution = numberFrom(member.quest_contribution, 0);
      if (guildQuestEligible(contribution, progress, goal, questMin)) {
        guildPayoutByUser.set(userId, (guildPayoutByUser.get(userId) ?? 0) + questCoins);
        guildsPaid += 1;
      }
    }
    await tx`
      update guilds set quest_week_id = ${newWeek}, quest_progress = 0, quest_goal = ${goal}
      where id = ${guildId}
    `;
    await tx`update guild_members set quest_contribution = 0 where guild_id = ${guildId}`;
  }

  let usersProcessed = 0;
  for (const player of players) {
    const userId = String(player.user_id);
    const selfScore = scoreByUser.get(userId) ?? {
      userId,
      rawXp: 0,
      updatedAt: "9999-12-31T00:00:00.000Z",
    };
    const rawXp = selfScore.rawXp;

    const friendRows = await tx`
      select friend_id from friendships
      where user_id = ${userId} and status = 'accepted'
    `;
    const friendIds = friendRows.map((row) => String(row.friend_id));
    const board: WeeklyScoreRow[] = [selfScore];
    let activeFriends = 0;
    for (const friendId of friendIds) {
      const score = scoreByUser.get(friendId) ?? {
        userId: friendId,
        rawXp: 0,
        updatedAt: "9999-12-31T00:00:00.000Z",
      };
      board.push(score);
      if (score.rawXp > 0) activeFriends += 1;
    }

    let rank: number | null = null;
    let rankCoins = 0;
    let specialItem: string | null = null;
    let weeklyTargetCoins = 0;
    const targetHit = rawXp >= targetXp;

    if (targetHit) {
      weeklyTargetCoins = targetCoins;
      if (qualifiesForRankRewards(activeFriends, rawXp, minFriends, targetXp)) {
        rank = leaderboardRank(userId, board);
        const reward = rankRewardForPlace(rank, config.leaderboard_rewards);
        if (reward) {
          rankCoins = reward.coins;
          if (winsSpecialItem(random(), reward.itemChance)) {
            specialItem = pickWeightedItem(pool, random());
            await grantSpecial(userId, specialItem, tx);
          }
        }
      }
    }

    const guildQuestCoins = guildPayoutByUser.get(userId) ?? 0;
    const coinDelta = weeklyTargetCoins + rankCoins + guildQuestCoins;
    if (coinDelta > 0) {
      await tx`update player_state set coins = coins + ${coinDelta} where user_id = ${userId}`;
    }

    const trailing = await trailing30Stats(userId, weekEnd, tx);
    if (isBalancedWeek(trailing, trailing.total)) {
      const counters = await bumpCounters(userId, { balanced_weeks: 1 }, tx);
      await applyAchievementProgress(userId, {
        badge: "balanced",
        progress: numberFrom(counters.balanced_weeks, 0),
      }, tx);
    }
    const steadyDays = await steadyDaysInWeek(userId, closingWeek, tx);
    if (isSteadyWeek(steadyDays)) {
      const counters = await bumpCounters(userId, { steady_pace_weeks: 1 }, tx);
      await applyAchievementProgress(userId, {
        badge: "steady_pace",
        progress: numberFrom(counters.steady_pace_weeks, 0),
      }, tx);
    }

    const split = await weekStatSplit(userId, closingWeek, tx);
    const bossesBeaten = await bossesBeatenInWeek(userId, closingWeek, tx);

    await tx`
      insert into inbox (user_id, type, payload)
      values (
        ${userId},
        'weekly_results',
        ${JSON.stringify({
          weekId: closingWeek,
          rawXp,
          targetHit,
          targetCoins: weeklyTargetCoins,
          activeFriends,
          rank,
          rankCoins,
          specialItem,
          guildQuestCoins,
          intellect: split.intellect,
          vitality: split.vitality,
          craft: split.craft,
          charisma: split.charisma,
          bestDay: split.bestDay,
          bestDayXp: split.bestDayXp,
          bossesBeaten,
        })}::jsonb
      )
    `;

    const pending = player.pending_rest_weekday;
    if (pending == null) {
      await tx`
        update player_state set
          weekly_raw_xp = 0,
          week_id = ${newWeek},
          boss_coins_this_week = 0
        where user_id = ${userId}
      `;
    } else {
      await tx`
        update player_state set
          weekly_raw_xp = 0,
          week_id = ${newWeek},
          boss_coins_this_week = 0,
          rest_weekday = ${numberFrom(pending, 0)},
          pending_rest_weekday = null
        where user_id = ${userId}
      `;
    }
    await tx`
      update friend_summaries set weekly_raw_xp = 0, updated_at = now()
      where user_id = ${userId}
    `;
    usersProcessed += 1;
  }

  return { users: usersProcessed, guildsPaid };
}

export async function runWeeklyReset(
  body: unknown,
  sql: Sql = getSql(),
  now = new Date(),
): Promise<{ users: number; guildsPaid: number }> {
  const config = await loadConfig();
  const parsed = inputSchema.parse(body ?? {});
  const clock = parsed.now ? new Date(parsed.now) : now;
  return await sql.begin(async (tx) =>
    runWeeklyResetDraft({}, tx as unknown as Tx, config, clock)
  );
}
