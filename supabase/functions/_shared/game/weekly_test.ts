import { assertEquals } from "jsr:@std/assert@1";

import {
  isoWeekDateRange,
  leaderboardRank,
  pickWeightedItem,
  priorWeekId,
  qualifiesForRankRewards,
  rankRewardForPlace,
  winsSpecialItem,
} from "./weekly.ts";

Deno.test("priorWeekId steps back across year boundary", () => {
  assertEquals(priorWeekId("2026-W41"), "2026-W40");
  assertEquals(priorWeekId("2026-W01"), "2025-W52");
});

Deno.test("isoWeekDateRange returns Monday through Sunday", () => {
  assertEquals(isoWeekDateRange("2026-W41"), { start: "2026-10-05", end: "2026-10-11" });
});

Deno.test("qualifiesForRankRewards needs target and active friends", () => {
  assertEquals(qualifiesForRankRewards(4, 500, 4, 500), true);
  assertEquals(qualifiesForRankRewards(3, 500, 4, 500), false);
  assertEquals(qualifiesForRankRewards(4, 499, 4, 500), false);
});

Deno.test("leaderboardRank prefers higher XP then earlier updated_at", () => {
  const board = [
    { userId: "a", rawXp: 600, updatedAt: "2026-10-10T12:00:00Z" },
    { userId: "b", rawXp: 700, updatedAt: "2026-10-11T12:00:00Z" },
    { userId: "c", rawXp: 600, updatedAt: "2026-10-09T12:00:00Z" },
  ];
  assertEquals(leaderboardRank("b", board), 1);
  assertEquals(leaderboardRank("c", board), 2);
  assertEquals(leaderboardRank("a", board), 3);
});

Deno.test("rankRewardForPlace maps config pairs", () => {
  const rewards = [[300, 0.5], [200, 0.3], [150, 0.2]];
  assertEquals(rankRewardForPlace(1, rewards), { place: 1, coins: 300, itemChance: 0.5 });
  assertEquals(rankRewardForPlace(3, rewards)?.coins, 150);
  assertEquals(rankRewardForPlace(4, rewards), null);
});

Deno.test("special item helpers", () => {
  assertEquals(winsSpecialItem(0.49, 0.5), true);
  assertEquals(winsSpecialItem(0.5, 0.5), false);
  assertEquals(
    pickWeightedItem({ streak_shield: 1 }, 0.1),
    "streak_shield",
  );
});
