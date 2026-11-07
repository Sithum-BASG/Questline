import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { runWeeklyResetDraft } from "./weekly_reset.ts";

const userA = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const userB = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const userC = "cccccccc-cccc-cccc-cccc-cccccccccccc";
const userD = "dddddddd-dddd-dddd-dddd-dddddddddddd";
const userE = "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee";
const guildId = "gggggggg-gggg-gggg-gggg-gggggggggggg";

Deno.test("runWeeklyResetDraft pays target, top rank and guild quest then resets week", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });

    if (text.includes("from weekly_scores")) {
      return Promise.resolve([
        { user_id: userA, raw_xp: 800, updated_at: "2026-10-10T10:00:00Z" },
        { user_id: userB, raw_xp: 600, updated_at: "2026-10-10T11:00:00Z" },
        { user_id: userC, raw_xp: 550, updated_at: "2026-10-10T12:00:00Z" },
        { user_id: userD, raw_xp: 520, updated_at: "2026-10-10T13:00:00Z" },
        { user_id: userE, raw_xp: 510, updated_at: "2026-10-10T14:00:00Z" },
      ]);
    }
    if (text.includes("from player_state") && text.includes("pending_rest_weekday")) {
      return Promise.resolve([
        { user_id: userA, pending_rest_weekday: 0 },
        { user_id: userB, pending_rest_weekday: null },
        { user_id: userC, pending_rest_weekday: null },
        { user_id: userD, pending_rest_weekday: null },
        { user_id: userE, pending_rest_weekday: null },
      ]);
    }
    if (text.includes("from guilds")) {
      return Promise.resolve([
        { id: guildId, quest_progress: 5000, quest_goal: 5000, quest_week_id: "2026-W41" },
      ]);
    }
    if (text.includes("from guild_members")) {
      return Promise.resolve([
        { user_id: userA, quest_contribution: 250 },
        { user_id: userB, quest_contribution: 50 },
      ]);
    }
    if (text.includes("from friendships")) {
      const uid = String(values[0]);
      const friends = {
        [userA]: [userB, userC, userD, userE],
        [userB]: [userA, userC, userD, userE],
        [userC]: [userA, userB, userD, userE],
        [userD]: [userA, userB, userC, userE],
        [userE]: [userA, userB, userC, userD],
      }[uid] ?? [];
      return Promise.resolve(friends.map((friend_id) => ({ friend_id })));
    }
    if (text.includes("from daily_stats") && text.includes("count(*)")) {
      return Promise.resolve([{ n: 5 }]);
    }
    if (text.includes("from daily_stats") && text.includes("xp_intellect")) {
      return Promise.resolve([
        {
          day: "2026-10-06",
          xp_intellect: 100,
          xp_vitality: 100,
          xp_craft: 100,
          xp_charisma: 100,
          raw_xp: 400,
        },
      ]);
    }
    if (text.includes("from bosses")) {
      return Promise.resolve([{ n: 1 }]);
    }
    if (text.includes("from achievements")) {
      return Promise.resolve([{ progress: 0, tier: 0 }]);
    }
    if (text.includes("select counters from player_state")) {
      return Promise.resolve([{ counters: { balanced_weeks: 0, steady_pace_weeks: 0 } }]);
    }
    return Promise.resolve([]);
  };

  // Always miss special-item rolls so coin math stays deterministic.
  const result = await runWeeklyResetDraft(
    {},
    tx,
    defaults as never,
    new Date("2026-10-12T04:00:00+05:30"),
    () => 0.99,
  );

  assertEquals(result.users, 5);
  assertEquals(result.guildsPaid, 1);

  const coinUpdates = queries.filter((q) =>
    q.text.includes("update player_state set coins = coins +")
  );
  // A: 200 target + 300 rank1 + 100 guild = 600
  assertEquals(
    coinUpdates.some((q) => q.values.includes(userA) && q.values.includes(600)),
    true,
  );

  assertEquals(queries.some((q) => q.text.includes("weekly_results")), true);
  assertEquals(queries.some((q) => q.text.includes("rest_weekday")), true);
  assertEquals(queries.some((q) => q.text.includes("boss_coins_this_week = 0")), true);
  assertEquals(
    queries.some((q) => q.text.includes("update guilds set quest_week_id")),
    true,
  );
  assertEquals(
    queries.some((q) => q.text.includes("insert into achievements")),
    true,
  );
});
