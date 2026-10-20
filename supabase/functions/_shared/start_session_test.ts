import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { startDraft } from "./start_session.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const taskId = "22222222-2222-2222-2222-222222222222";

function task(over: Record<string, unknown> = {}) {
  return {
    id: taskId,
    status: "open",
    stat: "intellect",
    difficulty: 4,
    est_minutes: 60,
    ...over,
  };
}

function scripted(options: { task?: Record<string, unknown> | null; active?: boolean; potions?: number; focusToday?: number } = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from tasks")) return Promise.resolve(options.task === null ? [] : [options.task ?? task()]);
    if (text.includes("from sessions") && text.includes("status = 'active'")) {
      return Promise.resolve(options.active ? [{ id: "active" }] : []);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ potions: options.potions ?? 0, focus_minutes_today: options.focusToday ?? 0 }]);
    }
    if (text.includes("insert into sessions")) {
      return Promise.resolve([{ id: "33333333-3333-3333-3333-333333333333", started_at: "2026-10-19T02:00:00.000Z" }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("a focus session starts and the cap is 1.5 times the estimate", async () => {
  const { tx, queries } = scripted();
  const result = await startDraft(userId, { taskId, mode: "focus" }, tx, defaults);
  assertEquals(result, {
    sessionId: "33333333-3333-3333-3333-333333333333",
    startedAt: "2026-10-19T02:00:00.000Z",
    capMinutes: 90,
  });
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
});

Deno.test("activity is only for vitality and charisma", async () => {
  const intellect = scripted();
  await assertRejects(
    () => startDraft(userId, { taskId, mode: "activity" }, intellect.tx, defaults),
    AppError,
    "Activity mode",
  );
  assertEquals(intellect.queries.some((query) => query.text.includes("insert into sessions")), false);

  const vitality = scripted({ task: task({ stat: "vitality", est_minutes: 40 }) });
  const result = await startDraft(userId, { taskId, mode: "activity" }, vitality.tx, defaults);
  assertEquals(result.capMinutes, 40);
});

Deno.test("a second active session is rejected", async () => {
  const { tx, queries } = scripted({ active: true });
  await assertRejects(() => startDraft(userId, { taskId, mode: "focus" }, tx, defaults), AppError, "current session");
  assertEquals(queries.some((query) => query.text.includes("insert into sessions")), false);
});

Deno.test("a potion arms only when one is owned and the estimate is long enough", async () => {
  const armed = scripted({ potions: 1 });
  await startDraft(userId, { taskId, mode: "focus", usePotion: true }, armed.tx, defaults);
  assertEquals(armed.queries.some((query) => query.text.includes("active_potion = true")), true);
  assertEquals(armed.queries.some((query) => query.text.includes("potions = potions - 1")), false);

  const none = scripted({ potions: 0 });
  await assertRejects(
    () => startDraft(userId, { taskId, mode: "focus", usePotion: true }, none.tx, defaults),
    AppError,
    "potion",
  );

  const short = scripted({ potions: 1, task: task({ est_minutes: 20 }) });
  await assertRejects(
    () => startDraft(userId, { taskId, mode: "focus", usePotion: true }, short.tx, defaults),
    AppError,
    "25",
  );
});

Deno.test("the daily focus limit shrinks the cap", async () => {
  const { tx } = scripted({ focusToday: 470 });
  const result = await startDraft(userId, { taskId, mode: "focus" }, tx, defaults);
  assertEquals(result.capMinutes, 10);
});
