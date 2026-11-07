import { ackBossResult } from "../_shared/ack_boss_result.ts";
import { createBoss } from "../_shared/create_boss.ts";
import { dispatch } from "../_shared/router.ts";
import { submitBoss } from "../_shared/submit_boss.ts";

export const handle = dispatch({
  createBoss: (body, user) => createBoss(user.id, body),
  submitBoss: (body, user) => submitBoss(user.id, body),
  ackBossResult: (body, user) => ackBossResult(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
