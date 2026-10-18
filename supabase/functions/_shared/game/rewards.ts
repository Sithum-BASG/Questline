import { roundHalfUp } from "./round.ts";

export type LevelCurve = { base: number; coef: number; exp: number; roundTo: number; maxLevel: number };

export const defaultCurve: LevelCurve = { base: 80, coef: 5.5, exp: 1.4, roundTo: 10, maxLevel: 50 };

/// XP to go from level-1 to level. Same curve as the overview, indexed by the destination level.
export function xpForLevel(level: number, curve: LevelCurve = defaultCurve): number {
  if (level < 2) return 0;
  const raw = curve.base + curve.coef * (level - 2) ** curve.exp;
  return roundHalfUp(raw / curve.roundTo) * curve.roundTo;
}

export function totalForLevel(level: number, curve: LevelCurve = defaultCurve): number {
  let total = 0;
  for (let next = 2; next <= Math.min(level, curve.maxLevel); next++) total += xpForLevel(next, curve);
  return total;
}

export function levelFromXp(xp: number, curve: LevelCurve = defaultCurve): number {
  let level = 1;
  for (let next = 2; next <= curve.maxLevel; next++) {
    if (totalForLevel(next, curve) <= xp) level = next;
    else break;
  }
  return level;
}

export interface LevelRewardRow {
  level: number;
  rewards: unknown[];
}

/// Every reward from the levels crossed, lowest level first.
export function rewardsForLevels(fromLevel: number, toLevel: number, table: LevelRewardRow[]): unknown[] {
  return table
    .filter((row) => row.level > fromLevel && row.level <= toLevel)
    .sort((left, right) => left.level - right.level)
    .flatMap((row) => row.rewards);
}
