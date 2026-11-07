import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { AppError } from "./errors.ts";
import { equipGearDraft } from "./equip_gear.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const wand = "gear_weapon_apprentice_wand";

function scripted(options: { owned?: boolean; type?: string; slot?: string } = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from inventory") && text.includes("join catalog_items")) {
      if (!options.owned) return Promise.resolve([]);
      return Promise.resolve([{
        catalog_id: wand,
        equipped_slot: null,
        type: options.type ?? "gear",
        slot: options.slot ?? "weapon",
      }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("equipGear puts the item in the slot and refreshes summaries", async () => {
  const { tx, queries } = scripted({ owned: true });
  const result = await equipGearDraft(userId, { catalogId: wand, slot: "weapon" }, tx);
  assertEquals(result, { ok: true });
  assertEquals(queries.some((query) => query.text.includes("equipped_slot = null")), true);
  assertEquals(queries.some((query) => query.text.includes("equipped_slot =") && query.values.includes("weapon")), true);
  assertEquals(queries.some((query) => query.text.includes("update friend_summaries")), true);
});

Deno.test("equipGear rejects items the player does not own", async () => {
  const { tx } = scripted({ owned: false });
  await assertRejects(
    () => equipGearDraft(userId, { catalogId: wand, slot: "weapon" }, tx),
    AppError,
    "don't own",
  );
});

Deno.test("equipGear rejects a mismatched slot", async () => {
  const { tx } = scripted({ owned: true, slot: "weapon" });
  await assertRejects(
    () => equipGearDraft(userId, { catalogId: wand, slot: "armour" }, tx),
    AppError,
    "doesn't fit",
  );
});
