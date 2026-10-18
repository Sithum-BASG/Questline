import { assertEquals, assertThrows } from "jsr:@std/assert@1";

import { AiOutputError, clampBossEstimate, clampJudgement, clampReason } from "./clamp.ts";
import { FakeProvider } from "./fake.ts";
import { GroqProvider } from "./groq.ts";
import { requestJudgement } from "./judge.ts";
import { bossEstimateSystem, challengeAddendum, challengeUser, taskJudgeSystem, taskJudgeUser } from "./prompts.ts";

Deno.test("prompts keep the overview wording", () => {
  assertEquals(taskJudgeSystem.includes("\r"), false);
  assertEquals(taskJudgeSystem.startsWith("You are the task judge for Questline"), true);
  assertEquals(taskJudgeSystem.endsWith("Return only JSON matching the schema."), true);
  assertEquals(challengeAddendum.startsWith("The student disagreed with the previous rating"), true);
  assertEquals(bossEstimateSystem.includes("The Forensic Phantom"), true);
  assertEquals(bossEstimateSystem.endsWith("Return only JSON."), true);
});

Deno.test("the user message carries task text only", () => {
  const raw = taskJudgeUser({
    taskTitle: "Revise notes",
    taskNotes: "chapter 3",
    parent: "Big Data",
    dueInDays: 2,
    studentContext: "BSc IT",
    calibrationRatio: null,
  });
  const parsed = JSON.parse(raw);
  assertEquals(Object.keys(parsed).sort(), [
    "calibration_ratio",
    "due_in_days",
    "parent",
    "student_context",
    "task_notes",
    "task_title",
  ]);
  const challenge = JSON.parse(challengeUser({
    taskTitle: "Revise notes",
    previousJudgement: { difficulty: 3 },
    challengeContext: "It is a past paper",
  }));
  assertEquals(challenge.challenge_context, "It is a past paper");
  assertEquals("email" in challenge, false);
});

Deno.test("numbers clamp, reasons stop at 20 words, and bad names fall back", () => {
  const judgement = clampJudgement({
    stat: "intellect",
    difficulty: 9,
    estimated_minutes: 1,
    too_big: false,
    reason: "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty extra",
  });
  assertEquals(judgement.difficulty, 5);
  assertEquals(judgement.estimated_minutes, 5);
  assertEquals(clampReason(judgement.reason).split(" ").length, 20);
  assertEquals(judgement.reason.includes("extra"), false);

  const low = clampJudgement({
    stat: "craft",
    difficulty: 0.4,
    estimated_minutes: 180.5,
    too_big: true,
    reason: "Debugging.",
  });
  assertEquals(low.difficulty, 1);
  assertEquals(low.estimated_minutes, 180);

  const boss = clampBossEstimate({
    boss_name: "Shade",
    total_hours: 1,
    per_person_hours: 90,
    reason: "A short exam.",
  });
  assertEquals(boss.boss_name, "The Deadline Shade");
  assertEquals(boss.total_hours, 2);
  assertEquals(boss.per_person_hours, 40);
  assertEquals(clampBossEstimate({
    boss_name: "The Forensic Phantom",
    total_hours: 8.5,
    per_person_hours: 8.5,
    reason: "Revision.",
  }).boss_name, "The Forensic Phantom");

  assertThrows(() => clampJudgement({ stat: "magic", difficulty: 3, estimated_minutes: 30, too_big: false, reason: "No." }), AiOutputError);
});

Deno.test("a rejected judgement tries the next model", async () => {
  let calls = 0;
  const provider = new GroqProvider({
    apiKey: "test-key",
    models: ["openai/gpt-oss-120b", "openai/gpt-oss-20b"],
    timeoutMs: 50,
    fetch: () => {
      calls += 1;
      const content = calls === 1
        ? { stat: "magic", difficulty: 3, estimated_minutes: 30, too_big: false, reason: "No." }
        : { stat: "intellect", difficulty: 4, estimated_minutes: 90, too_big: false, reason: "Careful writing." };
      return Promise.resolve(new Response(JSON.stringify({
        choices: [{ message: { content: JSON.stringify(content) } }],
      })));
    },
  });
  const judgement = await requestJudgement(provider, { taskTitle: "Write the introduction" });
  assertEquals(judgement.stat, "intellect");
  assertEquals(calls, 2);
});

Deno.test("fake mode returns a clamped canned judgement", async () => {
  const judgement = await requestJudgement(new FakeProvider(), { taskTitle: "Gym session" });
  assertEquals(judgement.stat, "vitality");
  assertEquals(judgement.difficulty, 3);
  assertEquals(judgement.estimated_minutes, 30);
  assertEquals(judgement.reason, "Development judge (fake mode).");
});
