import { dispatch } from "../_shared/router.ts";
import { startSession } from "../_shared/start_session.ts";

export const handle = dispatch({
  startSession: (body, user) => startSession(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
