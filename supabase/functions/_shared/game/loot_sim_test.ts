import { assert } from "jsr:@std/assert@1";

import { defaultLootRates, rollRarity, type Rarity } from "./loot.ts";

function mulberry32(seed: number): () => number {
  let state = seed;
  return () => {
    state = (state + 0x6d2b79f5) | 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

Deno.test("100,000 chest rarities stay within half a percent of the published rates", () => {
  const rolls = 100_000;
  const rng = mulberry32(0x517cc1);
  const counts: Record<Rarity, number> = { common: 0, rare: 0, epic: 0, legendary: 0, mythic: 0 };
  for (let i = 0; i < rolls; i++) counts[rollRarity(0, rng())] += 1;
  for (const rarity of Object.keys(counts) as Rarity[]) {
    const actual = counts[rarity] / rolls;
    const expected = defaultLootRates.rarity[rarity];
    assert(Math.abs(actual - expected) <= 0.005, `${rarity} ${(actual * 100).toFixed(2)}% vs ${expected * 100}%`);
  }
});
