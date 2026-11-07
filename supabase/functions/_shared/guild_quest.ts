import type { GameConfig } from "./config.ts";

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/** True when a member earned enough raw XP this week to receive quest coins. */
export function guildQuestEligible(
  contribution: number,
  guildProgress: number,
  goal: number,
  minContribution: number,
): boolean {
  return guildProgress >= goal && contribution >= minContribution;
}

/** Coins paid to one eligible contributor (cron-weekly reads this). */
export function guildQuestPayoutCoins(config: { guild_quest_coins: number }): number {
  return numberFrom(config.guild_quest_coins, 100);
}

/**
 * Adds the caller's raw XP to their guild weekly quest.
 * Resets progress and contributions when the leaderboard week rolls.
 * Payout itself is handled by cron-weekly via `guildQuestEligible`.
 */
export async function applyGuildQuestProgress(
  userId: string,
  rawXp: number,
  week: string,
  tx: Tx,
  config: GameConfig,
): Promise<void> {
  if (rawXp <= 0) return;

  const membership = await tx`
    select guild_id, quest_contribution from guild_members
    where user_id = ${userId}
    limit 1 for update
  `;
  const row = membership[0];
  if (!row) return;
  const guildId = String(row.guild_id);

  const guilds = await tx`
    select id, quest_week_id, quest_progress, quest_goal
    from guilds where id = ${guildId} for update
  `;
  const guild = guilds[0];
  if (!guild) return;

  const goal = numberFrom(guild.quest_goal, numberFrom(config.guild_quest_goal, 5000));
  const sameWeek = guild.quest_week_id === week;
  if (!sameWeek) {
    await tx`
      update guild_members set quest_contribution = 0 where guild_id = ${guildId}
    `;
  }

  const previousProgress = sameWeek ? numberFrom(guild.quest_progress, 0) : 0;
  const nextProgress = Math.min(goal, previousProgress + rawXp);
  const previousContribution = sameWeek ? numberFrom(row.quest_contribution, 0) : 0;
  const nextContribution = previousContribution + rawXp;

  await tx`
    update guilds set
      quest_week_id = ${week},
      quest_progress = ${nextProgress},
      quest_goal = ${goal}
    where id = ${guildId}
  `;
  await tx`
    update guild_members set quest_contribution = ${nextContribution}
    where guild_id = ${guildId} and user_id = ${userId}
  `;
}
