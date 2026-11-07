import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { notFound } from "./errors.ts";

const inputSchema = z.object({
  bossId: z.string().uuid(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Marks a defeated/escaped result as seen so Home does not reopen it.
export async function ackBossResultDraft(userId: string, body: unknown, tx: Tx): Promise<{ ok: true }> {
  const { bossId } = inputSchema.parse(body);
  const rows = await tx`
    update bosses set result_seen = true
    where id = ${bossId} and user_id = ${userId} and status in ('defeated', 'escaped')
    returning id
  `;
  if (!rows[0]) throw notFound("Boss result not found");
  return { ok: true };
}

export async function ackBossResult(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  return await sql.begin(async (tx) => ackBossResultDraft(userId, body, tx as unknown as Tx));
}
