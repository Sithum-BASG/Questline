import { createClient } from "@supabase/supabase-js";

import { getSql, type Sql } from "./db.ts";
import { AppError } from "./errors.ts";

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Leaves guilds/raids cleanly so auth.admin.deleteUser can cascade the rest.
export async function deleteAccountDraft(userId: string, tx: Tx): Promise<void> {
  await tx`
    update raid_members set left_raid = true
    where user_id = ${userId} and left_raid = false
  `;

  const led = await tx`
    select id from guilds where leader_id = ${userId}
  `;
  for (const row of led) {
    const guildId = row.id as string;
    const next = await tx`
      select user_id from guild_members
      where guild_id = ${guildId} and user_id <> ${userId}
      order by joined_at asc
      limit 1
    `;
    if (next.length === 0) {
      await tx`delete from guilds where id = ${guildId}`;
    } else {
      await tx`update guilds set leader_id = ${next[0].user_id as string} where id = ${guildId}`;
    }
  }

  await tx`delete from guild_members where user_id = ${userId}`;
  await tx`update profiles set guild_id = null where id = ${userId}`;

  await tx`
    update activity_events
    set visible_to = array_remove(visible_to, ${userId}::uuid)
    where ${userId}::uuid = any(visible_to)
  `;
}

export async function deleteAccount(userId: string, sql: Sql = getSql()): Promise<{ ok: true }> {
  await sql.begin(async (tx) => {
    await deleteAccountDraft(userId, tx as unknown as Tx);
  });

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new AppError("internal", "Admin delete is not configured", 500);

  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) throw new AppError("internal", error.message, 500);
  return { ok: true };
}
