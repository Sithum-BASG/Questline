import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { attuneGearDraft } from "./attune_gear.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const wand = "gear_weapon_apprentice_wand";

function scripted(options: {
  owned?: boolean;
  attuned?: string | null;
  equipped?: boolean;
  coins?: number;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from inventory") && text.includes("join catalog_items")) {
      if (!options.owned) return Promise.resolve([]);
      return Promise.resolve([{
        catalog_id: wand,
        attuned_stat: options.attuned === undefined ? null : options.attuned,
        equipped_slot: options.equipped ? "weapon" : null,
        type: "gear",
      }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ coins: options.coins ?? 500 }]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("first attunement is free", async () => {
  const { tx, queries } = scripted({ owned: true, attuned: null });
  await attuneGearDraft(userId, { catalogId: wand, stat: "intellect" }, tx, defaults);
  assertEquals(queries.some((query) => query.text.includes("update player_state")), false);
  assertEquals(queries.some((query) => query.text.includes("attuned_stat =")), true);
});

Deno.test("re-attuning spends 200 coins and refreshes if equipped", async () => {
  const { tx, queries } = scripted({ owned: true, attuned: "vitality", equipped: true, coins: 200 });
  await attuneGearDraft(userId, { catalogId: wand, stat: "intellect" }, tx, defaults);
  assertEquals(queries.some((query) => query.text.includes("coins =") && query.values.includes(0)), true);
  assertEquals(queries.some((query) => query.text.includes("update friend_summaries")), true);
});

Deno.test("re-attune without coins is rejected", async () => {
  const { tx } = scripted({ owned: true, attuned: "vitality", coins: 50 });
  await assertRejects(
    () => attuneGearDraft(userId, { catalogId: wand, stat: "intellect" }, tx, defaults),
    AppError,
    "Not enough coins",
  );
});
