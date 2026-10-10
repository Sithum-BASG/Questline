import { getSql } from "./db.ts";

/// Defaults from `docs/05-BACKEND-SCHEMA.md` §8. A `game_config` row overrides
/// its key for about 60 seconds. Missing table or database falls back to these.
export const defaults = {
  xp_difficulty_multipliers: [0.5, 0.75, 1.0, 1.3, 1.6],
  xp_focus_cap_ratio: 1.5,
  xp_activity_cap_ratio: 1.0,
  xp_activity_share: 0.8,
  xp_tick_share: 0.5,
  xp_on_time_bonus: 0.10,
  xp_late_penalty_per_day: 0.10,
  xp_late_floor: 0.5,
  xp_reschedule_penalty: 0.20,
  xp_daily_focus_minutes_limit: 480,
  xp_grace_seconds: 30,
  level_curve: { base: 80, coef: 5.5, exp: 1.4, round_to: 10, max_level: 50 },
  starter_bonus: { character: 20, first_task: 20, first_session: 40 },
  potion_multiplier: 1.5,
  potion_min_minutes: 25,
  comeback_multiplier: 2.0,
  comeback_inactive_days: 3,
  gear_boost: { common: 0.03, rare: 0.05, epic: 0.07, legendary: 0.09 },
  gear_stat_cap: 0.25,
  deep_focus_min_minutes: 45,
  deep_focus_bonus: 0.10,
  boss_slayer_bonus: 0.20,
  reattune_cost: 200,
  chest_cost: 500,
  chest_rarity_rates: { common: 0.55, rare: 0.30, epic: 0.12, legendary: 0.025, mythic: 0.005 },
  chest_legendary_pity: 30,
  chest_common_pouches: [[50, 0.60], [100, 0.30], [200, 0.09], [500, 0.01]],
  chest_rare_cosmetic_chance: 0.5,
  chest_rare_consumables: { streak_shield: 0.40, focus_potion: 0.35, reschedule_scroll: 0.25 },
  consumable_overflow_coins: 100,
  duplicate_refund: { rare: 100, epic: 200, legendary: 400, mythic: 500 },
  hold_limits: { streak_shield: 2, focus_potion: 3 },
  streak_min_raw_xp: 40,
  day_boundary_hour: 4,
  streak_milestones: {
    "7": { coins: 100 },
    "14": { coins: 150 },
    "30": { freeChest: 1 },
    "60": { item: "frame_unbroken" },
    "100": { title: "title_unbroken" },
  },
  boss_hours_min: 2,
  boss_hours_max: 40,
  boss_tiers: [
    ["minion", 0, 4, 100],
    ["brute", 4, 12, 150],
    ["warlord", 12, 25, 200],
    ["titan", 25, 999, 300],
  ],
  boss_full_loot_threshold: 0.75,
  boss_heal_per_day: 0.03,
  boss_escape_penalty: 100,
  boss_weekly_coin_cap: 600,
  boss_min_hours_before_deadline_for_coins: 48,
  max_active_fights: 15,
  raid_victory_bonus: 0.25,
  raid_narrow_threshold: 0.75,
  raid_fair_share_ratio: 0.5,
  raid_mvp_item_chance: 0.30,
  party_min: 2,
  party_max: 8,
  guild_max: 10,
  guild_quest_goal: 5000,
  guild_quest_min_contribution: 200,
  guild_quest_coins: 100,
  weekly_target_raw_xp: 500,
  weekly_target_coins: 200,
  leaderboard_min_friends: 4,
  leaderboard_rewards: [[300, 0.50], [200, 0.30], [150, 0.20]],
  special_item_pool: { streak_shield: 0.40, focus_potion: 0.35, reschedule_scroll: 0.20, free_chest: 0.05 },
  badge_tier_coins: [50, 100, 200],
  pause_max_days_per_month: 7,
  ai_daily_limit: 50,
  ai_timeout_ms: 10000,
  notif_daily_cap: 2,
  presence_stale_seconds: 120,
  demo_seconds_per_5_minutes: 30,
} as const;

export type GameConfig = { [K in keyof typeof defaults]: unknown };

const cacheMs = 60_000;
let cached: { at: number; value: GameConfig } | undefined;

export function mergeConfig(rows: { key: string; value: unknown }[]): GameConfig {
  const next: Record<string, unknown> = { ...defaults };
  for (const row of rows) {
    if (row.key in defaults) next[row.key] = row.value;
  }
  return next as GameConfig;
}

export function clearConfigCache(): void {
  cached = undefined;
}

/// Reads `game_config` when the table exists. Any failure keeps the defaults.
export async function loadConfig(
  readRows: () => Promise<{ key: string; value: unknown }[]> = readConfigRows,
): Promise<GameConfig> {
  const now = Date.now();
  if (cached && now - cached.at < cacheMs) return cached.value;
  try {
    const value = mergeConfig(await readRows());
    cached = { at: now, value };
    return value;
  } catch {
    const value = mergeConfig([]);
    cached = { at: now, value };
    return value;
  }
}

async function readConfigRows(): Promise<{ key: string; value: unknown }[]> {
  const sql = getSql();
  return await sql<{ key: string; value: unknown }[]>`
    select key, value from game_config
  `;
}
