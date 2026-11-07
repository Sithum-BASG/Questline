import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument } from "./errors.ts";

const inputSchema = z.object({}).passthrough();

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Arms active_potion for the next qualifying session. Count stays until the session spends it.
export async function usePotionDraft(userId: string, body: unknown, tx: Tx): Promise<{ ok: true }> {
  inputSchema.parse(body ?? {});
  const states = await tx`
    select potions, active_potion from player_state where user_id = ${userId} for update
  `;
  const state = states[0];
  if (!state) throw invalidArgument("Player state missing");
  if (numberFrom(state.potions, 0) < 1) throw invalidArgument("You don't have a focus potion");
  if (state.active_potion === true) return { ok: true };
  await tx`update player_state set active_potion = true where user_id = ${userId}`;
  return { ok: true };
}

export async function usePotion(userId: string, body: unknown, sql: Sql = getSql()): Promise<{ ok: true }> {
  return await sql.begin(async (tx) => usePotionDraft(userId, body, tx as unknown as Tx));
}
