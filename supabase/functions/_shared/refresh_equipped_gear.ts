type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Rebuilds friend_summaries.equipped_gear from the caller's equipped inventory.
export async function refreshEquippedGear(tx: Tx, userId: string): Promise<void> {
  await tx`
    update friend_summaries set
      equipped_gear = coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'slot', equipped_slot,
            'catalog_id', catalog_id,
            'attuned_stat', attuned_stat
          )
          order by equipped_slot
        )
        from inventory
        where user_id = ${userId} and equipped_slot is not null
      ), '[]'::jsonb),
      updated_at = now()
    where user_id = ${userId}
  `;
}
