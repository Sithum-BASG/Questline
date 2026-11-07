import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { applyEscapePenalty } from "./game/combat.ts";
import { resolveRaidsDraft } from "./raid_resolve.ts";

const inputSchema = z.object({
  now: z.string().datetime({ offset: true }).optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Escapes overdue solo bosses and closes stale focus sessions (> 3× estimate).
export async function runDeadlinesDraft(
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
): Promise<{ escaped: number; sessionsClosed: number; raidsResolved: number }> {
  inputSchema.parse(body ?? {});

  const overdue = await tx`
    select id, user_id, name, tier, max_hp, damage
    from bosses
    where status in ('active', 'staggered') and deadline <= ${now.toISOString()}
    for update
  `;

  let escaped = 0;
  for (const boss of overdue) {
    const userId = String(boss.user_id);
    const states = await tx`
      select coins from player_state where user_id = ${userId} for update
    `;
    const coins = numberFrom(states[0]?.coins, 0);
    const finalCoins = applyEscapePenalty(coins, true, false);
    const deducted = coins - finalCoins;

    await tx`
      update bosses set
        status = 'escaped',
        loot = ${JSON.stringify({ loot: "none", coins: 0 })}::jsonb,
        result_seen = false
      where id = ${boss.id} and user_id = ${userId}
    `;
    await tx`
      update player_state set coins = ${finalCoins}
      where user_id = ${userId}
    `;
    await tx`
      insert into inbox (user_id, type, payload)
      values (
        ${userId},
        'boss_result',
        ${JSON.stringify({
          bossId: boss.id,
          result: "escaped",
          name: String(boss.name),
          tier: String(boss.tier),
          penalty: deducted,
        })}::jsonb
      )
    `;
    escaped += 1;
  }

  const activeSessions = await tx`
    select s.id, s.user_id, s.started_at, t.est_minutes
    from sessions s
    join tasks t on t.id = s.task_id and t.user_id = s.user_id
    where s.status = 'active'
  `;
  let sessionsClosed = 0;
  for (const session of activeSessions) {
    const est = numberFrom(session.est_minutes, 30);
    const started = Date.parse(String(session.started_at));
    if (!Number.isFinite(started)) continue;
    const limitMs = Math.max(est, 5) * 3 * 60_000;
    if (now.getTime() - started <= limitMs) continue;
    await tx`
      update sessions set
        status = 'broken',
        ended_at = ${now.toISOString()},
        processed = true,
        summary = ${JSON.stringify({
          rawXp: 0,
          finalXp: 0,
          verifiedMinutes: 0,
          countedMinutes: 0,
          broken: true,
          xpTotal: 0,
          level: 1,
          rewards: [],
        })}::jsonb
      where id = ${session.id} and user_id = ${session.user_id} and status = 'active'
    `;
    sessionsClosed += 1;
  }

  const raidsResolved = await resolveRaidsDraft(tx, config, now);
  return { escaped, sessionsClosed, raidsResolved };
}

export async function runDeadlines(
  body: unknown = {},
  sql: Sql = getSql(),
): Promise<{ escaped: number; sessionsClosed: number; raidsResolved: number }> {
  const config = await loadConfig();
  const parsed = inputSchema.parse(body ?? {});
  const now = parsed.now ? new Date(parsed.now) : new Date();
  return await sql.begin(async (tx) => runDeadlinesDraft(body, tx as unknown as Tx, config, now));
}
