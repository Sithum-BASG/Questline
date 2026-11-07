import { createBoss } from "../_shared/create_boss.ts";
import { dispatch } from "../_shared/router.ts";

export const handle = dispatch({
  createBoss: (body, user) => createBoss(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
