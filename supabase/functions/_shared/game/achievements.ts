import { zonedParts } from "./time.ts";

export type BadgeId =
  | "deep_worker"
  | "boss_hunter"
  | "team_player"
  | "unbroken"
  | "balanced"
  | "early_bird"
  | "steady_pace"
  | "punctual";

export const badgeThresholds: Record<BadgeId, [number, number, number]> = {
  deep_worker: [10, 50, 200],
  boss_hunter: [1, 10, 40],
  team_player: [1, 5, 20],
  unbroken: [7, 30, 100],
  balanced: [1, 4, 12],
  early_bird: [5, 25, 100],
  steady_pace: [1, 4, 12],
  punctual: [10, 50, 200],
};

const tierCoins = [50, 100, 200];

export interface TierReward {
  tier: number;
  coins: number;
  title?: string;
}

/// Rewards for tiers crossed by moving from [previousTier] to the tier [value] now reaches.
export function tierRewards(badge: BadgeId, previousTier: number, value: number): TierReward[] {
  const thresholds = badgeThresholds[badge];
  const reached = thresholds.filter((threshold) => value >= threshold).length;
  const rewards: TierReward[] = [];
  for (let tier = previousTier + 1; tier <= reached; tier++) {
    const reward: TierReward = { tier, coins: tierCoins[tier - 1] };
    if (tier === 3) reward.title = `title_${badge}`;
    rewards.push(reward);
  }
  return rewards;
}

/// A session that starts at or after 04:00 and before 08:00 local.
export function isEarlyBird(start: Date, timeZone: string): boolean {
  const hour = zonedParts(start, timeZone).hour;
  return hour >= 4 && hour < 8;
}

export interface StatXp {
  intellect: number;
  vitality: number;
  craft: number;
  charisma: number;
}

/// Every stat is at least 15% of the trailing 30-day XP.
export function isBalancedWeek(stats: StatXp, trailingXp: number): boolean {
  if (trailingXp <= 0) return false;
  return [stats.intellect, stats.vitality, stats.craft, stats.charisma].every((xp) => xp >= 0.15 * trailingXp);
}

export function isSteadyWeek(daysWithSessions: number): boolean {
  return daysWithSessions >= 5;
}
