import { createRaid, joinRaid, leaveRaid } from "../_shared/create_raid.ts";
import { dispatch } from "../_shared/router.ts";

export const handle = dispatch({
  createRaid: (body, user) => createRaid(user.id, body),
  joinRaid: (body, user) => joinRaid(user.id, body),
  leaveRaid: (body, user) => leaveRaid(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
