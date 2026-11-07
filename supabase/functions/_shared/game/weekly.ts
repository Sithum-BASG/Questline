/** Pure helpers for cron-weekly rank rewards and week id math. */

export type WeeklyScoreRow = {
  userId: string;
  rawXp: number;
  updatedAt: string;
};

export type RankReward = {
  place: number;
  coins: number;
  itemChance: number;
};

/** Previous ISO week id (`2026-W41` → `2026-W40`). */
export function priorWeekId(week: string): string {
  const match = /^(\d{4})-W(\d{2})$/.exec(week);
  if (!match) throw new Error(`Invalid week id: ${week}`);
  const year = Number(match[1]);
  const weekNum = Number(match[2]);
  if (weekNum > 1) return `${year}-W${String(weekNum - 1).padStart(2, "0")}`;
  // Week 1 → last ISO week of the previous year (28 Dec is always in that week).
  const dec28 = new Date(Date.UTC(year - 1, 11, 28));
  const day = dec28.getUTCDay() || 7;
  dec28.setUTCDate(dec28.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(dec28.getUTCFullYear(), 0, 1));
  const w = Math.ceil(((dec28.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7);
  return `${dec28.getUTCFullYear()}-W${String(w).padStart(2, "0")}`;
}

/** Civil Monday–Sunday dates (UTC calendar) for an ISO week id. */
export function isoWeekDateRange(week: string): { start: string; end: string } {
  const match = /^(\d{4})-W(\d{2})$/.exec(week);
  if (!match) throw new Error(`Invalid week id: ${week}`);
  const year = Number(match[1]);
  const weekNum = Number(match[2]);
  const jan4 = new Date(Date.UTC(year, 0, 4));
  const day = jan4.getUTCDay() || 7;
  const monday = new Date(jan4);
  monday.setUTCDate(jan4.getUTCDate() - day + 1 + (weekNum - 1) * 7);
  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);
  const pad = (n: number) => String(n).padStart(2, "0");
  const fmt = (d: Date) =>
    `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
  return { start: fmt(monday), end: fmt(sunday) };
}

export function qualifiesForRankRewards(
  activeFriendCount: number,
  weeklyRawXp: number,
  minFriends: number,
  targetXp: number,
): boolean {
  return weeklyRawXp >= targetXp && activeFriendCount >= minFriends;
}

/** 1-based place among the board. Ties: earlier updatedAt wins. */
export function leaderboardRank(userId: string, board: WeeklyScoreRow[]): number {
  const sorted = [...board].sort((a, b) => {
    if (b.rawXp !== a.rawXp) return b.rawXp - a.rawXp;
    return a.updatedAt.localeCompare(b.updatedAt);
  });
  const index = sorted.findIndex((row) => row.userId === userId);
  return index < 0 ? board.length + 1 : index + 1;
}

/** Rewards for places 1–3 from `leaderboard_rewards` config pairs [coins, chance]. */
export function rankRewardForPlace(
  place: number,
  rewards: unknown,
): RankReward | null {
  if (!Array.isArray(rewards) || place < 1 || place > 3) return null;
  const entry = rewards[place - 1];
  if (!Array.isArray(entry) || entry.length < 2) return null;
  const coins = Number(entry[0]);
  const itemChance = Number(entry[1]);
  if (!Number.isFinite(coins) || !Number.isFinite(itemChance)) return null;
  return { place, coins, itemChance };
}

export function pickWeightedItem(pool: Record<string, number>, roll: number): string {
  let cursor = 0;
  const entries = Object.entries(pool);
  for (const [id, weight] of entries) {
    cursor += Number(weight) || 0;
    if (roll < cursor) return id;
  }
  return entries[0]?.[0] ?? "streak_shield";
}

export function winsSpecialItem(roll: number, chance: number): boolean {
  return roll < chance;
}
