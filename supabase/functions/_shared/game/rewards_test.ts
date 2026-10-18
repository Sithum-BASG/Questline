import { assertEquals } from "jsr:@std/assert@1";

import { levelFromXp, rewardsForLevels, totalForLevel, xpForLevel, type LevelCurve } from "./rewards.ts";

const curve: LevelCurve = { base: 80, coef: 5.5, exp: 1.4, roundTo: 10, maxLevel: 50 };

Deno.test("level totals match the documented table", () => {
  assertEquals(xpForLevel(2, curve), 80);
  assertEquals(totalForLevel(2, curve), 80);
  assertEquals(totalForLevel(5, curve), 370);
  assertEquals(totalForLevel(10, curve), 1110);
  assertEquals(totalForLevel(15, curve), 2310);
  assertEquals(totalForLevel(20, curve), 4040);
  assertEquals(totalForLevel(25, curve), 6390);
  assertEquals(totalForLevel(30, curve), 9420);
  assertEquals(totalForLevel(35, curve), 13170);
  assertEquals(totalForLevel(40, curve), 17730);
  assertEquals(totalForLevel(45, curve), 23110);
  assertEquals(totalForLevel(50, curve), 29360);
  assertEquals(levelFromXp(79, curve), 1);
  assertEquals(levelFromXp(80, curve), 2);
  assertEquals(levelFromXp(29360, curve), 50);
});

Deno.test("a multi-level jump grants every reward in order", () => {
  const table = [
    { level: 4, rewards: ["skin"] },
    { level: 2, rewards: ["frame"] },
    { level: 3, rewards: ["title"] },
    { level: 5, rewards: ["gear"] },
  ];
  assertEquals(rewardsForLevels(1, 4, table), ["frame", "title", "skin"]);
  assertEquals(rewardsForLevels(4, 4, table), []);
});
