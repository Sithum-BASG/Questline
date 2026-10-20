import { attuneGear } from "../_shared/attune_gear.ts";
import { equipGear } from "../_shared/equip_gear.ts";
import { dispatch } from "../_shared/router.ts";
import { openChest } from "../_shared/open_chest.ts";
import { usePotion } from "../_shared/use_potion.ts";

export const handle = dispatch({
  openChest: (body, user) => openChest(user.id, body),
  equipGear: (body, user) => equipGear(user.id, body),
  attuneGear: (body, user) => attuneGear(user.id, body),
  usePotion: (body, user) => usePotion(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
