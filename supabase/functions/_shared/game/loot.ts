export type Rarity = "common" | "rare" | "epic" | "legendary" | "mythic";

export interface LootRates {
  rarity: Record<Rarity, number>;
  pity: number;
  pouches: [number, number][];
  rareCosmeticChance: number;
  consumables: ["streak_shield" | "focus_potion" | "reschedule_scroll", number][];
  overflowCoins: number;
  refund: { epic: number; legendary: number; mythic: number };
  hold: { streak_shield: number; focus_potion: number };
}

export const defaultLootRates: LootRates = {
  rarity: { common: 0.55, rare: 0.3, epic: 0.12, legendary: 0.025, mythic: 0.005 },
  pity: 30,
  pouches: [[50, 0.6], [100, 0.3], [200, 0.09], [500, 0.01]],
  rareCosmeticChance: 0.5,
  consumables: [["streak_shield", 0.4], ["focus_potion", 0.35], ["reschedule_scroll", 0.25]],
  overflowCoins: 100,
  refund: { epic: 200, legendary: 400, mythic: 500 },
  hold: { streak_shield: 2, focus_potion: 3 },
};

export interface Cosmetic {
  id: string;
  rarity: "rare" | "epic" | "legendary";
}

export interface MythicSet {
  ids: string[];
}

export interface Inventory {
  chestsSinceLegendary: number;
  owned: string[];
  shields: number;
  potions: number;
  scrolls: number;
}

export type ChestDrop =
  | { kind: "pouch"; coins: number }
  | { kind: "item"; id: string }
  | { kind: "set"; ids: string[] }
  | { kind: "consumable"; id: "streak_shield" | "focus_potion" | "reschedule_scroll" }
  | { kind: "coins"; coins: number };

export interface ChestRoll {
  rarity: Rarity;
  drop: ChestDrop;
  pityCounter: number;
}

const rarityOrder: Rarity[] = ["common", "rare", "epic", "legendary", "mythic"];

export function rollRarity(pityCount: number, roll: number, rates: LootRates = defaultLootRates): Rarity {
  if (pityCount + 1 >= rates.pity) return "legendary";
  let cursor = 0;
  for (const rarity of rarityOrder) {
    cursor += rates.rarity[rarity];
    if (roll < cursor) return rarity;
  }
  return "mythic";
}

function pickWeighted<T>(entries: [T, number][], roll: number): T {
  let cursor = 0;
  for (const [value, weight] of entries) {
    cursor += weight;
    if (roll < cursor) return value;
  }
  return entries[entries.length - 1][0];
}

function pickUnowned(items: Cosmetic[], owned: Set<string>, rng: () => number): Cosmetic | undefined {
  const pool = items.filter((item) => !owned.has(item.id));
  if (pool.length === 0) return undefined;
  const index = Math.min(pool.length - 1, Math.floor(rng() * pool.length));
  return pool[index];
}

/// One chest. `rng` returns numbers in [0, 1) and is called once per decision, so tests can force a result.
export function rollChest(
  inventory: Inventory,
  cosmetics: Cosmetic[],
  mythicSets: MythicSet[],
  rng: () => number,
  rates: LootRates = defaultLootRates,
  force?: Rarity,
): ChestRoll {
  const pity = inventory.chestsSinceLegendary + 1;
  const rarity = force ?? rollRarity(inventory.chestsSinceLegendary, rng(), rates);
  const pityCounter = rarity === "legendary" ? 0 : pity;
  const owned = new Set(inventory.owned);

  if (rarity === "common") {
    return { rarity, pityCounter, drop: { kind: "pouch", coins: pickWeighted(rates.pouches, rng()) } };
  }

  if (rarity === "rare") {
    const wantCosmetic = rng() < rates.rareCosmeticChance;
    const cosmetic = wantCosmetic ? pickUnowned(cosmetics.filter((item) => item.rarity === "rare"), owned, rng) : undefined;
    if (cosmetic) return { rarity, pityCounter, drop: { kind: "item", id: cosmetic.id } };
    const consumable = pickWeighted(rates.consumables, rng());
    const held = consumable === "streak_shield"
      ? inventory.shields
      : consumable === "focus_potion"
      ? inventory.potions
      : inventory.scrolls;
    const limit = consumable === "streak_shield"
      ? rates.hold.streak_shield
      : consumable === "focus_potion"
      ? rates.hold.focus_potion
      : Number.POSITIVE_INFINITY;
    if (held >= limit) return { rarity, pityCounter, drop: { kind: "coins", coins: rates.overflowCoins } };
    return { rarity, pityCounter, drop: { kind: "consumable", id: consumable } };
  }

  if (rarity === "mythic") {
    const set = mythicSets.find((candidate) => candidate.ids.some((id) => !owned.has(id)));
    if (set) return { rarity, pityCounter, drop: { kind: "set", ids: set.ids } };
    return { rarity, pityCounter, drop: { kind: "coins", coins: rates.refund.mythic } };
  }

  const item = pickUnowned(cosmetics.filter((entry) => entry.rarity === rarity), owned, rng);
  if (item) return { rarity, pityCounter, drop: { kind: "item", id: item.id } };
  const coins = rarity === "epic" ? rates.refund.epic : rates.refund.legendary;
  return { rarity, pityCounter, drop: { kind: "coins", coins } };
}
