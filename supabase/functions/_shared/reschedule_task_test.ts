import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import type { Sql } from "./db.ts";
import { AppError } from "./errors.ts";
import { rescheduleOwnedTask, rescheduleTask } from "./reschedule_task.ts";

const userId = "11111111-1111-1111-1111-111111111111";
const taskId = "22222222-2222-2222-2222-222222222222";

function scripted(task: Record<string, unknown> | null, scrolls = 0) {
  const queries: { text: string; values: unknown[] }[] = [];
  const tx = (strings: TemplateStringsArray, ...values: unknown[]) => {
    const text = strings.join(" ");
    queries.push({ text, values });
    if (text.includes("from tasks")) return Promise.resolve(task ? [task] : []);
    if (text.includes("select scrolls")) return Promise.resolve([{ scrolls }]);
    return Promise.resolve([]);
  };
  return { tx, queries };
}

const open = {
  id: taskId,
  status: "open",
  due_at: "2026-10-12T00:00:00.000Z",
  original_due_at: null,
  rescheduled: false,
  scroll_used: false,
};

Deno.test("rescheduling without a scroll sets the penalty flag", async () => {
  const { tx, queries } = scripted(open);
  const result = await rescheduleOwnedTask(userId, taskId, "2026-10-20T00:00:00.000Z", false, tx);
  assertEquals(result.rescheduled, true);
  assertEquals(result.scrollUsed, false);
  assertEquals(queries.every((query) => query.values.includes(userId)), true);
  const update = queries.find((query) => query.text.includes("update tasks"));
  assertEquals(update?.values.includes(true), true);
});

Deno.test("a scroll clears the penalty and is spent", async () => {
  const { tx, queries } = scripted(open, 1);
  const result = await rescheduleOwnedTask(userId, taskId, "2026-10-20T00:00:00.000Z", true, tx);
  assertEquals(result.rescheduled, false);
  assertEquals(result.scrollUsed, true);
  assertEquals(queries.some((query) => query.text.includes("scrolls = scrolls - 1")), true);
});

Deno.test("a missing scroll or a second reschedule is rejected", async () => {
  const none = scripted(open, 0);
  await assertRejects(
    () => rescheduleOwnedTask(userId, taskId, "2026-10-20T00:00:00.000Z", true, none.tx),
    AppError,
    "do not have a reschedule scroll",
  );
  const again = scripted({ ...open, rescheduled: true });
  await assertRejects(
    () => rescheduleOwnedTask(userId, taskId, "2026-10-20T00:00:00.000Z", false, again.tx),
    AppError,
    "already rescheduled",
  );
});

Deno.test("a bad date never starts a transaction", async () => {
  let began = false;
  const sql = { begin() {
    began = true;
  } } as unknown as Sql;
  await assertRejects(() => rescheduleTask(userId, { taskId, newDueAt: "tomorrow" }, sql));
  assertEquals(began, false);
});
