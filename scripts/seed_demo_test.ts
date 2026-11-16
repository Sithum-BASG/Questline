// Sanity checks for the demo seed constants (no database).
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { totalForLevel, levelFromXp } from "../supabase/functions/_shared/game/rewards.ts";

Deno.test("level 42 needs 19780 total XP", () => {
  assertEquals(totalForLevel(42), 19780);
  assertEquals(levelFromXp(19780), 42);
  assertEquals(levelFromXp(19779), 41);
});
