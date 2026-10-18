import { z } from "zod";

import { loadConfig, type GameConfig } from "./config.ts";
import { getSql, type Sql } from "./db.ts";
import { invalidArgument, notFound, AppError } from "./errors.ts";
import { AiExhaustedError, getProvider, type AiProvider } from "./ai/index.ts";
import { fakeStat } from "./ai/fake.ts";
import { requestChallenge, requestJudgement } from "./ai/judge.ts";

const inputSchema = z.object({
  taskId: z.string().uuid(),
});

const challengeSchema = z.object({
  taskId: z.string().uuid(),
  context: z.string().trim().min(1).max(280),
});

export interface JudgeResult {
  stat: string;
  difficulty: number;
  estimatedMinutes: number;
  tooBig: boolean;
  reason: string;
  provisional: boolean;
  challenged: boolean;
  xpPreview: number;
}

interface TaskRow {
  id: string;
  title: string;
  notes: string | null;
  due_at: string | null;
  boss_id: string | null;
  status: string;
  stat: string | null;
  difficulty: number | null;
  est_minutes: number | null;
  too_big: boolean | null;
  reason: string | null;
  provisional: boolean;
  challenged: boolean;
  judged_at: string | null;
}

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

const provisionalReason = "Saved as provisional. It will be judged again soon.";
const restingReason = "AI judge resting until tomorrow; saved as provisional";

