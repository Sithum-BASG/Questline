import { assertEquals } from "jsr:@std/assert@1";

import { dayKey, nextRollover, weekId } from "./time.ts";

Deno.test("the game day flips at 04:00, including midnight", () => {
  const zone = "Asia/Colombo";
  assertEquals(dayKey(new Date("2026-10-10T03:59:00+05:30"), zone), "2026-10-09");
  assertEquals(dayKey(new Date("2026-10-10T04:00:00+05:30"), zone), "2026-10-10");
  assertEquals(dayKey(new Date("2026-10-10T00:00:00+05:30"), zone), "2026-10-09");
});

Deno.test("week ids and the next rollover stay on the Colombo clock", () => {
  const zone = "Asia/Colombo";
  assertEquals(nextRollover(new Date("2026-10-10T03:00:00+05:30"), zone).toISOString(), "2026-10-09T22:30:00.000Z");
  assertEquals(weekId(new Date("2026-10-05T03:30:00+05:30"), zone), "2026-W40");
  assertEquals(weekId(new Date("2026-10-05T04:00:00+05:30"), zone), "2026-W41");
});

Deno.test("a daylight-saving jump still changes the day at local 04:00", () => {
  const zone = "Europe/London";
  assertEquals(dayKey(new Date("2026-03-29T03:59:00+01:00"), zone), "2026-03-28");
  assertEquals(dayKey(new Date("2026-03-29T04:00:00+01:00"), zone), "2026-03-29");
  assertEquals(dayKey(new Date("2026-10-25T00:30:00+01:00"), zone), "2026-10-24");
  assertEquals(dayKey(new Date("2026-10-25T00:30:00+00:00"), zone), "2026-10-24");
});
