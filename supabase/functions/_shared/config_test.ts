import { assertEquals } from "jsr:@std/assert@1";

import { clearConfigCache, defaults, loadConfig, mergeConfig } from "./config.ts";
import { createSql } from "./db.ts";

Deno.test("defaults match the documented chest cost and ai timeout", () => {
  assertEquals(defaults.chest_cost, 500);
  assertEquals(defaults.ai_timeout_ms, 10000);
  assertEquals(defaults.ai_daily_limit, 50);
  assertEquals(defaults.day_boundary_hour, 4);
  assertEquals(defaults.guild_quest_coins, 100);
});

Deno.test("a game_config row overrides only its own key", () => {
  const merged = mergeConfig([{ key: "chest_cost", value: 250 }, { key: "not_a_key", value: 1 }]);
  assertEquals(merged.chest_cost, 250);
  assertEquals(merged.ai_daily_limit, defaults.ai_daily_limit);
  assertEquals("not_a_key" in merged, false);
});

Deno.test("loadConfig falls back to defaults when the reader throws", async () => {
  clearConfigCache();
  const config = await loadConfig(() => Promise.reject(new Error("no table")));
  assertEquals(config.chest_cost, defaults.chest_cost);
});

Deno.test("createSql refuses a blank database url", () => {
  let threw = false;
  try {
    createSql("");
  } catch {
    threw = true;
  }
  assertEquals(threw, true);
});
