import { dispatch } from "../_shared/router.ts";
import { judgeTask } from "../_shared/judge_task.ts";

export const handle = dispatch({
  judgeTask: (body, user) => judgeTask(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
