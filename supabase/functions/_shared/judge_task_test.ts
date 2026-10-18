import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { AiExhaustedError, type AiProvider, type GenerateJsonRequest } from "./ai/index.ts";
import { defaults } from "./config.ts";
import type { Sql } from "./db.ts";
import { AppError } from "./errors.ts";
import { judgeDraft, judgeTask } from "./judge_task.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const taskId = "22222222-2222-2222-2222-222222222222";

function draft(over: Record<string, unknown> = {}) {
  return {
    id: taskId,
    title: "Write introduction for Computer Forensics report",
    notes: "800 words",
    due_at: "2026-10-13T00:00:00.000Z",
    boss_id: null,
    status: "draft",
    stat: null,
    difficulty: null,
    est_minutes: null,
    too_big: null,
    reason: null,
    provisional: false,
    challenged: false,
    judged_at: null,
    ...over,
  };
}

function scripted(rows: Record<string, unknown>, callsToday = 0) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from tasks")) return Promise.resolve([rows]);
    if (text.includes("ai_calls_today") && text.includes("select")) {
      return Promise.resolve([{ ai_calls_today: callsToday }]);
    }
    if (text.includes("study_context")) return Promise.resolve([{ study_context: "BSc IT, 3rd year" }]);
    if (text.includes("from bosses")) return Promise.resolve([{ title: "Computer Forensics Assignment 2" }]);
    return Promise.resolve([]);
  };
  return { tx, queries };
}

function provider(result: unknown): AiProvider & { calls: GenerateJsonRequest[] } {
  const calls: GenerateJsonRequest[] = [];
  return {
    calls,
    generateJson(req) {
      calls.push(req);
      return Promise.resolve(result);
    },
  };
}

const good = {
  stat: "intellect",
  difficulty: 4,
  estimated_minutes: 90,
  too_big: false,
  reason: "Structured academic writing that needs research and careful wording.",
};

Deno.test("a draft is judged and the model never sees the user id", async () => {
  const { tx, queries } = scripted(draft());
  const ai = provider(good);
  const result = await judgeDraft(userId, taskId, tx, ai, defaults, new Date("2026-10-10T12:00:00.000Z"));
  assertEquals(result.stat, "intellect");
  assertEquals(result.difficulty, 4);
  assertEquals(result.estimatedMinutes, 90);
  assertEquals(result.provisional, false);
  assertEquals(result.xpPreview, 129);
  assertEquals(ai.calls.length, 1);
  const sent = JSON.parse(ai.calls[0].user);
  assertEquals(sent.task_title, draft().title);
  assertEquals(sent.student_context, "BSc IT, 3rd year");
  assertEquals(JSON.stringify(sent).includes(userId), false);
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
  assertEquals(queries.some((query) => query.text.includes("update tasks")), true);
  assertEquals(queries.some((query) => query.text.includes("ai_calls_today = ai_calls_today + 1")), true);
});

Deno.test("a failed model chain saves a provisional judgement", async () => {
  const { tx, queries } = scripted(draft({ title: "Gym session", notes: null, due_at: null }));
  const ai: AiProvider = {
    generateJson() {
      return Promise.reject(new AiExhaustedError());
    },
  };
  const result = await judgeDraft(userId, taskId, tx, ai, defaults);
  assertEquals(result.provisional, true);
  assertEquals(result.difficulty, 3);
  assertEquals(result.estimatedMinutes, 30);
  assertEquals(result.stat, "vitality");
  assertEquals(result.xpPreview, 30);
  assertEquals(queries.some((query) => query.text.includes("ai_calls_today = ai_calls_today + 1")), true);
});

Deno.test("the daily limit skips the model and does not count another call", async () => {
  let called = false;
  const { tx } = scripted(draft(), 50);
  const ai: AiProvider = {
    generateJson() {
      called = true;
      return Promise.resolve(good);
    },
  };
  const result = await judgeDraft(userId, taskId, tx, ai, defaults);
  assertEquals(called, false);
  assertEquals(result.provisional, true);
  assertEquals(result.reason, "AI judge resting until tomorrow; saved as provisional");
});

Deno.test("a finished judgement is returned without calling the model again", async () => {
  let called = false;
  const { tx, queries } = scripted(draft({
    stat: "intellect",
    difficulty: 4,
    est_minutes: 90,
    too_big: false,
    reason: "Already judged.",
    judged_at: "2026-10-10T00:00:00.000Z",
  }));
  const ai: AiProvider = {
    generateJson() {
      called = true;
      return Promise.resolve(good);
    },
  };
  const result = await judgeDraft(userId, taskId, tx, ai, defaults);
  assertEquals(called, false);
  assertEquals(result.estimatedMinutes, 90);
  assertEquals(queries.some((query) => query.text.includes("update tasks")), false);
});

Deno.test("someone else's task and an open task are rejected", async () => {
  const missing = scripted(draft());
  missing.tx = () => Promise.resolve([]);
  await assertRejects(
    () => judgeDraft(userId, taskId, missing.tx, provider(good), defaults),
    AppError,
    "Task not found",
  );
  const open = scripted(draft({ status: "open" }));
  await assertRejects(
    () => judgeDraft(userId, taskId, open.tx, provider(good), defaults),
    AppError,
    "Only a draft task can be judged",
  );
});

Deno.test("a bad task id never starts a transaction", async () => {
  let began = false;
  const sql = { begin() {
    began = true;
  } } as unknown as Sql;
  await assertRejects(() => judgeTask(userId, { taskId: "nope" }, sql));
  assertEquals(began, false);
});
