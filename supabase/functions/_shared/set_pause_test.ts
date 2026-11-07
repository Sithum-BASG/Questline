import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { setPauseDraft } from "./set_pause.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const now = new Date("2026-10-20T12:00:00.000Z");

function scripted(options: { used?: number; month?: string } = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from player_state")) {
      return Promise.resolve([{
        pause_active: false,
        pause_until: null,
        pause_days_used: options.used ?? 0,
        pause_month: options.month ?? "2026-10",
      }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("setPause arms until a future time", async () => {
  const { tx, queries } = scripted();
  await setPauseDraft(
    userId,
    { active: true, until: "2026-10-22T12:00:00.000Z" },
    tx,
    defaults,
    now,
  );
  assertEquals(queries.some((query) => query.text.includes("pause_active = true")), true);
});

Deno.test("setPause rejects more than 7 days in a month", async () => {
  const { tx } = scripted({ used: 6 });
  await assertRejects(
    () => setPauseDraft(
      userId,
      { active: true, until: "2026-10-23T12:00:00.000Z" },
      tx,
      defaults,
      now,
    ),
    AppError,
    "limited to 7",
  );
});
