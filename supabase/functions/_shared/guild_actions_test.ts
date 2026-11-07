import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { AppError } from "./errors.ts";
import {
  createGuildDraft,
  joinGuildDraft,
  leaveGuildDraft,
} from "./guild_actions.ts";

const me = "11111111-1111-1111-1111-111111111111";
const leader = "22222222-2222-2222-2222-222222222222";
const other = "33333333-3333-3333-3333-333333333333";
const guildId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

function scripted(options: {
  alreadyInGuild?: boolean;
  guild?: Record<string, unknown> | null;
  members?: string[];
  friendsWithLeader?: boolean;
  remainingAfterLeave?: string[];
  isLeader?: boolean;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join("?");
    queries.push({ text, values });

    if (text.includes("insert into guilds")) {
      return Promise.resolve([{
        id: guildId,
        name: values[0],
        emblem: values[1],
        leader_id: values[2],
        invite_code: values[3],
        quest_week_id: null,
        quest_goal: values[4],
        quest_progress: 0,
        created_at: new Date("2026-10-10T00:00:00Z"),
      }]);
    }
    if (text.includes("from guilds where upper(invite_code)")) {
      if (options.guild === null) return Promise.resolve([]);
      return Promise.resolve([options.guild ?? {
        id: guildId,
        name: "Night Owls",
        emblem: "crest_1",
        leader_id: leader,
        invite_code: "ABCD1234",
        quest_week_id: null,
        quest_goal: 5000,
        quest_progress: 0,
        created_at: new Date("2026-10-10T00:00:00Z"),
      }]);
    }
    if (text.includes("select user_id from guild_members where guild_id") && text.includes("for update")) {
      return Promise.resolve((options.members ?? [leader]).map((user_id) => ({ user_id })));
    }
    if (text.includes("from friendships") && text.includes("status = 'accepted'")) {
      return Promise.resolve(options.friendsWithLeader ? [{ status: "accepted" }] : []);
    }
    if (text.includes("select guild_id from guild_members where user_id")) {
      return Promise.resolve(options.alreadyInGuild ? [{ guild_id: guildId }] : []);
    }
    if (text.includes("select leader_id from guilds")) {
      return Promise.resolve([{
        leader_id: options.isLeader === false ? leader : me,
      }]);
    }
    if (text.includes("order by joined_at")) {
      return Promise.resolve((options.remainingAfterLeave ?? []).map((user_id) => ({ user_id })));
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("createGuild inserts guild, membership and profile link", async () => {
  const { tx, queries } = scripted();
  const guild = await createGuildDraft(me, { name: "Night Owls", emblem: "crest_2" }, tx);
  assertEquals(guild.name, "Night Owls");
  assertEquals(guild.emblem, "crest_2");
  assertEquals(guild.leader_id, me);
  assertEquals(queries.some((q) => q.text.includes("insert into guild_members")), true);
  assertEquals(queries.some((q) => q.text.includes("update profiles set guild_id")), true);
});

Deno.test("createGuild rejects when already a member", async () => {
  const { tx } = scripted({ alreadyInGuild: true });
  await assertRejects(
    () => createGuildDraft(me, { name: "Night Owls", emblem: "crest_1" }, tx),
    AppError,
  );
});

Deno.test("joinGuild requires friendship with the leader and auto-befriends members", async () => {
  const { tx, queries } = scripted({
    members: [leader, other],
    friendsWithLeader: true,
  });
  const guild = await joinGuildDraft(me, { code: "abcd1234" }, tx, { guild_max: 10 });
  assertEquals(guild.id, guildId);
  assertEquals(queries.filter((q) => q.text.includes("insert into friendships")).length >= 4, true);
  assertEquals(queries.some((q) => q.text.includes("insert into guild_members")), true);
});

Deno.test("joinGuild refuses strangers to the leader", async () => {
  const { tx } = scripted({ friendsWithLeader: false });
  await assertRejects(() => joinGuildDraft(me, { code: "ABCD1234" }, tx), AppError);
});

Deno.test("joinGuild refuses a full guild", async () => {
  const { tx } = scripted({
    friendsWithLeader: true,
    members: Array.from({ length: 10 }, (_, i) => `00000000-0000-0000-0000-00000000000${i}`),
  });
  await assertRejects(() => joinGuildDraft(me, { code: "ABCD1234" }, tx, { guild_max: 10 }), AppError);
});

Deno.test("leaveGuild deletes an empty guild", async () => {
  const { tx, queries } = scripted({
    alreadyInGuild: true,
    remainingAfterLeave: [],
    isLeader: true,
  });
  const result = await leaveGuildDraft(me, {}, tx);
  assertEquals(result.ok, true);
  assertEquals(queries.some((q) => q.text.includes("delete from guilds")), true);
});

Deno.test("leaveGuild passes leadership to the oldest remaining member", async () => {
  const { tx, queries } = scripted({
    alreadyInGuild: true,
    remainingAfterLeave: [other],
    isLeader: true,
  });
  await leaveGuildDraft(me, {}, tx);
  assertEquals(
    queries.some((q) => q.text.includes("update guilds set leader_id") && q.values.includes(other)),
    true,
  );
});
