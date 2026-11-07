import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { sessionXp } from "./game/xp.ts";
import { runRolloverDraft } from "./rollover.ts";

const userId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

type DayScript = {
  label: string;
  /** Game day that closes at this rollover (YYYY-MM-DD). */
  closingDay: string;
  /** Instant of the 04:00 rollover that closes [closingDay]. */
  now: string;
  rawXp: number;
  restWeekday?: number | null;
  pauseActive?: boolean;
  expectStreak: number;
  expectComeback?: boolean;
  expectShields?: number;
};

/**
 * 10-day streak path (plan 8.3): met, met, shield, rest, met, pause, miss×3 (comeback), met.
 * Comes through runRolloverDraft with a faked clock each day.
 */
Deno.test("10-day rollover simulation: streak path and comeback 2×", async () => {
  const state: Record<string, unknown> = {
    user_id: userId,
    coins: 0,
    streak_count: 0,
    streak_best: 0,
    streak_last_counted_day: null,
    shields: 1,
    last_shield_day: null,
    milestones_paid: [],
    free_chests: 0,
    owned_titles: [],
    inactive_days: 0,
    comeback_armed: false,
    timezone: "UTC",
    rest_weekday: 3, // Wednesday = closing day 2026-10-14
    pause_active: false,
    pause_until: null,
    next_rollover_at: "2026-10-11T04:00:00.000Z",
  };

  let dayRawXp = 0;
  const days: DayScript[] = [
    { label: "met", closingDay: "2026-10-10", now: "2026-10-11T04:00:00.000Z", rawXp: 40, expectStreak: 1 },
    { label: "met", closingDay: "2026-10-11", now: "2026-10-12T04:00:00.000Z", rawXp: 40, expectStreak: 2 },
    { label: "shield", closingDay: "2026-10-12", now: "2026-10-13T04:00:00.000Z", rawXp: 0, expectStreak: 2, expectShields: 0 },
    { label: "met-before-rest", closingDay: "2026-10-13", now: "2026-10-14T04:00:00.000Z", rawXp: 40, expectStreak: 3 },
    { label: "rest", closingDay: "2026-10-14", now: "2026-10-15T04:00:00.000Z", rawXp: 0, restWeekday: 3, expectStreak: 3 },
    { label: "pause", closingDay: "2026-10-15", now: "2026-10-16T04:00:00.000Z", rawXp: 0, pauseActive: true, expectStreak: 3 },
    { label: "miss1", closingDay: "2026-10-16", now: "2026-10-17T04:00:00.000Z", rawXp: 0, expectStreak: 0 },
    { label: "miss2", closingDay: "2026-10-17", now: "2026-10-18T04:00:00.000Z", rawXp: 0, expectStreak: 0 },
    { label: "miss3-comeback", closingDay: "2026-10-18", now: "2026-10-19T04:00:00.000Z", rawXp: 0, expectStreak: 0, expectComeback: true },
    { label: "met-after-comeback", closingDay: "2026-10-19", now: "2026-10-20T04:00:00.000Z", rawXp: 40, expectStreak: 1, expectComeback: true },
  ];

  // 10 met, 11 met, 12 shield, 13 met, 14 rest, 15 pause, 16–18 miss, 19 met
  for (const day of days) {
    dayRawXp = day.rawXp;
    if (day.restWeekday !== undefined) state.rest_weekday = day.restWeekday;
    state.pause_active = day.pauseActive === true;
    state.next_rollover_at = day.now;

    const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
      const text = strings.join(" ");
      if (text.includes("from player_state") && text.includes("next_rollover_at")) {
        return Promise.resolve([{ ...state }]);
      }
      if (text.includes("from daily_stats")) {
        return Promise.resolve([{
          raw_xp: dayRawXp,
          rest_day: day.label === "rest",
          paused: day.label === "pause",
        }]);
      }
      if (text.includes("from bosses") || text.includes("from profiles")) {
        return Promise.resolve(text.includes("from profiles") ? [{ hide_radar: false }] : []);
      }
      if (text.includes("update player_state set")) {
        // Interleaved ${} values only — ai_calls_today / focus_minutes_today are SQL literals.
        state.streak_count = values[0];
        state.streak_best = values[1];
        state.streak_last_counted_day = values[2];
        state.shields = values[3];
        state.last_shield_day = values[4];
        state.milestones_paid = values[5];
        state.coins = values[6];
        state.free_chests = values[7];
        state.owned_titles = values[8];
        state.inactive_days = values[9];
        state.comeback_armed = values[10];
        state.pause_active = values[11];
        state.next_rollover_at = values[12];
      }
      return Promise.resolve([]);
    };

    const result = await runRolloverDraft(
      { now: day.now },
      tx,
      defaults,
      new Date(day.now),
    );
    assertEquals(result.processed, 1, day.label);
    assertEquals(state.streak_count, day.expectStreak, `${day.label} streak`);
    if (day.expectShields != null) {
      assertEquals(state.shields, day.expectShields, `${day.label} shields`);
    }
    if (day.expectComeback != null) {
      assertEquals(state.comeback_armed, day.expectComeback, `${day.label} comeback`);
    }
  }

  assertEquals(state.comeback_armed, true);
  const withComeback = sessionXp({
    difficulty: 4,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    dated: true,
    onTime: true,
    comebackArmed: true,
  });
  const without = sessionXp({
    difficulty: 4,
    estimatedMinutes: 60,
    verifiedMinutes: 60,
    mode: "focus",
    dated: true,
    onTime: true,
    comebackArmed: false,
  });
  assertEquals(without.raw, 86);
  assertEquals(withComeback.raw, 86);
  assertEquals(withComeback.final, 172);
  assertEquals(without.final, 86);
});
