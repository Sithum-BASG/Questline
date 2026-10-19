import { roundHalfUp } from "./round.ts";

export type BossTierName = "minion" | "brute" | "warlord" | "titan";

export interface BossTier {
  tier: BossTierName;
  coins: number;
}

const tiers: [BossTierName, number, number][] = [
  ["minion", 4, 100],
  ["brute", 12, 150],
  ["warlord", 25, 200],
  ["titan", Number.POSITIVE_INFINITY, 300],
];

export function bossTier(hours: number): BossTier {
  const match = tiers.find(([, below]) => hours < below) ?? tiers[tiers.length - 1];
  return { tier: match[0], coins: match[2] };
}

export function maxHp(hours: number): number {
  return roundHalfUp(hours * 60);
}

export function raidMaxHp(perPersonMinutes: number, participants: number): number {
  return perPersonMinutes * participants;
}

/// Activity and tick sessions deal no damage. Boss Slayer adds 20% on a focus session.
export function sessionDamage(minutes: number, mode: "focus" | "activity" | "tick", bossSlayer: boolean): number {
  if (mode !== "focus") return 0;
  return roundHalfUp(minutes * (bossSlayer ? 1.2 : 1));
}

export interface BossHealth {
  status: string;
  damage: number;
  maxHp: number;
  lastWorkDay: string | null;
  staggered: boolean;
}

/// Heal 3% of max HP when the boss was not worked that day. A staggered boss does not heal.
export function healBoss(
  boss: BossHealth,
  closedDay: string,
  options: { rest: boolean; paused: boolean; rate?: number },
): number {
  if (boss.staggered || boss.status !== "active" || options.rest || options.paused || boss.lastWorkDay === closedDay) {
    return boss.damage;
  }
  const healed = roundHalfUp((options.rate ?? 0.03) * boss.maxHp);
  return Math.max(0, boss.damage - healed);
}

export function soloLoot(
  ratio: number,
  tierCoins: number,
  options: { weeklyCoins: number; coinsEligible: boolean; weeklyCap?: number; fullThreshold?: number },
): { loot: "full" | "half"; coins: number } {
  const full = ratio >= (options.fullThreshold ?? 0.75);
  if (!options.coinsEligible) return { loot: full ? "full" : "half", coins: 0 };
  const raw = tierCoins * (full ? 1 : 0.5);
  const room = Math.max(0, (options.weeklyCap ?? 600) - options.weeklyCoins);
  return { loot: full ? "full" : "half", coins: Math.min(raw, room) };
}

export function raidResult(damage: number, hp: number, beforeDeadline: boolean): "victory" | "narrow_win" | "escaped" {
  if (beforeDeadline && damage >= hp) return "victory";
  if (hp > 0 && damage / hp >= 0.75) return "narrow_win";
  return "escaped";
}

export function metFairShare(damage: number, hp: number, participants: number): boolean {
  if (participants <= 0) return false;
  return damage >= 0.5 * hp / participants;
}

export function raidLoot(fairShare: boolean, result: "victory" | "narrow_win" | "escaped", coins: number): number {
  if (!fairShare || result === "escaped") return 0;
  return roundHalfUp(coins * (result === "victory" ? 1.25 : 0.5));
}

export function applyEscapePenalty(coins: number, escaped: boolean, fairShare: boolean): number {
  if (!escaped || fairShare) return coins;
  return Math.max(0, coins - 100);
}

export function mvp(members: { id: string; damage: number }[]): string | null {
  let best: { id: string; damage: number } | null = null;
  for (const member of members) {
    if (!best || member.damage > best.damage) best = member;
  }
  return best?.id ?? null;
}

export function mvpWinsItem(roll: number, chance = 0.3): boolean {
  return roll < chance;
}
