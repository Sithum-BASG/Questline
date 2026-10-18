import { dispatch } from "../_shared/router.ts";
import { judgeTask, challengeTask } from "../_shared/judge_task.ts";
import { rescheduleTask } from "../_shared/reschedule_task.ts";

export const handle = dispatch({
  judgeTask: (body, user) => judgeTask(user.id, body),
  challengeTask: (body, user) => challengeTask(user.id, body),
  rescheduleTask: (body, user) => rescheduleTask(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
