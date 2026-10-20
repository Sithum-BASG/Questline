import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { endDraft, type SessionSummary } from "./end_session.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const sessionId = "33333333-3333-3333-3333-333333333333";
const taskId = "22222222-2222-2222-2222-222222222222";
const now = new Date("2026-10-19T04:00:00.000Z");

/// One session, two endSession calls. The second must return the stored summary.
Deno.test("a 60 minute difficulty 4 session pays 86 XP once", async () => {
  let processed = false;
  let stored: SessionSummary | null = null;
  let xpWrites = 0;
  const started = new Date(now.getTime() - 60 * 60 * 1000).toISOString();

  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    if (text.includes("from sessions")) {
      return Promise.resolve([{
        id: sessionId,
        task_id: taskId,
        mode: "focus",
        started_at: started,
        status: processed ? "completed" : "active",
        potion: false,
        processed,
        summary: stored,
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
        xp_total: 0,
        comeback_armed: false,
        potions: 0,
        onboarding_step: "done",
      }]);
    }
    if (text.includes("from inventory") || text.includes("from user_settings") || text.includes("from demo_allowlist")) {
      return Promise.resolve([]);
    }
    if (text.includes("from level_rewards")) {
      return Promise.resolve([{ level: 2, rewards: [{ type: "item", id: "frame_margin_notes" }] }]);
    }
    if (text.includes("insert into daily_stats") || text.includes("insert into weekly_scores")) {
      xpWrites += 1;
    }
    if (text.includes("update sessions") && text.includes("processed = true")) {
      processed = true;
      const payload = values.find((value) => typeof value === "string" && value.includes("rawXp"));
      if (typeof payload === "string") stored = JSON.parse(payload) as SessionSummary;
    }
    return Promise.resolve([]);
  };

  const first = await endDraft(userId, { sessionId, interruptions: [] }, tx, defaults, now);
  assertEquals(first.rawXp, 86);
  assertEquals(first.finalXp, 86);
  assertEquals(first.verifiedMinutes, 60);
  assertEquals(xpWrites, 2);

  const second = await endDraft(userId, { sessionId, interruptions: [] }, tx, defaults, now);
  assertEquals(second, first);
  assertEquals(xpWrites, 2);
});
