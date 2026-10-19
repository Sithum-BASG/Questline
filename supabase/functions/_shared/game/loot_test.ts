import { assertEquals } from "jsr:@std/assert@1";

import { rollChest, type Cosmetic, type Inventory, type MythicSet } from "./loot.ts";

const cosmetics: Cosmetic[] = [
  { id: "frame_rare", rarity: "rare" },
  { id: "bg_rare", rarity: "rare" },
  { id: "frame_epic", rarity: "epic" },
  { id: "skin_leg", rarity: "legendary" },
];

const mythic: MythicSet[] = [{ ids: ["skin_myth", "bg_myth", "frame_myth"] }];

const empty: Inventory = { chestsSinceLegendary: 0, owned: [], shields: 0, potions: 0, scrolls: 0 };

function sequence(values: number[]): () => number {
  let index = 0;
  return () => values[Math.min(index++, values.length - 1)];
}

Deno.test("pity forces a legendary on the 30th chest and resets", () => {
  const roll = rollChest({ ...empty, chestsSinceLegendary: 29 }, cosmetics, mythic, sequence([0]));
  assertEquals(roll.rarity, "legendary");
  assertEquals(roll.pityCounter, 0);
  assertEquals(roll.drop, { kind: "item", id: "skin_leg" });
});

Deno.test("a common chest is a coin pouch and never gear", () => {
  const roll = rollChest(empty, cosmetics, mythic, sequence([0, 0]));
  assertEquals(roll.rarity, "common");
  assertEquals(roll.drop, { kind: "pouch", coins: 50 });
  assertEquals(roll.pityCounter, 1);
});

Deno.test("rare prefers an unowned cosmetic, then a consumable, then coins", () => {
  const cosmetic = rollChest(empty, cosmetics, mythic, sequence([0.55, 0.1, 0]));
  assertEquals(cosmetic.drop, { kind: "item", id: "frame_rare" });

  const owned: Inventory = { ...empty, owned: ["frame_rare", "bg_rare"] };
  const shield = rollChest(owned, cosmetics, mythic, sequence([0.55, 0.1, 0]));
  assertEquals(shield.drop, { kind: "consumable", id: "streak_shield" });

  const full = rollChest({ ...owned, shields: 2 }, cosmetics, mythic, sequence([0.55, 0.1, 0]));
  assertEquals(full.drop, { kind: "coins", coins: 100 });
});

Deno.test("owned epic and legendary refund, and a mythic set is all or coins", () => {
  const epic = rollChest(
    { ...empty, owned: ["frame_epic"] },
    cosmetics,
    mythic,
    sequence([0.9]),
  );
  assertEquals(epic.drop, { kind: "coins", coins: 200 });

  const legendary = rollChest(
    { ...empty, owned: ["skin_leg"] },
    cosmetics,
    mythic,
    sequence([0.98]),
  );
  assertEquals(legendary.drop, { kind: "coins", coins: 400 });

  const set = rollChest(empty, cosmetics, mythic, sequence([0.999]));
  assertEquals(set.rarity, "mythic");
  assertEquals(set.drop, { kind: "set", ids: ["skin_myth", "bg_myth", "frame_myth"] });
  assertEquals(set.pityCounter, 1);

  const refund = rollChest(
    { ...empty, owned: ["skin_myth", "bg_myth", "frame_myth"] },
    cosmetics,
    mythic,
    sequence([0.999]),
  );
  assertEquals(refund.drop, { kind: "coins", coins: 500 });
});
