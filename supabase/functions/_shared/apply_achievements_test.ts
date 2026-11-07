import { assertEquals } from "jsr:@std/assert@1";

import { applyAchievementProgress, bumpCounters } from "./apply_achievements.ts";

const userId = "11111111-1111-1111-1111-111111111111";

Deno.test("applyAchievementProgress pays newly crossed tiers once", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });
    if (text.includes("from achievements")) {
      return Promise.resolve([{ progress: 0, tier: 0 }]);
    }
    return Promise.resolve([]);
  };

  const paid = await applyAchievementProgress(userId, { badge: "boss_hunter", progress: 10 }, tx);
  assertEquals(paid.coins, 150);
  assertEquals(queries.some((q) => q.text.includes("insert into achievements")), true);
  assertEquals(queries.filter((q) => q.text.includes("'badge'")).length, 2);
});

Deno.test("bumpCounters merges deltas into player_state counters", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });
    if (text.includes("select counters")) {
      return Promise.resolve([{ counters: { focus_minutes: 30, bosses_defeated: 1 } }]);
    }
    return Promise.resolve([]);
  };

  const next = await bumpCounters(userId, { focus_minutes: 60 }, tx);
  assertEquals(next.focus_minutes, 90);
  assertEquals(next.bosses_defeated, 1);
  assertEquals(queries.some((q) => q.text.includes("update player_state set counters")), true);
});
