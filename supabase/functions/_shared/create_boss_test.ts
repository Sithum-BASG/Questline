import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { FakeProvider } from "./ai/index.ts";
import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { coinsEligibleAt, createBossDraft, dueInDays } from "./create_boss.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const now = new Date("2026-10-10T10:00:00.000Z");
const deadlineIn3Days = "2026-10-13T10:00:00.000Z";
const deadlineIn1Day = "2026-10-11T10:00:00.000Z";

function scripted(options: {
  soloCount?: number;
  raidCount?: number;
  aiCalls?: number;
  studyContext?: string | null;
  insertId?: string;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from bosses") && text.includes("count")) {
      return Promise.resolve([{ n: options.soloCount ?? 0 }]);
    }
    if (text.includes("from raid_members")) {
      return Promise.resolve([{ n: options.raidCount ?? 0 }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ ai_calls_today: options.aiCalls ?? 0 }]);
    }
    if (text.includes("from user_settings")) {
      return Promise.resolve([{ study_context: options.studyContext ?? null }]);
    }
    if (text.includes("insert into bosses")) {
      return Promise.resolve([{
        id: options.insertId ?? "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
        name: values[1],
        title: values[2],
        type: values[3],
        tier: values[4],
        hours: values[5],
        max_hp: values[6],
        damage: 0,
        deadline: values[8],
        status: "active",
        coins_eligible: values[9],
      }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

const baseBody = {
  title: "Computer Forensics Assignment 2",
  description: "Write the report",
  type: "assignment" as const,
  deadline: deadlineIn3Days,
};

Deno.test("coinsEligibleAt requires 48 hours before the deadline", () => {
  assertEquals(coinsEligibleAt(new Date(deadlineIn3Days), now, 48), true);
  assertEquals(coinsEligibleAt(new Date(deadlineIn1Day), now, 48), false);
  assertEquals(dueInDays(new Date(deadlineIn3Days), now), 3);
});

Deno.test("dryRun returns an AI preview without inserting", async () => {
  const { tx, queries } = scripted();
  const result = await createBossDraft(
    userId,
    { ...baseBody, dryRun: true },
    tx,
    new FakeProvider(),
    defaults,
    now,
  );
  assertEquals("preview" in result, true);
  if (!("preview" in result)) return;
  assertEquals(result.preview.name, "The Practice Shade");
  assertEquals(result.preview.hours, 6);
  assertEquals(result.preview.tier, "brute");
  assertEquals(result.preview.maxHp, 360);
  assertEquals(result.preview.coinsEligible, true);
  assertEquals(result.preview.defeatCoins, 150);
  assertEquals(queries.some((query) => query.text.includes("insert into bosses")), false);
  assertEquals(queries.some((query) => query.text.includes("ai_calls_today = ai_calls_today + 1")), true);
});

Deno.test("confirm creates a boss with the chosen hours and 48 h coin flag", async () => {
  const { tx, queries } = scripted();
  const result = await createBossDraft(
    userId,
    {
      ...baseBody,
      dryRun: false,
      hours: 2,
      name: "The Practice Shade",
      deadline: deadlineIn1Day,
    },
    tx,
    new FakeProvider(),
    defaults,
    now,
  );
  assertEquals("boss" in result, true);
  if (!("boss" in result)) return;
  assertEquals(result.boss.hours, 2);
  assertEquals(result.boss.tier, "minion");
  assertEquals(result.boss.maxHp, 120);
  assertEquals(result.boss.coinsEligible, false);
  assertEquals(result.boss.name, "The Practice Shade");
  assertEquals(queries.some((query) => query.text.includes("insert into bosses")), true);
});

Deno.test("confirm rejects a 16th active fight", async () => {
  const { tx } = scripted({ soloCount: 10, raidCount: 5 });
  await assertRejects(
    () =>
      createBossDraft(
        userId,
        { ...baseBody, dryRun: false, hours: 4, name: "The Practice Shade" },
        tx,
        new FakeProvider(),
        defaults,
        now,
      ),
    AppError,
  );
});

Deno.test("dryRun fails when the daily AI limit is hit", async () => {
  const { tx } = scripted({ aiCalls: 50 });
  await assertRejects(
    () =>
      createBossDraft(
        userId,
        { ...baseBody, dryRun: true },
        tx,
        new FakeProvider(),
        defaults,
        now,
      ),
    AppError,
  );
});
