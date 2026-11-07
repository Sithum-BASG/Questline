import { applyAchievementProgress, bumpCounters, grantTitleIfMissing } from "./apply_achievements.ts";
import type { GameConfig } from "./config.ts";
import {
  applyEscapePenalty,
  bossTier,
  metFairShare,
  mvp,
  mvpWinsItem,
  raidLoot,
  raidResult,
} from "./game/combat.ts";

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function pickSpecialItem(pool: Record<string, number>, roll: number): string {
  let cursor = 0;
  const entries = Object.entries(pool);
  for (const [id, weight] of entries) {
    cursor += numberFrom(weight, 0);
    if (roll < cursor) return id;
  }
  return entries[0]?.[0] ?? "streak_shield";
}

async function grantSpecial(
  userId: string,
  item: string,
  tx: Tx,
): Promise<void> {
  if (item === "streak_shield") {
    await tx`update player_state set shields = shields + 1 where user_id = ${userId}`;
  } else if (item === "focus_potion") {
    await tx`update player_state set potions = potions + 1 where user_id = ${userId}`;
  } else if (item === "reschedule_scroll") {
    await tx`update player_state set scrolls = scrolls + 1 where user_id = ${userId}`;
  } else if (item === "free_chest") {
    await tx`update player_state set free_chests = free_chests + 1 where user_id = ${userId}`;
  }
}

/** Resolves overdue active raids: result, loot, MVP, trophies, feed, inbox, clear events. */
export async function resolveRaidsDraft(
  tx: Tx,
  config: GameConfig,
  now = new Date(),
  random = Math.random,
): Promise<number> {
  const overdue = await tx`
    select *
    from raids
    where status = 'active' and deadline <= ${now.toISOString()}
    for update
  `;

  let resolved = 0;
  for (const raid of overdue) {
    const raidId = String(raid.id);
    const maxHp = numberFrom(raid.max_hp, 0);
    const damage = numberFrom(raid.damage, 0);
    const participants = numberFrom(raid.participants, 1);
    const result = raidResult(damage, maxHp, damage >= maxHp);
    const hours = numberFrom(raid.per_person_minutes, 0) / 60;
    const tier = bossTier(hours);
    const baseCoins = raid.coins_eligible === true ? tier.coins : 0;

    const members = await tx`
      select user_id, display_name, left_raid
      from raid_members where raid_id = ${raidId} for update
    `;
    const damageRows = await tx`
      select user_id, damage from raid_damage where raid_id = ${raidId}
    `;
    const damageByUser = new Map<string, number>();
    for (const row of damageRows) {
      damageByUser.set(String(row.user_id), numberFrom(row.damage, 0));
    }

    const activeMembers = members.filter((row) => row.left_raid !== true);
    const mvpId = mvp(
      activeMembers.map((row) => ({
        id: String(row.user_id),
        damage: damageByUser.get(String(row.user_id)) ?? 0,
      })),
    );

    let mvpItem: string | null = null;
    if (mvpId && mvpWinsItem(random(), numberFrom(config.raid_mvp_item_chance, 0.3))) {
      const pool = (config.special_item_pool ?? {}) as Record<string, number>;
      mvpItem = pickSpecialItem(pool, random());
      await grantSpecial(mvpId, mvpItem, tx);
    }

    for (const member of members) {
      const userId = String(member.user_id);
      const left = member.left_raid === true;
      const personal = damageByUser.get(userId) ?? 0;
      const fair = !left && metFairShare(personal, maxHp, participants);
      const coins = left ? 0 : raidLoot(fair, result, baseCoins);
      const states = await tx`
        select coins, boss_coins_this_week from player_state where user_id = ${userId} for update
      `;
      const currentCoins = numberFrom(states[0]?.coins, 0);
      const weekly = numberFrom(states[0]?.boss_coins_this_week, 0);
      const weeklyCap = numberFrom(config.boss_weekly_coin_cap, 600);
      const payable = Math.min(coins, Math.max(0, weeklyCap - weekly));
      const afterLoot = currentCoins + payable;
      const finalCoins = left ? currentCoins : applyEscapePenalty(afterLoot, result === "escaped", fair);
      const penalty = Math.max(0, afterLoot - finalCoins);

      await tx`
        update player_state set
          coins = ${finalCoins},
          boss_coins_this_week = boss_coins_this_week + ${payable}
        where user_id = ${userId}
      `;
      await tx`
        update raid_members set
          met_fair_share = ${fair},
          is_mvp = ${mvpId === userId}
        where raid_id = ${raidId} and user_id = ${userId}
      `;
      await tx`
        insert into inbox (user_id, type, payload)
        values (
          ${userId},
          'raid_result',
          ${JSON.stringify({
            raidId,
            result,
            name: String(raid.name),
            metFairShare: fair,
            coins: payable,
            penalty,
            isMvp: mvpId === userId,
            mvpItem: mvpId === userId ? mvpItem : null,
            leftRaid: left,
          })}::jsonb
        )
      `;

      if (!left && (result === "victory" || result === "narrow_win")) {
        await tx`
          insert into activity_events (actor_id, type, payload, visible_to)
          values (
            ${userId},
            'raid_won',
            ${JSON.stringify({ raidId, result, name: String(raid.name) })}::jsonb,
            coalesce(
              (select array_agg(friend_id) from friendships where user_id = ${userId} and status = 'accepted'),
              '{}'
            )
          )
        `;
        const counterDeltas: Record<string, number> = { raids_won: 1 };
        if (mvpId === userId) counterDeltas.raid_mvps = 1;
        const counters = await bumpCounters(userId, counterDeltas, tx);
        await applyAchievementProgress(userId, {
          badge: "team_player",
          progress: numberFrom(counters.raids_won, 0),
        }, tx);
        if (numberFrom(counters.raid_mvps, 0) >= 10) {
          await grantTitleIfMissing(userId, "title_raid_champion", tx);
        }
      }
    }

    if (raid.source === "guild" && raid.guild_id && result !== "escaped") {
      await tx`
        insert into guild_trophies (guild_id, raid_id, name, won_at)
        values (${raid.guild_id}, ${raidId}, ${String(raid.name)}, ${now.toISOString()})
        on conflict do nothing
      `;
    }

    await tx`
      update raids set status = ${result} where id = ${raidId}
    `;
    await tx`delete from raid_events where raid_id = ${raidId}`;
    resolved += 1;
  }

  return resolved;
}
