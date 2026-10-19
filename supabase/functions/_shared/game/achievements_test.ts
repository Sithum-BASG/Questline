import { assertEquals } from "jsr:@std/assert@1";

import { isBalancedWeek, isEarlyBird, isSteadyWeek, tierRewards } from "./achievements.ts";

Deno.test("each badge tier pays the documented coins and the third tier adds the title", () => {
  assertEquals(tierRewards("deep_worker", 0, 9), []);
  assertEquals(tierRewards("deep_worker", 0, 10), [{ tier: 1, coins: 50 }]);
  assertEquals(tierRewards("boss_hunter", 0, 10), [{ tier: 1, coins: 50 }, { tier: 2, coins: 100 }]);
  assertEquals(tierRewards("punctual", 0, 200), [
    { tier: 1, coins: 50 },
    { tier: 2, coins: 100 },
    { tier: 3, coins: 200, title: "title_punctual" },
  ]);
  assertEquals(tierRewards("unbroken", 2, 100), [{ tier: 3, coins: 200, title: "title_unbroken" }]);
  assertEquals(tierRewards("team_player", 1, 4), []);
  assertEquals(tierRewards("balanced", 0, 1)[0].tier, 1);
  assertEquals(tierRewards("steady_pace", 0, 4).length, 2);
  assertEquals(tierRewards("early_bird", 0, 5)[0].coins, 50);
});

Deno.test("early bird is a session that starts from 4 a.m. and before 8 a.m.", () => {
  const zone = "Asia/Colombo";
  assertEquals(isEarlyBird(new Date("2026-10-10T03:59:00+05:30"), zone), false);
  assertEquals(isEarlyBird(new Date("2026-10-10T04:00:00+05:30"), zone), true);
  assertEquals(isEarlyBird(new Date("2026-10-10T07:59:00+05:30"), zone), true);
  assertEquals(isEarlyBird(new Date("2026-10-10T08:00:00+05:30"), zone), false);
});

Deno.test("balanced weeks need every stat, and a steady week needs five days", () => {
  assertEquals(isBalancedWeek({ intellect: 15, vitality: 15, craft: 15, charisma: 15 }, 100), true);
  assertEquals(isBalancedWeek({ intellect: 14, vitality: 15, craft: 15, charisma: 15 }, 100), false);
  assertEquals(isBalancedWeek({ intellect: 0, vitality: 0, craft: 0, charisma: 0 }, 0), false);
  assertEquals(isSteadyWeek(5), true);
  assertEquals(isSteadyWeek(4), false);
});
