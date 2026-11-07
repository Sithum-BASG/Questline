import { assertEquals } from "jsr:@std/assert@1";

import { deleteAccountDraft } from "./delete_account.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const otherId = "22222222-2222-2222-2222-222222222222";
const guildId = "33333333-3333-3333-3333-333333333333";

Deno.test("deleteAccountDraft passes leadership when another member remains", async () => {
  const queries: string[] = [];
  let step = 0;
  const tx = (strings: TemplateStringsArray, ..._values: unknown[]) => {
    const text = strings.join(" ");
    queries.push(text);
    step += 1;
    if (text.includes("select id from guilds")) {
      return Promise.resolve([{ id: guildId }]);
    }
    if (text.includes("select user_id from guild_members")) {
      return Promise.resolve([{ user_id: otherId }]);
    }
    return Promise.resolve([]);
  };
  await deleteAccountDraft(userId, tx);
  assertEquals(queries.some((text) => text.includes("update guilds set leader_id")), true);
  assertEquals(queries.some((text) => text.includes("delete from guilds")), false);
  assertEquals(step > 3, true);
});

Deno.test("deleteAccountDraft deletes an empty guild when leader is alone", async () => {
  const queries: string[] = [];
  const tx = (strings: TemplateStringsArray, ..._values: unknown[]) => {
    const text = strings.join(" ");
    queries.push(text);
    if (text.includes("select id from guilds")) {
      return Promise.resolve([{ id: guildId }]);
    }
    if (text.includes("select user_id from guild_members")) {
      return Promise.resolve([]);
    }
    return Promise.resolve([]);
  };
  await deleteAccountDraft(userId, tx);
  assertEquals(queries.some((text) => text.includes("delete from guilds")), true);
  assertEquals(queries.some((text) => text.includes("update raid_members")), true);
  assertEquals(queries.some((text) => text.includes("array_remove")), true);
});
