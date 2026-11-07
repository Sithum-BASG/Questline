import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { AppError } from "./errors.ts";
import { submitBossDraft } from "./submit_boss.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const bossId = "44444444-4444-4444-4444-444444444444";
const now = new Date("2026-10-10T12:00:00.000Z");

function scripted(options: {
  status?: string;
  damage?: number;
  maxHp?: number;
  hours?: number;
  coinsEligible?: boolean;
  weeklyCoins?: number;
  loot?: unknown;
  deadline?: string;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from bosses")) {
      return Promise.resolve([{
        id: bossId,
        name: "The Practice Shade",
        title: "Report",
        tier: "minion",
        hours: options.hours ?? 2,
        max_hp: options.maxHp ?? 120,
        damage: options.damage ?? 100,
        deadline: options.deadline ?? "2026-10-13T12:00:00.000Z",
        status: options.status ?? "active",
        coins_eligible: options.coinsEligible !== false,
        loot: options.loot ?? null,
      }]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{
        coins: 200,
        boss_coins_this_week: options.weeklyCoins ?? 0,
        counters: { bosses_defeated: 0 },
      }]);
    }
    if (text.includes("from profiles")) {
      return Promise.resolve([{ show_boss_names: true }]);
    }
    if (text.includes("from achievements")) {
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("submitBoss pays full loot at 75 percent damage", async () => {
  const { tx, queries } = scripted({ damage: 90, maxHp: 120 });
  const result = await submitBossDraft(userId, { bossId }, tx, defaults, now);
  assertEquals(result.result, "defeated");
  assertEquals(result.loot, "full");
  assertEquals(result.coins, 100);
  assertEquals(queries.some((query) => query.text.includes("status = 'defeated'")), true);
  assertEquals(queries.some((query) => query.text.includes("boss_defeated")), true);
});

Deno.test("submitBoss pays half loot under 75 percent", async () => {
  const { tx } = scripted({ damage: 50, maxHp: 120 });
  const result = await submitBossDraft(userId, { bossId }, tx, defaults, now);
  assertEquals(result.loot, "half");
  assertEquals(result.coins, 50);
});

Deno.test("submitBoss is idempotent after defeat", async () => {
  const { tx, queries } = scripted({
    status: "defeated",
    loot: { loot: "full", coins: 100 },
  });
  const result = await submitBossDraft(userId, { bossId }, tx, defaults, now);
  assertEquals(result.coins, 100);
  assertEquals(queries.some((query) => query.text.includes("update player_state")), false);
});

Deno.test("submitBoss rejects a past deadline", async () => {
  const { tx } = scripted({ deadline: "2026-10-09T12:00:00.000Z" });
  await assertRejects(() => submitBossDraft(userId, { bossId }, tx, defaults, now), AppError);
});
