import { dispatch } from "../_shared/router.ts";
import { openChest } from "../_shared/open_chest.ts";

export const handle = dispatch({
  openChest: (body, user) => openChest(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
