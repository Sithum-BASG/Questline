import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import { refreshEquippedGear } from "./refresh_equipped_gear.ts";

const inputSchema = z.object({
  catalogId: z.string().trim().min(1),
  stat: z.enum(["intellect", "vitality", "craft", "charisma"]),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Sets gear attunement. First pick is free; changing it costs reattune_cost coins.
export async function attuneGearDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
): Promise<{ ok: true }> {
  const input = inputSchema.parse(body);

  const owned = await tx`
    select inventory.catalog_id, inventory.attuned_stat, inventory.equipped_slot, catalog_items.type
    from inventory
    join catalog_items on catalog_items.id = inventory.catalog_id
    where inventory.user_id = ${userId} and inventory.catalog_id = ${input.catalogId}
    for update of inventory
  `;
  const item = owned[0];
  if (!item) throw notFound("You don't own that item");
  if (item.type !== "gear") throw invalidArgument("Only gear can be attuned");

  const previous = item.attuned_stat == null ? null : String(item.attuned_stat);
  if (previous === input.stat) return { ok: true };

  if (previous != null) {
    const cost = numberFrom(config.reattune_cost, 200);
    const states = await tx`select coins from player_state where user_id = ${userId} for update`;
    const coins = numberFrom(states[0]?.coins, 0);
    if (coins < cost) throw invalidArgument("Not enough coins to re-attune");
    await tx`update player_state set coins = ${coins - cost} where user_id = ${userId}`;
  }

  await tx`
    update inventory set attuned_stat = ${input.stat}
    where user_id = ${userId} and catalog_id = ${input.catalogId}
  `;
  if (item.equipped_slot != null) await refreshEquippedGear(tx, userId);
  return { ok: true };
}

export async function attuneGear(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => attuneGearDraft(userId, body, tx as unknown as Tx, config));
}
