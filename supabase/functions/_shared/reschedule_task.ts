import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";

const inputSchema = z.object({
  taskId: z.string().uuid(),
  newDueAt: z.string().datetime({ offset: true }),
  useScroll: z.boolean().optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

/// Moves an open task's due date. A scroll avoids the reschedule penalty.
export async function rescheduleOwnedTask(
  userId: string,
  taskId: string,
  newDueAt: string,
  useScroll: boolean,
  tx: Tx,
): Promise<{ id: string; dueAt: string; rescheduled: boolean; scrollUsed: boolean }> {
  const tasks = await tx`
    select id, status, due_at, original_due_at, rescheduled, scroll_used
    from tasks where id = ${taskId} and user_id = ${userId} for update
  `;
  const task = tasks[0];
  if (!task) throw notFound("Task not found");
  if (task.status !== "open") throw invalidArgument("Only an open task can be rescheduled");
  if (task.rescheduled === true || task.scroll_used === true) {
    throw invalidArgument("This task was already rescheduled");
  }

  let scrollUsed = false;
  if (useScroll) {
    const rows = await tx`select scrolls from player_state where user_id = ${userId} for update`;
    const scrolls = Number(rows[0]?.scrolls ?? 0);
    if (scrolls < 1) throw invalidArgument("You do not have a reschedule scroll");
    await tx`update player_state set scrolls = scrolls - 1 where user_id = ${userId}`;
    scrollUsed = true;
  }

  const original = task.original_due_at ?? task.due_at;
  await tx`
    update tasks set
      due_at = ${newDueAt},
      original_due_at = ${original},
      rescheduled = ${!scrollUsed},
      scroll_used = ${scrollUsed}
    where id = ${taskId} and user_id = ${userId}
  `;
  return { id: taskId, dueAt: newDueAt, rescheduled: !scrollUsed, scrollUsed };
}

export async function rescheduleTask(userId: string, body: unknown, sql: Sql = getSql()): Promise<{
  id: string;
  dueAt: string;
  rescheduled: boolean;
  scrollUsed: boolean;
}> {
  const input = inputSchema.parse(body);
  return await sql.begin((tx) =>
    rescheduleOwnedTask(userId, input.taskId, input.newDueAt, input.useScroll ?? false, tx as unknown as Tx)
  );
}