function numberFrom(value: unknown, fallback: number): number {
  const parsed = typeof value === "number" ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/// On-time focus preview: minutes × difficulty multiplier, plus 10% when the task has a due date.
export function focusXpPreview(minutes: number, difficulty: number, dated: boolean, multipliers: number[]): number {
  const mult = multipliers[difficulty - 1] ?? 1;
  const raw = minutes * mult * (dated ? 1.1 : 1);
  return Math.round(raw);
}

function dueInDays(dueAt: string | null, now: Date): number | null {
  if (!dueAt) return null;
  return Math.round((new Date(dueAt).getTime() - now.getTime()) / 86_400_000);
}

function storedResult(task: TaskRow, multipliers: number[]): JudgeResult {
  const difficulty = task.difficulty ?? 3;
  const minutes = task.est_minutes ?? 30;
  return {
    stat: task.stat ?? "intellect",
    difficulty,
    estimatedMinutes: minutes,
    tooBig: task.too_big ?? false,
    reason: task.reason ?? "",
    provisional: task.provisional,
    challenged: task.challenged,
    xpPreview: focusXpPreview(minutes, difficulty, task.due_at != null, multipliers),
  };
}

async function writeJudgement(
  tx: Tx,
  userId: string,
  taskId: string,
  result: JudgeResult,
  countCall: boolean,
  now: Date,
): Promise<void> {
  await tx`
    update tasks set
      stat = ${result.stat},
      difficulty = ${result.difficulty},
      est_minutes = ${result.estimatedMinutes},
      too_big = ${result.tooBig},
      reason = ${result.reason},
      provisional = ${result.provisional},
      judged_at = ${now.toISOString()}
    where id = ${taskId} and user_id = ${userId}
  `;
  if (countCall) {
    await tx`
      update player_state set ai_calls_today = ai_calls_today + 1
      where user_id = ${userId}
    `;
  }
}

export async function judgeDraft(
  userId: string,
  taskId: string,
  tx: Tx,
  provider: AiProvider,
  config: GameConfig,
  now = new Date(),
): Promise<JudgeResult> {
  const tasks = await tx`
    select id, title, notes, due_at, boss_id, status, stat, difficulty, est_minutes,
           too_big, reason, provisional, challenged, judged_at
    from tasks where id = ${taskId} and user_id = ${userId} for update
  `;
  const task = tasks[0] as unknown as TaskRow | undefined;
  if (!task) throw notFound("Task not found");
  if (task.status !== "draft") throw invalidArgument("Only a draft task can be judged");

  const multipliers = config.xp_difficulty_multipliers as number[];
  if (task.judged_at && !task.provisional) return storedResult(task, multipliers);

  const limit = numberFrom(config.ai_daily_limit, 50);
  const calls = await tx`select ai_calls_today from player_state where user_id = ${userId} for update`;
  const used = numberFrom(calls[0]?.ai_calls_today, 0);
  if (used >= limit) {
    const result: JudgeResult = {
      stat: fakeStat(`${task.title} ${task.notes ?? ""}`),
      difficulty: 3,
      estimatedMinutes: 30,
      tooBig: false,
      reason: restingReason,
      provisional: true,
      challenged: false,
      xpPreview: focusXpPreview(30, 3, task.due_at != null, multipliers),
    };
    await writeJudgement(tx, userId, taskId, result, false, now);
    return result;
  }

  const settings = await tx`select study_context from user_settings where user_id = ${userId}`;
  let parent: string | null = null;
  if (task.boss_id) {
    const bosses = await tx`
      select title from bosses where id = ${task.boss_id} and user_id = ${userId}
    `;
    const title = bosses[0]?.title;
    parent = typeof title === "string" ? title : null;
  }

  let result: JudgeResult;
  try {
    const judgement = await requestJudgement(provider, {
      taskTitle: task.title,
      taskNotes: task.notes,
      parent,
      dueInDays: dueInDays(task.due_at, now),
      studentContext: (settings[0]?.study_context as string | null) ?? null,
      calibrationRatio: null,
    });
    result = {
      stat: judgement.stat,
      difficulty: judgement.difficulty,
      estimatedMinutes: judgement.estimated_minutes,
      tooBig: judgement.too_big,
      reason: judgement.reason,
      provisional: false,
      challenged: false,
      xpPreview: focusXpPreview(judgement.estimated_minutes, judgement.difficulty, task.due_at != null, multipliers),
    };
  } catch (error) {
    if (!(error instanceof AiExhaustedError)) throw error;
    result = {
      stat: fakeStat(`${task.title} ${task.notes ?? ""}`),
      difficulty: 3,
      estimatedMinutes: 30,
      tooBig: false,
      reason: provisionalReason,
      provisional: true,
      challenged: false,
      xpPreview: focusXpPreview(30, 3, task.due_at != null, multipliers),
    };
  }

  await writeJudgement(tx, userId, taskId, result, true, now);
  return result;
}

/// Judges the caller's draft task. The user id comes from the JWT, never the body.
export async function judgeTask(userId: string, body: unknown, sql: Sql = getSql()): Promise<JudgeResult> {
  const { taskId } = inputSchema.parse(body);
  const config = await loadConfig();
  const provider = getProvider({ timeoutMs: numberFrom(config.ai_timeout_ms, 10_000) });
  return await sql.begin(async (tx) => judgeDraft(userId, taskId, tx as unknown as Tx, provider, config));
}

/// One challenge per open task. The new rating is final. A failed call does not use up the challenge.
export async function challengeDraft(
  userId: string,
  taskId: string,
  context: string,
  tx: Tx,
  provider: AiProvider,
  config: GameConfig,
  now = new Date(),
): Promise<JudgeResult> {
  const tasks = await tx`
    select id, title, notes, due_at, boss_id, status, stat, difficulty, est_minutes,
           too_big, reason, provisional, challenged, judged_at
    from tasks where id = ${taskId} and user_id = ${userId} for update
  `;
  const task = tasks[0] as unknown as TaskRow | undefined;
  if (!task) throw notFound("Task not found");
  if (task.status !== "open" || task.difficulty == null) {
    throw invalidArgument("Only a judged open task can be challenged");
  }
  if (task.challenged) throw invalidArgument("This task was already challenged");
  if (task.provisional) throw invalidArgument("Wait for the judgement before challenging");

  const limit = numberFrom(config.ai_daily_limit, 50);
  const calls = await tx`select ai_calls_today from player_state where user_id = ${userId} for update`;
  const used = numberFrom(calls[0]?.ai_calls_today, 0);
  if (used >= limit) {
    throw new AppError("unavailable", restingReason, 503);
  }

  const settings = await tx`select study_context from user_settings where user_id = ${userId}`;
  let parent: string | null = null;
  if (task.boss_id) {
    const bosses = await tx`select title from bosses where id = ${task.boss_id} and user_id = ${userId}`;
    const title = bosses[0]?.title;
    parent = typeof title === "string" ? title : null;
  }

  let judgement;
  try {
    judgement = await requestChallenge(provider, {
      taskTitle: task.title,
      taskNotes: task.notes,
      parent,
      dueInDays: dueInDays(task.due_at, now),
      studentContext: (settings[0]?.study_context as string | null) ?? null,
      calibrationRatio: null,
      previousJudgement: {
        stat: task.stat,
        difficulty: task.difficulty,
        estimated_minutes: task.est_minutes,
        reason: task.reason,
      },
      challengeContext: context,
    });
  } catch (error) {
    if (error instanceof AiExhaustedError) {
      await tx`update player_state set ai_calls_today = ai_calls_today + 1 where user_id = ${userId}`;
      throw new AppError("unavailable", "The judge is unavailable. Try the challenge again in a moment.", 503);
    }
    throw error;
  }

  const multipliers = config.xp_difficulty_multipliers as number[];
  const result: JudgeResult = {
    stat: judgement.stat,
    difficulty: judgement.difficulty,
    estimatedMinutes: judgement.estimated_minutes,
    tooBig: judgement.too_big,
    reason: judgement.reason,
    provisional: false,
    challenged: true,
    xpPreview: focusXpPreview(judgement.estimated_minutes, judgement.difficulty, task.due_at != null, multipliers),
  };
  await tx`
    update tasks set
      stat = ${result.stat},
      difficulty = ${result.difficulty},
      est_minutes = ${result.estimatedMinutes},
      too_big = ${result.tooBig},
      reason = ${result.reason},
      provisional = false,
      challenged = true,
      judged_at = ${now.toISOString()}
    where id = ${taskId} and user_id = ${userId}
  `;
  await tx`update player_state set ai_calls_today = ai_calls_today + 1 where user_id = ${userId}`;
  return result;
}

export async function challengeTask(userId: string, body: unknown, sql: Sql = getSql()): Promise<JudgeResult> {
  const { taskId, context } = challengeSchema.parse(body);
  const config = await loadConfig();
  const provider = getProvider({ timeoutMs: numberFrom(config.ai_timeout_ms, 10_000) });
  return await sql.begin(async (tx) =>
    challengeDraft(userId, taskId, context, tx as unknown as Tx, provider, config)
  );
}
