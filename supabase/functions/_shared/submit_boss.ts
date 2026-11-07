import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import { bossTier, soloLoot } from "./game/combat.ts";

const inputSchema = z.object({
  bossId: z.string().uuid(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface SubmitBossResult {
  result: "defeated";
  loot: "full" | "half";
  coins: number;
  damage: number;
  maxHp: number;
  name: string;
  tier: string;
}

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Marks a solo boss submitted before its deadline and pays loot once.
export async function submitBossDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
  now = new Date(),
): Promise<SubmitBossResult> {
  const { bossId } = inputSchema.parse(body);
  const bosses = await tx`
    select id, name, title, tier, hours, max_hp, damage, deadline, status, coins_eligible, loot
    from bosses
    where id = ${bossId} and user_id = ${userId}
    for update
  `;
  const boss = bosses[0];
  if (!boss) throw notFound("Boss not found");
  if (boss.status === "defeated") {
    const stored = boss.loot as Record<string, unknown> | null;
    if (stored && typeof stored === "object") {
      return {
        result: "defeated",
        loot: stored.loot === "half" ? "half" : "full",
        coins: numberFrom(stored.coins, 0),
        damage: numberFrom(boss.damage, 0),
        maxHp: numberFrom(boss.max_hp, 0),
        name: String(boss.name),
        tier: String(boss.tier),
      };
    }
  }
  if (boss.status !== "active" && boss.status !== "staggered") {
    throw invalidArgument("This boss can no longer be submitted");
  }
  const deadline = new Date(String(boss.deadline));
  if (deadline.getTime() <= now.getTime()) {
    throw invalidArgument("The deadline has passed");
  }

  const maxHp = numberFrom(boss.max_hp, 0);
  const damage = numberFrom(boss.damage, 0);
  const ratio = maxHp > 0 ? damage / maxHp : 0;
  const tier = bossTier(numberFrom(boss.hours, 2));
  const states = await tx`
    select coins, boss_coins_this_week, counters
    from player_state where user_id = ${userId} for update
  `;
  const state = states[0];
  if (!state) throw invalidArgument("Player state missing");

  const paid = soloLoot(ratio, tier.coins, {
    weeklyCoins: numberFrom(state.boss_coins_this_week, 0),
    coinsEligible: boss.coins_eligible === true,
    weeklyCap: numberFrom(config.boss_weekly_coin_cap, 600),
    fullThreshold: numberFrom(config.boss_full_loot_threshold, 0.75),
  });

  const lootPayload = { loot: paid.loot, coins: paid.coins, tier: tier.tier };
  await tx`
    update bosses set
      status = 'defeated',
      loot = ${JSON.stringify(lootPayload)}::jsonb,
      result_seen = false
    where id = ${bossId} and user_id = ${userId}
  `;

  const counters = (state.counters ?? {}) as Record<string, unknown>;
  const defeated = numberFrom(counters.bosses_defeated, 0) + 1;
  const nextCounters = { ...counters, bosses_defeated: defeated };
  await tx`
    update player_state set
      coins = coins + ${paid.coins},
      boss_coins_this_week = boss_coins_this_week + ${paid.coins},
      counters = ${JSON.stringify(nextCounters)}::jsonb
    where user_id = ${userId}
  `;

  const profiles = await tx`select show_boss_names from profiles where id = ${userId}`;
  const showName = profiles[0]?.show_boss_names === true;
  await tx`
    insert into activity_events (actor_id, type, payload, visible_to)
    values (
      ${userId},
      'boss_defeated',
      ${JSON.stringify({
        bossId,
        tier: tier.tier,
        name: showName ? String(boss.name) : null,
        loot: paid.loot,
      })}::jsonb,
      coalesce((select array_agg(friend_id) from friendships where user_id = ${userId} and status = 'accepted'), '{}')
    )
  `;

  return {
    result: "defeated",
    loot: paid.loot,
    coins: paid.coins,
    damage,
    maxHp,
    name: String(boss.name),
    tier: String(boss.tier),
  };
}

export async function submitBoss(
  userId: string,
  body: unknown,
  sql: Sql = getSql(),
): Promise<SubmitBossResult> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => submitBossDraft(userId, body, tx as unknown as Tx, config));
}
