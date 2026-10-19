import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound } from "./errors.ts";

const inputSchema = z.object({
  taskId: z.string().uuid(),
  mode: z.enum(["focus", "activity"]),
  usePotion: z.boolean().optional(),
});

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface StartSessionResult {
  sessionId: string;
  startedAt: string;
  capMinutes: number;
}

function numberFrom(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// Opens one session for the caller's open task. The user id comes from the JWT.
export async function startDraft(
  userId: string,
  body: unknown,
  tx: Tx,
  config: GameConfig,
): Promise<StartSessionResult> {
  const input = inputSchema.parse(body);
  const tasks = await tx`
    select id, status, stat, difficulty, est_minutes
    from tasks where id = ${input.taskId} and user_id = ${userId} for update
  `;
  const task = tasks[0];
  if (!task) throw notFound("Task not found");
  if (task.status !== "open" || task.difficulty == null || task.est_minutes == null) {
    throw invalidArgument("Only a judged open task can be started");
  }
  if (input.mode === "activity" && task.stat !== "vitality" && task.stat !== "charisma") {
    throw invalidArgument("Activity mode is only for Vitality and Charisma");
  }

  const active = await tx`
    select id from sessions where user_id = ${userId} and status = 'active'
  `;
  if (active.length > 0) throw invalidArgument("Finish your current session first");

  const state = await tx`
    select potions, focus_minutes_today from player_state where user_id = ${userId} for update
  `;
  const potions = numberFrom(state[0]?.potions, 0);
  const focusToday = numberFrom(state[0]?.focus_minutes_today, 0);
  const estimate = numberFrom(task.est_minutes, 0);
  if (input.usePotion) {
    const minimum = numberFrom(config.potion_min_minutes, 25);
    if (estimate < minimum) throw invalidArgument(`A potion needs a task of at least ${minimum} minutes`);
    if (potions < 1) throw invalidArgument("You don't have a focus potion");
    // The potion stays in the count until the session spends it. Comeback can leave it armed (D3).
    await tx`update player_state set active_potion = true where user_id = ${userId}`;
  }

  const ratio = input.mode === "focus"
    ? numberFrom(config.xp_focus_cap_ratio, 1.5)
    : numberFrom(config.xp_activity_cap_ratio, 1);
  const daily = numberFrom(config.xp_daily_focus_minutes_limit, 480);
  const capMinutes = Math.max(0, Math.min(estimate * ratio, daily - focusToday));

  const inserted = await tx`
    insert into sessions (user_id, task_id, mode, potion)
    values (${userId}, ${input.taskId}, ${input.mode}, ${input.usePotion === true})
    returning id, started_at
  `;
  const row = inserted[0];
  return {
    sessionId: String(row.id),
    startedAt: new Date(String(row.started_at)).toISOString(),
    capMinutes,
  };
}

export async function startSession(userId: string, body: unknown, sql: Sql = getSql()): Promise<StartSessionResult> {
  const config = await loadConfig();
  return await sql.begin(async (tx) => startDraft(userId, body, tx as unknown as Tx, config));
}
