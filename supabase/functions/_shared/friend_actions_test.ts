import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { AppError } from "./errors.ts";
import {
  removeFriendDraft,
  respondFriendRequestDraft,
  sendFriendRequestDraft,
} from "./friend_actions.ts";

const me = "11111111-1111-1111-1111-111111111111";
const them = "22222222-2222-2222-2222-222222222222";

function scripted(options: {
  target?: { id: string; username: string } | null;
  existingStatus?: string | null;
  pendingIn?: boolean;
  accepted?: boolean;
  sameGuild?: boolean;
} = {}) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from profiles") && text.includes("friend_code")) {
      if (options.target === null) return Promise.resolve([]);
      return Promise.resolve([options.target ?? { id: them, username: "ada_lovelace_0042" }]);
    }
    if (text.includes("from profiles") && text.includes("lower(username)")) {
      if (options.target === null) return Promise.resolve([]);
      return Promise.resolve([options.target ?? { id: them, username: "ada_lovelace_0042" }]);
    }
    if (text.includes("from profiles") && text.includes("display_name")) {
      return Promise.resolve([{ username: "me_0001", display_name: "Me" }]);
    }
    if (text.includes("from friendships") && text.includes("for update")) {
      if (options.pendingIn) return Promise.resolve([{ status: "pending_in" }]);
      if (options.accepted) return Promise.resolve([{ status: "accepted" }]);
      return Promise.resolve([]);
    }
    if (text.includes("from friendships")) {
      if (options.existingStatus) return Promise.resolve([{ status: options.existingStatus }]);
      return Promise.resolve([]);
    }
    if (text.includes("from guild_members")) {
      return Promise.resolve(options.sameGuild ? [{ "?column?": 1 }] : []);
    }
    return Promise.resolve([]);
  };
  return { tx, queries };
}

Deno.test("sendFriendRequest creates pending rows and an inbox entry", async () => {
  const { tx, queries } = scripted();
  const result = await sendFriendRequestDraft(me, { username: "ada_lovelace_0042" }, tx);
  assertEquals(result.ok, true);
  assertEquals(queries.some((query) => query.text.includes("pending_out")), true);
  assertEquals(queries.some((query) => query.text.includes("pending_in")), true);
  assertEquals(queries.some((query) => query.text.includes("friend_request")), true);
});

Deno.test("sendFriendRequest by friend code is case-insensitive", async () => {
  const { tx, queries } = scripted();
  await sendFriendRequestDraft(me, { friendCode: "ab12cd34" }, tx);
  assertEquals(queries.some((query) => query.values.includes("AB12CD34")), true);
});

Deno.test("sendFriendRequest rejects self", async () => {
  const { tx } = scripted({ target: { id: me, username: "me_0001" } });
  await assertRejects(() => sendFriendRequestDraft(me, { username: "me_0001" }, tx), AppError);
});

Deno.test("respondFriendRequest accept marks both accepted", async () => {
  const { tx, queries } = scripted({ pendingIn: true });
  const result = await respondFriendRequestDraft(me, { fromUid: them, accept: true }, tx);
  assertEquals(result.accepted, true);
  assertEquals(queries.filter((query) => query.text.includes("status = 'accepted'")).length >= 2, true);
});

Deno.test("respondFriendRequest reject deletes both rows", async () => {
  const { tx, queries } = scripted({ pendingIn: true });
  const result = await respondFriendRequestDraft(me, { fromUid: them, accept: false }, tx);
  assertEquals(result.accepted, false);
  assertEquals(queries.filter((query) => query.text.includes("delete from friendships")).length, 2);
});

Deno.test("removeFriend refuses while sharing a guild", async () => {
  const { tx } = scripted({ accepted: true, sameGuild: true });
  await assertRejects(
    () => removeFriendDraft(me, { friendUid: them }, tx),
    AppError,
  );
});

Deno.test("removeFriend deletes both accepted rows", async () => {
  const { tx, queries } = scripted({ accepted: true });
  await removeFriendDraft(me, { friendUid: them }, tx);
  assertEquals(queries.filter((query) => query.text.includes("delete from friendships")).length, 2);
});
