import { assertEquals, assertGreaterOrEqual, assertLessOrEqual } from "jsr:@std/assert@1";

import { expectedTotals, runBalanceSimulation } from "./balance_simulation.ts";

Deno.test("12-week pace hits L10 ~1.5 weeks and L25 ~8–9 weeks", () => {
  const result = runBalanceSimulation();
  const totals = expectedTotals();
  assertEquals(totals.l10, 1110);
  assertEquals(totals.l25, 6390);

  // ~750–800 raw XP/week from 2 h × 6 days at difficulty 3 on time.
  assertGreaterOrEqual(result.weeklyRawXp, 700);
  assertLessOrEqual(result.weeklyRawXp, 850);

  const to10 = result.weeksToLevel[10];
  const to25 = result.weeksToLevel[25];
  assertEquals(to10 != null, true);
  assertEquals(to25 != null, true);
  assertGreaterOrEqual(to10!, 1);
  assertLessOrEqual(to10!, 2);
  assertGreaterOrEqual(to25!, 7);
  assertLessOrEqual(to25!, 10);
  assertGreaterOrEqual(result.levelAtWeek12, 25);
});

Deno.test("chest cadence is about one every 1–1.5 weeks at that pace", () => {
  const result = runBalanceSimulation();
  assertGreaterOrEqual(result.chestsOpened, 6);
  assertLessOrEqual(result.chestsOpened, 12);
  assertEquals(result.averageWeeksPerChest != null, true);
  assertGreaterOrEqual(result.averageWeeksPerChest!, 1);
  assertLessOrEqual(result.averageWeeksPerChest!, 2);
});
