import { dispatch } from "../_shared/router.ts";
import { startSession } from "../_shared/start_session.ts";
import { endSession } from "../_shared/end_session.ts";

export const handle = dispatch({
  startSession: (body, user) => startSession(user.id, body),
  endSession: (body, user) => endSession(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
