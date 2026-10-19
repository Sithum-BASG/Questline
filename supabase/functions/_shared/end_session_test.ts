import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { endDraft } from "./end_session.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const sessionId = "33333333-3333-3333-3333-333333333333";
const taskId = "22222222-2222-2222-2222-222222222222";
const now = new Date("2026-10-19T04:00:00.000Z");

function scripted(options: { processed?: boolean; summary?: unknown; startedAt?: string } = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const started = options.startedAt ?? new Date(now.getTime() - 60 * 60 * 1000).toISOString();
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from sessions")) {
      return Promise.resolve([{
        id: sessionId,
        task_id: taskId,
        mode: "focus",
        started_at: started,
        status: "active",
        potion: false,
        processed: options.processed === true,
        summary: options.summary ?? null,
      }]);
    }
    if (text.includes("from tasks")) {
      return Promise.resolve([{
        difficulty: 4,
        est_minutes: 60,
        stat: "intellect",
        due_at: "2026-10-20T12:00:00.000Z",
        rescheduled: false,
        scroll_used: false,
        status: "open",
      }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{
        timezone: "Asia/Colombo",
        focus_minutes_today: 0,
        weekly_raw_xp: 0,
        week_id: "2026-W42",
        comeback_armed: false,
        potions: 0,
        onboarding_step: "done",
      }]);
    }
    if (text.includes("from inventory")) return Promise.resolve([]);
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("a 60 minute difficulty 4 on-time session is worth 86 raw XP", async () => {
  const { tx, queries } = scripted();
  const summary = await endDraft(userId, { sessionId, interruptions: [] }, tx, defaults, now);
  assertEquals(summary.rawXp, 86);
  assertEquals(summary.finalXp, 86);
  assertEquals(summary.verifiedMinutes, 60);
  assertEquals(queries.some((query) => query.text.includes("insert into daily_stats")), true);
  assertEquals(queries.some((query) => query.text.includes("insert into weekly_scores")), true);
  assertEquals(queries.some((query) => query.text.includes("status = 'done'")), true);
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
});

Deno.test("a processed session returns the stored summary", async () => {
  const stored = { rawXp: 86, finalXp: 86, verifiedMinutes: 60, countedMinutes: 60, broken: false };
  const { tx, queries } = scripted({ processed: true, summary: stored });
  const summary = await endDraft(userId, { sessionId, interruptions: [] }, tx, defaults, now);
  assertEquals(summary, stored);
  assertEquals(queries.some((query) => query.text.includes("insert into daily_stats")), false);
});

Deno.test("under 5 verified minutes earns nothing and leaves the task open", async () => {
  const { tx, queries } = scripted({
    startedAt: new Date(now.getTime() - 2 * 60 * 1000).toISOString(),
  });
  const summary = await endDraft(userId, { sessionId, interruptions: [] }, tx, defaults, now);
  assertEquals(summary.rawXp, 0);
  assertEquals(summary.verifiedMinutes, 2);
  assertEquals(queries.some((query) => query.text.includes("status = 'done'")), false);
});
