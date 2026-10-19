import { assertEquals } from "jsr:@std/assert@1";

import { closeDay, type StreakState } from "./streaks.ts";

const fresh: StreakState = {
  count: 0,
  best: 0,
  lastCountedDay: null,
  shields: 0,
  lastShieldDay: null,
  paidMilestones: [],
};

Deno.test("40 raw XP extends the streak and a quiet day breaks it", () => {
  const counted = closeDay(fresh, "2026-10-10", 40, { rest: false, paused: false });
  assertEquals(counted.state.count, 1);
  assertEquals(counted.state.best, 1);
  assertEquals(counted.state.lastCountedDay, "2026-10-10");

  const broken = closeDay(counted.state, "2026-10-11", 39, { rest: false, paused: false });
  assertEquals(broken.state.count, 0);
});

Deno.test("a rest day or a pause leaves the streak alone", () => {
  const counted = closeDay(fresh, "2026-10-10", 40, { rest: false, paused: false }).state;
  const rest = closeDay(counted, "2026-10-11", 0, { rest: true, paused: false });
  assertEquals(rest.state.count, 1);
  const paused = closeDay(counted, "2026-10-11", 0, { rest: false, paused: true });
  assertEquals(paused.state.count, 1);
});

Deno.test("a shield saves one missed day and never two in a row", () => {
  const counted = closeDay({ ...fresh, shields: 2 }, "2026-10-10", 40, { rest: false, paused: false }).state;
  const saved = closeDay(counted, "2026-10-11", 0, { rest: false, paused: false });
  assertEquals(saved.state.count, 1);
  assertEquals(saved.state.shields, 1);
  assertEquals(saved.state.lastShieldDay, "2026-10-11");

  const broken = closeDay(saved.state, "2026-10-12", 0, { rest: false, paused: false });
  assertEquals(broken.state.count, 0);
  assertEquals(broken.state.shields, 1);
});

Deno.test("milestones pay once", () => {
  let state = fresh;
  let seventh: ReturnType<typeof closeDay> | undefined;
  for (let day = 1; day <= 7; day++) {
    seventh = closeDay(state, `2026-10-${String(day).padStart(2, "0")}`, 40, { rest: false, paused: false });
    state = seventh.state;
  }
  assertEquals(seventh?.milestone, { days: 7, coins: 100 });

  const again = closeDay(state, "2026-10-08", 0, { rest: false, paused: false });
  state = { ...again.state, count: 6 };
  const repeat = closeDay(state, "2026-10-09", 40, { rest: false, paused: false });
  assertEquals(repeat.milestone, null);
  assertEquals(repeat.state.paidMilestones, [7]);
});
