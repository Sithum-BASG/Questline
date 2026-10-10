import { assertEquals } from "jsr:@std/assert@1";

import {
  friendCode,
  levelFromXp,
  nextRollover,
  usernameFromDisplayName,
  weekId,
  type LevelCurve,
} from "./onboarding.ts";

const COLOMBO = "Asia/Colombo";
const curve: LevelCurve = { base: 80, coef: 5.5, exp: 1.4, roundTo: 10, maxLevel: 50 };

Deno.test("next rollover is the next 04:00 in Colombo", () => {
  const morning = new Date("2026-10-10T03:00:00+05:30");
  assertEquals(nextRollover(morning, COLOMBO).toISOString(), "2026-10-09T22:30:00.000Z");
  const afternoon = new Date("2026-10-10T10:00:00+05:30");
  assertEquals(nextRollover(afternoon, COLOMBO).toISOString(), "2026-10-10T22:30:00.000Z");
});

Deno.test("week id flips at Monday 04:00 Colombo", () => {
  assertEquals(weekId(new Date("2026-10-10T12:00:00+05:30"), COLOMBO), "2026-W41");
  assertEquals(weekId(new Date("2026-10-05T03:30:00+05:30"), COLOMBO), "2026-W40");
  assertEquals(weekId(new Date("2026-10-05T04:00:00+05:30"), COLOMBO), "2026-W41");
});

Deno.test("friend codes skip ambiguous characters", () => {
  const code = friendCode(() => 0);
  assertEquals(code, "AAAAAAAA");
  assertEquals(/^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}$/.test(friendCode(Math.random)), true);
});

Deno.test("usernames come from the display name plus 4 digits", () => {
  assertEquals(usernameFromDisplayName("Ada Lovelace", "0042"), "ada_lovelace_0042");
  assertEquals(usernameFromDisplayName("!!!", "7"), "player_0007");
});

Deno.test("80 total XP is level 2 and 79 stays level 1", () => {
  assertEquals(levelFromXp(79, curve), 1);
  assertEquals(levelFromXp(80, curve), 2);
});
