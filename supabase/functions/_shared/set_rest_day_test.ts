import { assertEquals } from "jsr:@std/assert@1";

import { setRestDayDraft } from "./set_rest_day.ts";

const userId = "11111111-1111-1111-1111-111111111111";

Deno.test("setRestDay stores pending_rest_weekday", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from player_state")) return Promise.resolve([{ user_id: userId }]);
    return Promise.resolve([]);
  };
  await setRestDayDraft(userId, { weekday: 0 }, tx);
  assertEquals(queries.some((query) => query.text.includes("pending_rest_weekday") && query.values.includes(0)), true);
});
