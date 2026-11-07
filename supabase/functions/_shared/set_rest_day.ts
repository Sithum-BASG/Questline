import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument } from "./errors.ts";

const inputSchema = z.object({
  weekday: z.number().int().min(0).max(6),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Queues a rest weekday for the next leaderboard week (applied in cron-weekly).
export async function setRestDayDraft(userId: string, body: unknown, tx: Tx): Promise<{ ok: true }> {
  const input = inputSchema.parse(body);
  const rows = await tx`select user_id from player_state where user_id = ${userId} for update`;
  if (!rows[0]) throw invalidArgument("Player state missing");
  await tx`
    update player_state set pending_rest_weekday = ${input.weekday}
    where user_id = ${userId}
  `;
  return { ok: true };
}

export async function setRestDay(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  return await sql.begin(async (tx) => setRestDayDraft(userId, body, tx as unknown as Tx));
}
