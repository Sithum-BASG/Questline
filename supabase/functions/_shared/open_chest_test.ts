import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { openChestDraft } from "./open_chest.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const requestId = "req-1";

function scripted(options: {
  coins?: number;
  freeChests?: number;
  pity?: number;
  processed?: unknown;
  demoMode?: boolean;
  allowlisted?: boolean;
  rng?: () => number;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from processed_requests")) {
      return Promise.resolve(options.processed ? [{ result: options.processed }] : []);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{
        coins: options.coins ?? 500,
        free_chests: options.freeChests ?? 0,
        chests_since_legendary: options.pity ?? 0,
        shields: 0,
        potions: 0,
        scrolls: 0,
      }]);
    }
    if (text.includes("from user_settings") || text.includes("demo_allowlist")) {
      return Promise.resolve([{
        demo_mode: options.demoMode === true,
        allowlisted: options.allowlisted === true,
      }]);
    }
    if (text.includes("from inventory")) return Promise.resolve([]);
    if (text.includes("from catalog_items")) {
      return Promise.resolve([
        { id: "frame_alchemist_glass", rarity: "rare", type: "frame", set_id: null },
        { id: "bg_cafe", rarity: "rare", type: "background", set_id: null },
        { id: "frame_amethyst_bloom", rarity: "epic", type: "frame", set_id: null },
        { id: "skin_sunscholar", rarity: "legendary", type: "skin", set_id: null },
        { id: "skin_chronomancer", rarity: "mythic", type: "skin", set_id: "chrono" },
        { id: "bg_chronosphere", rarity: "mythic", type: "background", set_id: "chrono" },
        { id: "frame_chronomancer", rarity: "mythic", type: "frame", set_id: "chrono" },
      ]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("opening a chest spends 500 coins and returns a pouch", async () => {
  const { tx, queries } = scripted();
  const result = await openChestDraft(userId, { requestId, useFreeChest: false }, tx, defaults, () => 0);
  assertEquals(result.rarity, "common");
  assertEquals(result.pityCounter, 1);
  assertEquals((result.drop as { kind: string; coins: number }).kind, "pouch");
  assertEquals(queries.some((query) => query.text.includes("coins =")), true);
  assertEquals(queries.some((query) => query.text.includes("insert into processed_requests")), true);
});

Deno.test("the same request id pays once", async () => {
  const stored = {
    rarity: "common" as const,
    pityCounter: 1,
    drop: { kind: "pouch" as const, coins: 50 },
  };
  const { tx, queries } = scripted({ processed: stored });
  const result = await openChestDraft(userId, { requestId }, tx, defaults, () => 0);
  assertEquals(result.rarity, stored.rarity);
  assertEquals(result.pityCounter, stored.pityCounter);
  assertEquals(result.drop, stored.drop);
  assertEquals(queries.some((query) => query.text.includes("insert into processed_requests")), false);
  assertEquals(queries.some((query) => query.text.includes("update player_state")), false);
});

Deno.test("a free chest is spent instead of coins", async () => {
  const { tx, queries } = scripted({ coins: 0, freeChests: 1 });
  await openChestDraft(userId, { requestId, useFreeChest: true }, tx, defaults, () => 0);
  assertEquals(queries.some((query) => query.text.includes("free_chests =")), true);
});

Deno.test("not enough coins is rejected", async () => {
  const { tx } = scripted({ coins: 100 });
  await assertRejects(
    () => openChestDraft(userId, { requestId }, tx, defaults, () => 0),
    AppError,
    "coins",
  );
});

Deno.test("demo mode on an allow-listed account forces Mythic", async () => {
  // rng would roll common (0); force overrides to mythic Chronomancer set.
  const { tx } = scripted({ demoMode: true, allowlisted: true });
  const result = await openChestDraft(userId, { requestId: "demo-chest" }, tx, defaults, () => 0);
  assertEquals(result.rarity, "mythic");
  assertEquals((result.drop as { kind: string }).kind, "set");
  assertEquals((result.drop as { ids: string[] }).ids.includes("skin_chronomancer"), true);
});

Deno.test("demo_mode alone without allowlist does not force Mythic", async () => {
  const { tx } = scripted({ demoMode: true, allowlisted: false });
  const result = await openChestDraft(userId, { requestId: "no-force" }, tx, defaults, () => 0);
  assertEquals(result.rarity, "common");
});
