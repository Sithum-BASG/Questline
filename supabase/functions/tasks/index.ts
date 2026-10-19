import { dispatch } from "../_shared/router.ts";
import { judgeTask, challengeTask } from "../_shared/judge_task.ts";
import { rescheduleTask } from "../_shared/reschedule_task.ts";
import { tickTask } from "../_shared/tick_task.ts";

export const handle = dispatch({
  judgeTask: (body, user) => judgeTask(user.id, body),
  challengeTask: (body, user) => challengeTask(user.id, body),
  rescheduleTask: (body, user) => rescheduleTask(user.id, body),
  tickTask: (body, user) => tickTask(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
