import { assertEquals } from "jsr:@std/assert@1";

import { defaults } from "./config.ts";
import { resolveRaidsDraft } from "./raid_resolve.ts";

const raidId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";
const userA = "11111111-1111-1111-1111-111111111111";
const userB = "22222222-2222-2222-2222-222222222222";
const now = new Date("2026-10-10T12:00:00.000Z");

Deno.test("resolveRaidsDraft marks victory, fair share, MVP and clears events", async () => {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });
    if (text.includes("from raids") && text.includes("status = 'active'")) {
      return Promise.resolve([{
        id: raidId,
        source: "party",
        guild_id: null,
        name: "The Practice Shade",
        title: "Group work",
        per_person_minutes: 360,
        participants: 2,
        max_hp: 720,
        damage: 720,
        coins_eligible: true,
      }]);
    }
    if (text.includes("from raid_members")) {
      return Promise.resolve([
        { user_id: userA, display_name: "A", left_raid: false },
        { user_id: userB, display_name: "B", left_raid: false },
      ]);
    }
    if (text.includes("from raid_damage")) {
      return Promise.resolve([
        { user_id: userA, damage: 400 },
        { user_id: userB, damage: 320 },
      ]);
    }
    if (text.includes("from player_state")) {
      return Promise.resolve([{ coins: 200, boss_coins_this_week: 0 }]);
    }
    return Promise.resolve([]);
  };

  const count = await resolveRaidsDraft(tx, defaults, now, () => 0.99);
  assertEquals(count, 1);
  assertEquals(queries.some((q) => q.text.includes("status =") && q.values.includes("victory")), true);
  assertEquals(queries.some((q) => q.text.includes("raid_result")), true);
  assertEquals(queries.some((q) => q.text.includes("delete from raid_events")), true);
  assertEquals(queries.some((q) => q.text.includes("is_mvp")), true);
});
