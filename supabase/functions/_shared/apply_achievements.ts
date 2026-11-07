import { type BadgeId, tierRewards } from "./game/achievements.ts";

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export type AchievementBump = {
  badge: BadgeId;
  /** Absolute progress value used for tier thresholds. */
  progress: number;
};

/**
 * Writes achievement progress, pays newly crossed tiers, grants Tier III titles,
 * and emits feed `badge` events. Idempotent for the same progress value.
 */
export async function applyAchievementProgress(
  userId: string,
  bump: AchievementBump,
  tx: Tx,
): Promise<{ coins: number; titles: string[] }> {
  const badgeId = `badge_${bump.badge}`;
  const rows = await tx`
    select progress, tier from achievements
    where user_id = ${userId} and badge_id = ${badgeId}
    for update
  `;
  const previousTier = numberFrom(rows[0]?.tier, 0);
  const previousProgress = numberFrom(rows[0]?.progress, 0);
  const progress = Math.max(previousProgress, bump.progress);
  const rewards = tierRewards(bump.badge, previousTier, progress);
  const nextTier = rewards.length > 0 ? rewards[rewards.length - 1].tier : previousTier;

  await tx`
    insert into achievements (user_id, badge_id, progress, tier, updated_at)
    values (${userId}, ${badgeId}, ${progress}, ${Math.max(previousTier, nextTier)}, now())
    on conflict (user_id, badge_id) do update set
      progress = greatest(achievements.progress, excluded.progress),
      tier = greatest(achievements.tier, excluded.tier),
      updated_at = now()
  `;

  let coins = 0;
  const titles: string[] = [];
  for (const reward of rewards) {
    coins += reward.coins;
    await tx`
      insert into activity_events (actor_id, type, payload, visible_to)
      values (
        ${userId},
        'badge',
        ${JSON.stringify({ badge: badgeId, tier: reward.tier })}::jsonb,
        coalesce(
          (select array_agg(friend_id) from friendships where user_id = ${userId} and status = 'accepted'),
          '{}'
        )
      )
    `;
    if (reward.title) {
      titles.push(reward.title);
      await tx`
        update player_state
        set owned_titles = owned_titles || ${`{${reward.title}}`}::text[]
        where user_id = ${userId} and not (${reward.title} = any (owned_titles))
      `;
    }
  }
  if (coins > 0) {
    await tx`update player_state set coins = coins + ${coins} where user_id = ${userId}`;
  }
  return { coins, titles };
}

/** Merges counter keys into player_state.counters and returns the next map. */
export async function bumpCounters(
  userId: string,
  deltas: Record<string, number>,
  tx: Tx,
): Promise<Record<string, number>> {
  const rows = await tx`
    select counters from player_state where user_id = ${userId} for update
  `;
  const current = (rows[0]?.counters ?? {}) as Record<string, unknown>;
  const next: Record<string, number> = {};
  for (const [key, value] of Object.entries(current)) {
    next[key] = numberFrom(value, 0);
  }
  for (const [key, delta] of Object.entries(deltas)) {
    next[key] = numberFrom(next[key], 0) + delta;
  }
  await tx`
    update player_state set counters = ${JSON.stringify(next)}::jsonb
    where user_id = ${userId}
  `;
  return next;
}

export async function grantTitleIfMissing(userId: string, titleId: string, tx: Tx): Promise<void> {
  await tx`
    update player_state
    set owned_titles = owned_titles || ${`{${titleId}}`}::text[]
    where user_id = ${userId} and not (${titleId} = any (owned_titles))
  `;
}
