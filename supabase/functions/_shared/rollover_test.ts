import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { runRolloverDraft } from "./rollover.ts";

const userId = "11111111-1111-1111-1111-111111111111";

function scripted(options: {
  rawXp?: number;
  streak?: number;
  shields?: number;
  restWeekday?: number | null;
  pauseActive?: boolean;
  inactive?: number;
  bosses?: { id: string; status?: string; damage: number; max_hp: number; last_work_day: string | null }[];
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const state = {
    user_id: userId,
    coins: 0,
    streak_count: options.streak ?? 0,
    streak_best: options.streak ?? 0,
    streak_last_counted_day: null,
    shields: options.shields ?? 0,
    last_shield_day: null,
    milestones_paid: [],
    free_chests: 0,
    owned_titles: [],
    inactive_days: options.inactive ?? 0,
    comeback_armed: false,
    timezone: "UTC",
    rest_weekday: options.restWeekday ?? null,
    pause_active: options.pauseActive ?? false,
    pause_until: null,
    next_rollover_at: "2026-10-11T04:00:00.000Z",
  };

  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from player_state") && text.includes("next_rollover_at")) {
      return Promise.resolve([state]);
    }
    if (text.includes("from daily_stats")) {
      return Promise.resolve([{ raw_xp: options.rawXp ?? 0, rest_day: false, paused: false }]);
    }
    if (text.includes("from bosses")) {
      return Promise.resolve(
        (options.bosses ?? []).map((boss) => ({ status: "active", ...boss })),
      );
    }
    if (text.includes("from profiles")) {
      return Promise.resolve([{ hide_radar: false }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries, state };
}

Deno.test("a met day extends the streak and resets daily counters", async () => {
  const { tx, queries } = scripted({ rawXp: 40, streak: 2 });
  const result = await runRolloverDraft(
    { now: "2026-10-11T04:00:00.000Z" },
    tx,
    defaults,
    new Date("2026-10-11T04:00:00.000Z"),
  );
  assertEquals(result.processed, 1);
  const update = queries.find((query) => query.text.includes("update player_state set"));
  assertEquals(update?.values.includes(3), true); // streak_count
  assertEquals(update?.values.includes(0), true); // ai / focus reset present
});

Deno.test("three quiet days arm comeback", async () => {
  const { tx, queries } = scripted({ rawXp: 0, inactive: 2 });
  await runRolloverDraft(
    { now: "2026-10-11T04:00:00.000Z" },
    tx,
    defaults,
    new Date("2026-10-11T04:00:00.000Z"),
  );
  const update = queries.find((query) => query.text.includes("update player_state set"));
  assertEquals(update?.values.includes(true), true); // comeback_armed
  assertEquals(update?.values.includes(3), true); // inactive_days
});

Deno.test("an active boss heals when the day was idle", async () => {
  const { tx, queries } = scripted({
    rawXp: 0,
    bosses: [{ id: "b1", damage: 100, max_hp: 100, last_work_day: "2026-10-09" }],
  });
  await runRolloverDraft(
    { now: "2026-10-11T04:00:00.000Z" },
    tx,
    defaults,
    new Date("2026-10-11T04:00:00.000Z"),
  );
  assertEquals(queries.some((query) => query.text.includes("update bosses set damage")), true);
});
