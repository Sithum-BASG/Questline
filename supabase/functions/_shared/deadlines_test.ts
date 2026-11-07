import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { runDeadlinesDraft } from "./deadlines.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const bossId = "44444444-4444-4444-4444-444444444444";
const sessionId = "33333333-3333-3333-3333-333333333333";
const now = new Date("2026-10-10T12:00:00.000Z");

Deno.test("overdue bosses escape with a 100 coin penalty and inbox entry", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from bosses")) {
      return Promise.resolve([{
        id: bossId,
        user_id: userId,
        name: "The Practice Shade",
        tier: "minion",
        max_hp: 120,
        damage: 10,
      }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ coins: 150 }]);
    }
    if (text.includes("from sessions")) {
      return Promise.resolve([]);
    }
    if (text.includes("from raids") && text.includes("status = 'active'")) {
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };

  const result = await runDeadlinesDraft({}, tx, defaults, now);
  assertEquals(result.escaped, 1);
  assertEquals(queries.some((query) => query.text.includes("status = 'escaped'")), true);
  assertEquals(queries.some((query) => query.values.includes(50)), true);
  assertEquals(queries.some((query) => query.text.includes("boss_result")), true);
});

Deno.test("sessions older than 3x estimate are closed as broken", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from bosses")) return Promise.resolve([]);
    if (text.includes("from sessions")) {
      return Promise.resolve([{
        id: sessionId,
        user_id: userId,
        started_at: new Date(now.getTime() - 4 * 60 * 60 * 1000).toISOString(),
        est_minutes: 60,
      }]);
    }
    if (text.includes("from raids") && text.includes("status = 'active'")) {
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };

  const result = await runDeadlinesDraft({}, tx, defaults, now);
  assertEquals(result.sessionsClosed, 1);
  assertEquals(queries.some((query) => query.text.includes("status = 'broken'")), true);
});
