import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";
import { refreshEquippedGear } from "./refresh_equipped_gear.ts";

const inputSchema = z.object({
  catalogId: z.string().trim().min(1),
  slot: z.enum(["weapon", "armour", "accessory"]),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Equips owned gear into a slot (one item per slot) and refreshes friend summaries.
export async function equipGearDraft(userId: string, body: unknown, tx: Tx): Promise<{ ok: true }> {
  const input = inputSchema.parse(body);

  const owned = await tx`
    select inventory.catalog_id, inventory.equipped_slot, catalog_items.type, catalog_items.slot
    from inventory
    join catalog_items on catalog_items.id = inventory.catalog_id
    where inventory.user_id = ${userId} and inventory.catalog_id = ${input.catalogId}
    for update of inventory
  `;
  const item = owned[0];
  if (!item) throw notFound("You don't own that item");
  if (item.type !== "gear") throw invalidArgument("Only gear can be equipped");
  if (item.slot !== input.slot) throw invalidArgument("That item doesn't fit this slot");

  await tx`
    update inventory set equipped_slot = null
    where user_id = ${userId} and equipped_slot = ${input.slot}
  `;
  await tx`
    update inventory set equipped_slot = ${input.slot}
    where user_id = ${userId} and catalog_id = ${input.catalogId}
  `;
  await refreshEquippedGear(tx, userId);
  return { ok: true };
}

export async function equipGear(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  return await sql.begin(async (tx) => equipGearDraft(userId, body, tx as unknown as Tx));
}
