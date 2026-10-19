import { assertEquals } from "jsr:@std/assert@1";

import { sessionXp } from "./xp.ts";

Deno.test("the documented XP cases", () => {
  assertEquals(sessionXp({
    difficulty: 4,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    dated: true,
    onTime: true,
  }).raw, 86);

  assertEquals(sessionXp({
    difficulty: 4,
    estimatedMinutes: 60,
    verifiedMinutes: 0,
    mode: "tick",
  }).raw, 39);

  assertEquals(sessionXp({
    difficulty: 3,
    estimatedMinutes: 30,
    verifiedMinutes: 90,
    mode: "focus",
  }).raw, 45);

  assertEquals(sessionXp({
    difficulty: 2,
    estimatedMinutes: 40,
    verifiedMinutes: 60,
    mode: "activity",
  }).raw, 24);

  assertEquals(sessionXp({
    difficulty: 3,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    dated: true,
    onTime: false,
    overdueDays: 3,
  }).raw, 42);

  assertEquals(sessionXp({
    difficulty: 3,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    dated: true,
    onTime: false,
    overdueDays: 8,
  }).raw, 30);
});

Deno.test("focus past 8 hours earns nothing more", () => {
  const full = sessionXp({
    difficulty: 4,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    focusMinutesToday: 480,
  });
  assertEquals(full.countedMinutes, 0);
  assertEquals(full.raw, 0);

  const tail = sessionXp({
    difficulty: 1,
    estimatedMinutes: 60,
    verifiedMinutes: 20,
    mode: "focus",
    focusMinutesToday: 470,
  });
  assertEquals(tail.countedMinutes, 10);
  assertEquals(tail.raw, 5);
});

Deno.test("a reschedule penalty is skipped when a scroll was used", () => {
  const penalised = sessionXp({
    difficulty: 3,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    rescheduled: true,
  });
  const scrolled = sessionXp({
    difficulty: 3,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    rescheduled: true,
    scrollUsed: true,
  });
  assertEquals(penalised.raw, 48);
  assertEquals(scrolled.raw, 60);
});

Deno.test("comeback wins over a potion and gear stays inside the cap", () => {
  const result = sessionXp({
    difficulty: 3,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    gearBoost: 0.4,
    deepFocus: true,
    potion: true,
    comebackArmed: true,
  });
  assertEquals(result.raw, 60);
  assertEquals(result.final, 162);
});
