import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";

const sendSchema = z.union([
  z.object({ username: z.string().trim().min(1).max(40) }),
  z.object({ friendCode: z.string().trim().min(6).max(12) }),
]);

const respondSchema = z.object({
  fromUid: z.string().uuid(),
  accept: z.boolean(),
});

const removeSchema = z.object({
  friendUid: z.string().uuid(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

async function findTarget(tx: Tx, body: z.infer<typeof sendSchema>): Promise<{ id: string; username: string }> {
  if ("username" in body) {
    const rows = await tx`
      select id, username from profiles
      where lower(username) = lower(${body.username})
      limit 1
    `;
    const row = rows[0];
    if (!row) throw notFound("No player with that username");
    return { id: String(row.id), username: String(row.username) };
  }
  const code = body.friendCode.toUpperCase();
  const rows = await tx`
    select id, username from profiles
    where upper(friend_code) = ${code}
    limit 1
  `;
  const row = rows[0];
  if (!row) throw notFound("No player with that friend code");
  return { id: String(row.id), username: String(row.username) };
}

/// Sends a friend request. Creates pending_out / pending_in and an inbox entry.
export async function sendFriendRequestDraft(
  userId: string,
  body: unknown,
  tx: Tx,
): Promise<{ ok: true }> {
  const input = sendSchema.parse(body);
  const target = await findTarget(tx, input);
  if (target.id === userId) throw invalidArgument("You cannot friend yourself");

  const existing = await tx`
    select status from friendships
    where user_id = ${userId} and friend_id = ${target.id}
  `;
  const status = existing[0]?.status;
  if (status === "accepted") throw invalidArgument("You are already friends");
  if (status === "pending_out" || status === "pending_in") {
    return { ok: true };
  }

  const me = await tx`select username, display_name from profiles where id = ${userId}`;
  if (!me[0]) throw invalidArgument("Profile missing");

  await tx`
    insert into friendships (user_id, friend_id, status)
    values (${userId}, ${target.id}, 'pending_out')
    on conflict (user_id, friend_id) do update set status = 'pending_out', since = now()
  `;
  await tx`
    insert into friendships (user_id, friend_id, status)
    values (${target.id}, ${userId}, 'pending_in')
    on conflict (user_id, friend_id) do update set status = 'pending_in', since = now()
  `;
  await tx`
    insert into inbox (user_id, type, payload)
    values (
      ${target.id},
      'friend_request',
      ${JSON.stringify({
        fromUid: userId,
        username: me[0].username,
        displayName: me[0].display_name,
      })}::jsonb
    )
  `;
  return { ok: true };
}

export async function respondFriendRequestDraft(
  userId: string,
  body: unknown,
  tx: Tx,
): Promise<{ ok: true; accepted: boolean }> {
  const input = respondSchema.parse(body);
  if (input.fromUid === userId) throw invalidArgument("Invalid request");

  const mine = await tx`
    select status from friendships
    where user_id = ${userId} and friend_id = ${input.fromUid}
    for update
  `;
  if (!mine[0] || mine[0].status !== "pending_in") {
    throw invalidArgument("No pending request from that player");
  }

  if (!input.accept) {
    await tx`delete from friendships where user_id = ${userId} and friend_id = ${input.fromUid}`;
    await tx`delete from friendships where user_id = ${input.fromUid} and friend_id = ${userId}`;
    return { ok: true, accepted: false };
  }

  await tx`
    update friendships set status = 'accepted', since = now()
    where user_id = ${userId} and friend_id = ${input.fromUid}
  `;
  await tx`
    update friendships set status = 'accepted', since = now()
    where user_id = ${input.fromUid} and friend_id = ${userId}
  `;
  return { ok: true, accepted: true };
}

export async function removeFriendDraft(
  userId: string,
  body: unknown,
  tx: Tx,
): Promise<{ ok: true }> {
  const input = removeSchema.parse(body);
  if (input.friendUid === userId) throw invalidArgument("Invalid friend");

  const mine = await tx`
    select status from friendships
    where user_id = ${userId} and friend_id = ${input.friendUid}
    for update
  `;
  if (!mine[0] || mine[0].status !== "accepted") {
    throw notFound("Friendship not found");
  }

  const sharedGuild = await tx`
    select 1
    from guild_members a
    join guild_members b on b.guild_id = a.guild_id
    where a.user_id = ${userId} and b.user_id = ${input.friendUid}
    limit 1
  `;
  if (sharedGuild.length > 0) {
    throw invalidArgument("Leave the guild before removing this friend");
  }

  await tx`delete from friendships where user_id = ${userId} and friend_id = ${input.friendUid}`;
  await tx`delete from friendships where user_id = ${input.friendUid} and friend_id = ${userId}`;
  return { ok: true };
}

export async function sendFriendRequest(userId: string, body: unknown, sql: Sql = getSql()) {
  return await sql.begin(async (tx) => sendFriendRequestDraft(userId, body, tx as unknown as Tx));
}

export async function respondFriendRequest(userId: string, body: unknown, sql: Sql = getSql()) {
  return await sql.begin(async (tx) => respondFriendRequestDraft(userId, body, tx as unknown as Tx));
}

export async function removeFriend(userId: string, body: unknown, sql: Sql = getSql()) {
  return await sql.begin(async (tx) => removeFriendDraft(userId, body, tx as unknown as Tx));
}
