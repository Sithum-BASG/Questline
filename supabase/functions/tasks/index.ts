import { dispatch } from "../_shared/router.ts";
import { challengeTask, judgeTask } from "../_shared/judge_task.ts";

export const handle = dispatch({
  judgeTask: (body, user) => judgeTask(user.id, body),
  challengeTask: (body, user) => challengeTask(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
