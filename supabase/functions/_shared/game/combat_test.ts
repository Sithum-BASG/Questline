import { assertEquals } from "jsr:@std/assert@1";

import {
  applyEscapePenalty,
  bossTier,
  healBoss,
  maxHp,
  metFairShare,
  mvp,
  mvpWinsItem,
  raidLoot,
  raidMaxHp,
  raidResult,
  sessionDamage,
  soloLoot,
} from "./combat.ts";

Deno.test("tiers, hit points and focus-only damage", () => {
  assertEquals(bossTier(3.9).tier, "minion");
  assertEquals(bossTier(4).tier, "brute");
  assertEquals(bossTier(12).tier, "warlord");
  assertEquals(bossTier(25).tier, "titan");
  assertEquals(bossTier(25).coins, 300);
  assertEquals(maxHp(2), 120);
  assertEquals(raidMaxHp(60, 4), 240);
  assertEquals(sessionDamage(50, "activity", true), 0);
  assertEquals(sessionDamage(50, "focus", false), 50);
  assertEquals(sessionDamage(50, "focus", true), 60);
});

Deno.test("an active boss heals, a staggered one does not", () => {
  const healed = healBoss({ status: "active", damage: 40, maxHp: 100, lastWorkDay: "2026-10-09", staggered: false }, "2026-10-10", {
    rest: false,
    paused: false,
  });
  assertEquals(healed, 37);
  const staggered = healBoss({ status: "active", damage: 40, maxHp: 100, lastWorkDay: "2026-10-09", staggered: true }, "2026-10-10", {
    rest: false,
    paused: false,
  });
  assertEquals(staggered, 40);
  const rest = healBoss({ status: "active", damage: 40, maxHp: 100, lastWorkDay: "2026-10-09", staggered: false }, "2026-10-10", {
    rest: true,
    paused: false,
  });
  assertEquals(rest, 40);
});

Deno.test("solo loot, raid result, fair share and the escape penalty", () => {
  assertEquals(soloLoot(0.75, 200, { weeklyCoins: 0, coinsEligible: true }).coins, 200);
  assertEquals(soloLoot(0.74, 200, { weeklyCoins: 0, coinsEligible: true }).coins, 100);
  assertEquals(soloLoot(1, 200, { weeklyCoins: 550, coinsEligible: true }).coins, 50);
  assertEquals(soloLoot(1, 200, { weeklyCoins: 0, coinsEligible: false }).coins, 0);

  assertEquals(raidResult(100, 100, true), "victory");
  assertEquals(raidResult(80, 100, false), "narrow_win");
  assertEquals(raidResult(70, 100, false), "escaped");
  assertEquals(metFairShare(13, 100, 4), true);
  assertEquals(raidLoot(true, "victory", 200), 250);
  assertEquals(raidLoot(true, "narrow_win", 200), 100);
  assertEquals(raidLoot(false, "victory", 200), 0);
  assertEquals(applyEscapePenalty(40, true, false), 0);
  assertEquals(applyEscapePenalty(40, true, true), 40);
});

Deno.test("the MVP is the top damage and wins the item on a 30 percent roll", () => {
  assertEquals(mvp([{ id: "a", damage: 10 }, { id: "b", damage: 40 }]), "b");
  assertEquals(mvpWinsItem(0.29), true);
  assertEquals(mvpWinsItem(0.3), false);
});
