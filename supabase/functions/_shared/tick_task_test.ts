import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { tickDraft } from "./tick_task.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const taskId = "22222222-2222-2222-2222-222222222222";

function scripted(status = "open") {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from tasks")) {
      return Promise.resolve([{
        difficulty: 4,
        est_minutes: 60,
        stat: "intellect",
        status,
        xp_raw: status === "done" ? 39 : null,
        xp_final: status === "done" ? 39 : null,
      }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ timezone: "Asia/Colombo", week_id: "2026-W43", weekly_raw_xp: 0, xp_total: 0 }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("ticking a difficulty 4 hour is worth 39 raw XP and no damage", async () => {
  const { tx, queries } = scripted();
  const summary = await tickDraft(userId, { taskId }, tx, defaults, new Date("2026-10-19T04:00:00.000Z"));
  assertEquals(summary.rawXp, 39);
  assertEquals(summary.finalXp, 39);
  assertEquals(queries.some((query) => query.text.includes("completion_mode = 'tick'")), true);
  assertEquals(queries.some((query) => query.text.includes("bosses")), false);
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
});

Deno.test("a ticked task pays once", async () => {
  const { tx, queries } = scripted("done");
  const summary = await tickDraft(userId, { taskId }, tx, defaults);
  assertEquals(summary.rawXp, 39);
  assertEquals(queries.some((query) => query.text.includes("update tasks")), false);
});

Deno.test("a draft cannot be ticked", async () => {
  const { tx } = scripted("draft");
  await assertRejects(() => tickDraft(userId, { taskId }, tx, defaults), AppError, "judged");
});
