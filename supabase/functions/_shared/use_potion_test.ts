import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { AppError } from "./errors.ts";
import { usePotionDraft } from "./use_potion.ts";

const userId = "11111111-1111-1111-1111-111111111111";

function scripted(options: { potions?: number; active?: boolean } = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from player_state")) {
      return Promise.resolve([{
        potions: options.potions ?? 1,
        active_potion: options.active ?? false,
      }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("usePotion arms active_potion when the player has one", async () => {
  const { tx, queries } = scripted({ potions: 2 });
  const result = await usePotionDraft(userId, {}, tx);
  assertEquals(result, { ok: true });
  assertEquals(queries.some((query) => query.text.includes("active_potion = true")), true);
});

Deno.test("usePotion rejects an empty potion count", async () => {
  const { tx } = scripted({ potions: 0 });
  await assertRejects(() => usePotionDraft(userId, {}, tx), AppError, "don't have a focus potion");
});
