import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { demoStatusDraft, setDemoModeDraft } from "./demo_mode.ts";
import { AppError } from "./errors.ts";

const userId = "11111111-1111-1111-1111-111111111111";

function scripted(options: { allowed: boolean; demo?: boolean }) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from demo_allowlist")) return Promise.resolve(options.allowed ? [{ user_id: userId }] : []);
    if (text.includes("from user_settings")) return Promise.resolve([{ demo_mode: options.demo === true }]);
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("demoStatus reports the allow-list and the switch", async () => {
  assertEquals(await demoStatusDraft(userId, scripted({ allowed: true, demo: true }).tx), { allowed: true, enabled: true });
  assertEquals(await demoStatusDraft(userId, scripted({ allowed: false, demo: true }).tx), { allowed: false, enabled: false });
});

Deno.test("setDemoMode updates only the caller's settings", async () => {
  const { tx, queries } = scripted({ allowed: true });
  const result = await setDemoModeDraft(userId, { enabled: true }, tx);
  assertEquals(result, { allowed: true, enabled: true });
  const update = queries.find((query) => query.text.includes("update user_settings"));
  assertEquals(update?.values, [true, userId]);
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
});

Deno.test("setDemoMode is refused off the allow-list", async () => {
  const { tx, queries } = scripted({ allowed: false });
  await assertRejects(() => setDemoModeDraft(userId, { enabled: true }, tx), AppError);
  assertEquals(queries.some((query) => query.text.includes("update user_settings")), false);
});
