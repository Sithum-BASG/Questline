import { z } from "zod";

import { loadConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import { friendCode } from "./onboarding.ts";

const emblems = [
  "crest_1",
  "crest_2",
  "crest_3",
  "crest_4",
  "crest_5",
  "crest_6",
  "crest_7",
  "crest_8",
] as const;

const createSchema = z.object({
  name: z.string().trim().min(3).max(24),
  emblem: z.enum(emblems),
});

const joinSchema = z.object({
  code: z.string().trim().min(6).max(12),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export type GuildRow = {
  id: string;
  name: string;
  emblem: string;
  leader_id: string;
  invite_code: string;
  quest_week_id: string | null;
  quest_goal: number;
  quest_progress: number;
  created_at: string;
};

function asGuild(row: Record<string, unknown>): GuildRow {
  return {
    id: String(row.id),
    name: String(row.name),
    emblem: String(row.emblem),
    leader_id: String(row.leader_id),
    invite_code: String(row.invite_code),
    quest_week_id: row.quest_week_id == null ? null : String(row.quest_week_id),
    quest_goal: Number(row.quest_goal),
    quest_progress: Number(row.quest_progress),
    created_at: row.created_at instanceof Date
      ? row.created_at.toISOString()
      : String(row.created_at),
  };
}

async function ensureAcceptedFriends(tx: Tx, a: string, b: string): Promise<void> {
  if (a === b) return;
  await tx`
    insert into friendships (user_id, friend_id, status)
    values (${a}, ${b}, 'accepted')
    on conflict (user_id, friend_id) do update set status = 'accepted', since = now()
  `;
  await tx`
    insert into friendships (user_id, friend_id, status)
    values (${b}, ${a}, 'accepted')
    on conflict (user_id, friend_id) do update set status = 'accepted', since = now()
  `;
}

export async function createGuildDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: { guild_quest_goal: number } = { guild_quest_goal: 5000 },
): Promise<GuildRow> {
  const input = createSchema.parse(body);

  const existing = await tx`
    select guild_id from guild_members where user_id = ${userId} limit 1
  `;
  if (existing[0]) throw invalidArgument("You are already in a guild");

  let guild: Record<string, unknown> | undefined;
  for (let attempt = 0; attempt < 6; attempt++) {
    const code = friendCode(Math.random);
    try {
      const rows = await tx`
        insert into guilds (name, emblem, leader_id, invite_code, quest_goal)
        values (
          ${input.name},
          ${input.emblem},
          ${userId},
          ${code},
          ${Number(config.guild_quest_goal)}
        )
        returning *
      `;
      guild = rows[0];
      break;
    } catch (error) {
      const unique = (error as { code?: string }).code === "23505";
      if (!unique || attempt === 5) throw error;
    }
  }
  if (!guild) throw invalidArgument("Could not create guild");

  await tx`
    insert into guild_members (guild_id, user_id)
    values (${guild.id}, ${userId})
  `;
  await tx`
    update profiles set guild_id = ${guild.id} where id = ${userId}
  `;
  return asGuild(guild);
}

export async function joinGuildDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: { guild_max: number } = { guild_max: 10 },
): Promise<GuildRow> {
  const input = joinSchema.parse(body);
  const code = input.code.toUpperCase();

  const already = await tx`
    select guild_id from guild_members where user_id = ${userId} limit 1
  `;
  if (already[0]) throw invalidArgument("You are already in a guild");

  const guilds = await tx`
    select * from guilds where upper(invite_code) = ${code} limit 1 for update
  `;
  const guild = guilds[0];
  if (!guild) throw notFound("No guild with that invite code");

  const members = await tx`
    select user_id from guild_members where guild_id = ${guild.id} for update
  `;
  if (members.length >= Number(config.guild_max)) {
    throw invalidArgument("This guild is full");
  }

  const leaderId = String(guild.leader_id);
  const friend = await tx`
    select status from friendships
    where user_id = ${userId} and friend_id = ${leaderId} and status = 'accepted'
    limit 1
  `;
  if (!friend[0]) {
    throw invalidArgument("You must be friends with the guild leader to join");
  }

  for (const member of members) {
    await ensureAcceptedFriends(tx, userId, String(member.user_id));
  }

  await tx`
    insert into guild_members (guild_id, user_id)
    values (${guild.id}, ${userId})
  `;
  await tx`
    update profiles set guild_id = ${guild.id} where id = ${userId}
  `;
  return asGuild(guild);
}

export async function leaveGuildDraft(
  userId: string,
  _body: unknown,
  tx: Tx,
): Promise<{ ok: true }> {
  const membership = await tx`
    select guild_id from guild_members where user_id = ${userId} limit 1 for update
  `;
  if (!membership[0]) throw notFound("You are not in a guild");
  const guildId = String(membership[0].guild_id);

  const guilds = await tx`
    select leader_id from guilds where id = ${guildId} for update
  `;
  const guild = guilds[0];
  if (!guild) throw notFound("Guild not found");

  await tx`delete from guild_members where guild_id = ${guildId} and user_id = ${userId}`;
  await tx`update profiles set guild_id = null where id = ${userId}`;

  const remaining = await tx`
    select user_id from guild_members
    where guild_id = ${guildId}
    order by joined_at asc
  `;

  if (remaining.length === 0) {
    await tx`delete from guilds where id = ${guildId}`;
    return { ok: true };
  }

  if (String(guild.leader_id) === userId) {
    await tx`
      update guilds set leader_id = ${remaining[0].user_id} where id = ${guildId}
    `;
  }

  return { ok: true };
}

export async function createGuild(userId: string, body: unknown, sql: Sql = getSql()) {
  const config = await loadConfig();
  return await sql.begin(async (tx) =>
    createGuildDraft(userId, body, tx as unknown as Tx, {
      guild_quest_goal: Number(config.guild_quest_goal),
    })
  );
}

export async function joinGuild(userId: string, body: unknown, sql: Sql = getSql()) {
  const config = await loadConfig();
  return await sql.begin(async (tx) =>
    joinGuildDraft(userId, body, tx as unknown as Tx, {
      guild_max: Number(config.guild_max),
    })
  );
}

export async function leaveGuild(userId: string, body: unknown = {}, sql: Sql = getSql()) {
  return await sql.begin(async (tx) => leaveGuildDraft(userId, body, tx as unknown as Tx));
}
