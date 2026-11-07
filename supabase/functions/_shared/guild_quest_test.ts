import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import {
  applyGuildQuestProgress,
  guildQuestEligible,
  guildQuestPayoutCoins,
} from "./guild_quest.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const guildId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

Deno.test("guildQuestEligible needs goal met and min contribution", () => {
  assertEquals(guildQuestEligible(200, 5000, 5000, 200), true);
  assertEquals(guildQuestEligible(199, 5000, 5000, 200), false);
  assertEquals(guildQuestEligible(200, 4999, 5000, 200), false);
});

Deno.test("guildQuestPayoutCoins reads config", () => {
  assertEquals(guildQuestPayoutCoins({ guild_quest_coins: 100 }), 100);
});

Deno.test("applyGuildQuestProgress resets on a new week and adds raw XP", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });
    if (text.includes("from guild_members") && text.includes("user_id")) {
      return Promise.resolve([{ guild_id: guildId, quest_contribution: 50 }]);
    }
    if (text.includes("from guilds")) {
      return Promise.resolve([{
        id: guildId,
        quest_week_id: "2026-W41",
        quest_progress: 400,
        quest_goal: 5000,
      }]);
    }
    return Promise.resolve([]);
  };

  await applyGuildQuestProgress(userId, 86, "2026-W42", tx, defaults);
  assertEquals(queries.some((q) => q.text.includes("quest_contribution = 0")), true);
  assertEquals(
    queries.some((q) => q.text.includes("quest_progress =") && q.values.includes(86)),
    true,
  );
  assertEquals(
    queries.some((q) => q.text.includes("quest_contribution =") && q.values.includes(86)),
    true,
  );
});
