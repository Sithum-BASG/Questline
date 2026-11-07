import { defaultCurve, levelFromXp, totalForLevel } from "./rewards.ts";
import { defaultXpRates, sessionXp } from "./xp.ts";

/** Numbers mirrored from `game_config` / schema defaults (display + sim only). */
export const balanceConfig = {
  chestCost: 500,
  weeklyTargetRawXp: 500,
  weeklyTargetCoins: 200,
  bossWeeklyCoinCap: 600,
  minionCoins: 100,
};

export interface BalanceAssumptions {
  minutesPerDay: number;
  daysPerWeek: number;
  weeks: number;
  difficulty: number;
  minionBossesPerWeek: number;
}

export interface BalanceResult {
  weeklyRawXp: number;
  weeksToLevel: Record<number, number | null>;
  levelAtWeek12: number;
  chestsOpened: number;
  averageWeeksPerChest: number | null;
  coinsEarned: number;
}

const defaultAssumptions: BalanceAssumptions = {
  minutesPerDay: 120,
  daysPerWeek: 6,
  weeks: 12,
  difficulty: 3,
  minionBossesPerWeek: 1,
};

/**
 * Pace from plan 15.2: 2 h/day, 6 days/week, 12 weeks.
 * Coins: weekly target when raw XP clears the bar, plus one minion boss/week.
 * Chests open whenever the balance covers `chestCost`.
 */
export function runBalanceSimulation(
  assumptions: Partial<BalanceAssumptions> = {},
  config: typeof balanceConfig = balanceConfig,
): BalanceResult {
  const opts = { ...defaultAssumptions, ...assumptions };
  const day = sessionXp({
    difficulty: opts.difficulty,
    estimatedMinutes: opts.minutesPerDay,
    verifiedMinutes: opts.minutesPerDay,
    mode: "focus",
    dated: true,
    onTime: true,
    rates: defaultXpRates,
  });
  const weeklyRawXp = day.raw * opts.daysPerWeek;
  const weeklyFinalXp = day.final * opts.daysPerWeek;

  let xpTotal = 0;
  let coins = 0;
  let chestsOpened = 0;
  const weeksToLevel: Record<number, number | null> = { 10: null, 25: null };

  for (let week = 1; week <= opts.weeks; week++) {
    xpTotal += weeklyFinalXp;
    if (weeklyRawXp >= config.weeklyTargetRawXp) coins += config.weeklyTargetCoins;
    const bossPay = Math.min(
      config.minionCoins * opts.minionBossesPerWeek,
      config.bossWeeklyCoinCap,
    );
    coins += bossPay;

    while (coins >= config.chestCost) {
      coins -= config.chestCost;
      chestsOpened += 1;
    }

    const level = levelFromXp(xpTotal, defaultCurve);
    for (const target of [10, 25]) {
      if (weeksToLevel[target] == null && level >= target) weeksToLevel[target] = week;
    }
  }

  return {
    weeklyRawXp,
    weeksToLevel,
    levelAtWeek12: levelFromXp(xpTotal, defaultCurve),
    chestsOpened,
    averageWeeksPerChest: chestsOpened > 0 ? opts.weeks / chestsOpened : null,
    coinsEarned: chestsOpened * config.chestCost + coins,
  };
}

export function expectedTotals(): { l10: number; l25: number } {
  return { l10: totalForLevel(10, defaultCurve), l25: totalForLevel(25, defaultCurve) };
}
