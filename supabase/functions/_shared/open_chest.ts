import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import {
  rollChest,
  type Cosmetic,
  type LootRates,
  type MythicSet,
  type Rarity,
} from "./game/loot.ts";

const inputSchema = z.object({
  requestId: z.string().trim().min(1).max(64),
  useFreeChest: z.boolean().optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface OpenChestResult {
  rarity: Rarity;
  pityCounter: number;
  drop: Record<string, unknown>;
  refund?: number;
}

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function ratesFrom(config: GameConfig): LootRates {
  const rates = config.chest_rarity_rates as Record<Rarity, number>;
  const pouches = config.chest_common_pouches as [number, number][];
  const consumables = config.chest_rare_consumables as Record<string, number>;
  const refund = config.duplicate_refund as Record<string, number>;
  const hold = config.hold_limits as Record<string, number>;
  return {
    rarity: rates,
    pity: numberFrom(config.chest_legendary_pity, 30),
    pouches,
    rareCosmeticChance: numberFrom(config.chest_rare_cosmetic_chance, 0.5),
    consumables: [
      ["streak_shield", numberFrom(consumables.streak_shield, 0.4)],
      ["focus_potion", numberFrom(consumables.focus_potion, 0.35)],
      ["reschedule_scroll", numberFrom(consumables.reschedule_scroll, 0.25)],
    ],
    overflowCoins: numberFrom(config.consumable_overflow_coins, 100),
    refund: {
      epic: numberFrom(refund.epic, 200),
      legendary: numberFrom(refund.legendary, 400),
      mythic: numberFrom(refund.mythic, 500),
    },
    hold: {
      streak_shield: numberFrom(hold.streak_shield, 2),
      focus_potion: numberFrom(hold.focus_potion, 3),
    },
  };
}

/// Opens one chest for the caller. [requestId] makes retries safe.
export async function openChestDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
  rng: () => number = Math.random,
): Promise<OpenChestResult> {
  const input = inputSchema.parse(body);
  const prior = await tx`
    select result from processed_requests where user_id = ${userId} and request_id = ${input.requestId}
  `;
  if (prior[0]?.result) return prior[0].result as OpenChestResult;

  const states = await tx`
    select coins, free_chests, chests_since_legendary, shields, potions, scrolls
    from player_state where user_id = ${userId} for update
  `;
  const state = states[0];
  if (!state) throw notFound("Player not found");

  const cost = numberFrom(config.chest_cost, 500);
  const useFree = input.useFreeChest === true;
  if (useFree) {
    if (numberFrom(state.free_chests, 0) < 1) throw invalidArgument("You don't have a free chest");
  } else if (numberFrom(state.coins, 0) < cost) {
    throw invalidArgument(`Need ${cost} coins`);
  }

  const ownedRows = await tx`select catalog_id from inventory where user_id = ${userId}`;
  const owned = ownedRows.map((row) => String(row.catalog_id));
  const catalog = await tx`
    select id, rarity, type, set_id from catalog_items
    where source = 'chest' and type in ('skin','background','frame')
  `;
  const cosmetics: Cosmetic[] = catalog
    .filter((row) => row.rarity === "rare" || row.rarity === "epic" || row.rarity === "legendary")
    .map((row) => ({ id: String(row.id), rarity: row.rarity as Cosmetic["rarity"] }));
  const sets = new Map<string, string[]>();
  for (const row of catalog) {
    if (row.rarity !== "mythic" || row.set_id == null) continue;
    const list = sets.get(String(row.set_id)) ?? [];
    list.push(String(row.id));
    sets.set(String(row.set_id), list);
  }
  const mythicSets: MythicSet[] = [...sets.values()].map((ids) => ({ ids }));

  const roll = rollChest(
    {
      chestsSinceLegendary: numberFrom(state.chests_since_legendary, 0),
      owned,
      shields: numberFrom(state.shields, 0),
      potions: numberFrom(state.potions, 0),
      scrolls: numberFrom(state.scrolls, 0),
    },
    cosmetics,
    mythicSets,
    rng,
    ratesFrom(config),
  );

  let refund: number | undefined;
  let coinGain = 0;
  let shieldDelta = 0;
  let potionDelta = 0;
  let scrollDelta = 0;
  const drop: Record<string, unknown> = { ...roll.drop };

  if (roll.drop.kind === "pouch" || roll.drop.kind === "coins") {
    coinGain = roll.drop.coins;
    if (roll.drop.kind === "coins") refund = roll.drop.coins;
  } else if (roll.drop.kind === "consumable") {
    if (roll.drop.id === "streak_shield") shieldDelta = 1;
    else if (roll.drop.id === "focus_potion") potionDelta = 1;
    else scrollDelta = 1;
  } else if (roll.drop.kind === "item") {
    await tx`
      insert into inventory (user_id, catalog_id, source)
      values (${userId}, ${roll.drop.id}, 'chest')
      on conflict (user_id, catalog_id) do nothing
    `;
  } else if (roll.drop.kind === "set") {
    for (const id of roll.drop.ids) {
      await tx`
        insert into inventory (user_id, catalog_id, source)
        values (${userId}, ${id}, 'chest')
        on conflict (user_id, catalog_id) do nothing
      `;
    }
  }

  const nextCoins = numberFrom(state.coins, 0) - (useFree ? 0 : cost) + coinGain;
  await tx`
    update player_state set
      coins = ${nextCoins},
      free_chests = ${numberFrom(state.free_chests, 0) - (useFree ? 1 : 0)},
      shields = ${numberFrom(state.shields, 0) + shieldDelta},
      potions = ${numberFrom(state.potions, 0) + potionDelta},
      scrolls = ${numberFrom(state.scrolls, 0) + scrollDelta},
      chests_since_legendary = ${roll.pityCounter}
    where user_id = ${userId}
  `;

  if (roll.rarity === "epic" || roll.rarity === "legendary" || roll.rarity === "mythic") {
    await tx`
      insert into activity_events (actor_id, type, payload, visible_to)
      values (
        ${userId}, 'chest_drop', ${JSON.stringify({ rarity: roll.rarity })}::jsonb,
        coalesce((select array_agg(friend_id) from friendships where user_id = ${userId} and status = 'accepted'), '{}')
      )
    `;
  }

  const result: OpenChestResult = {
    rarity: roll.rarity,
    pityCounter: roll.pityCounter,
    drop,
    refund,
  };
  await tx`
    insert into processed_requests (user_id, request_id, result)
    values (${userId}, ${input.requestId}, ${JSON.stringify(result)}::jsonb)
  `;
  return result;
}

export async function openChest(userId: string, body: unknown, sql: Sql = getSql()): Promise<OpenChestResult> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => openChestDraft(userId, body, tx as unknown as Tx, config));
}
