import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument } from "./errors.ts";

const inputSchema = z.object({
  active: z.boolean(),
  until: z.string().datetime({ offset: true }).optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function monthKey(date: Date): string {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

function daysBetween(from: Date, to: Date): number {
  const ms = to.getTime() - from.getTime();
  return Math.max(0, Math.ceil(ms / 86_400_000));
}

/// Arms or clears pause mode. Max pause_max_days_per_month per calendar month.
export async function setPauseDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
): Promise<{ ok: true }> {
  const input = inputSchema.parse(body);
  const rows = await tx`
    select pause_active, pause_until, pause_days_used, pause_month
    from player_state where user_id = ${userId} for update
  `;
  const row = rows[0];
  if (!row) throw invalidArgument("Player state missing");

  if (!input.active) {
    await tx`
      update player_state set pause_active = false, pause_until = null
      where user_id = ${userId}
    `;
    return { ok: true };
  }

  if (!input.until) throw invalidArgument("Pause needs an end time");
  const until = new Date(input.until);
  if (until.getTime() <= now.getTime()) throw invalidArgument("Pause end must be in the future");

  const maxDays = numberFrom(config.pause_max_days_per_month, 7);
  const month = monthKey(now);
  let used = numberFrom(row.pause_days_used, 0);
  if (row.pause_month !== month) used = 0;

  const requestDays = daysBetween(now, until);
  if (used + requestDays > maxDays) {
    throw invalidArgument(`Pause is limited to ${maxDays} days per month (${maxDays - used} left)`);
  }

  await tx`
    update player_state set
      pause_active = true,
      pause_until = ${until.toISOString()},
      pause_days_used = ${used + requestDays},
      pause_month = ${month}
    where user_id = ${userId}
  `;
  return { ok: true };
}

export async function setPause(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => setPauseDraft(userId, body, tx as unknown as Tx, config));
}
