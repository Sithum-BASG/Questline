import { z } from "zod";

export class AiOutputError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AiOutputError";
  }
}

const stats = ["intellect", "vitality", "craft", "charisma"] as const;

export interface TaskJudgement {
  stat: (typeof stats)[number];
  difficulty: number;
  estimated_minutes: number;
  too_big: boolean;
  reason: string;
}

export interface BossEstimate {
  boss_name: string;
  total_hours: number;
  per_person_hours: number;
  reason: string;
}

const judgementObject = z.object({
  stat: z.enum(stats),
  difficulty: z.number(),
  estimated_minutes: z.number(),
  too_big: z.boolean(),
  reason: z.string(),
}).strict();

const bossObject = z.object({
  boss_name: z.string(),
  total_hours: z.number(),
  per_person_hours: z.number(),
  reason: z.string(),
}).strict();

function roundHalfUp(value: number): number {
  return Math.sign(value) * Math.round(Math.abs(value));
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, roundHalfUp(value)));
}

/// At most 20 words. Extra words are dropped.
export function clampReason(reason: string): string {
  return reason.trim().split(/\s+/).filter((word) => word.length > 0).slice(0, 20).join(" ");
}

/// 2–4 words, otherwise the documented fallback name.
export function clampBossName(name: string): string {
  const words = name.trim().split(/\s+/).filter((word) => word.length > 0);
  if (words.length < 2 || words.length > 4) return "The Deadline Shade";
  return words.join(" ");
}

export function clampJudgement(value: unknown): TaskJudgement {
  const parsed = judgementObject.safeParse(value);
  if (!parsed.success) throw new AiOutputError("Judgement did not match the schema");
  return {
    stat: parsed.data.stat,
    difficulty: clamp(parsed.data.difficulty, 1, 5),
    estimated_minutes: clamp(parsed.data.estimated_minutes, 5, 180),
    too_big: parsed.data.too_big,
    reason: clampReason(parsed.data.reason),
  };
}

export function clampBossEstimate(value: unknown): BossEstimate {
  const parsed = bossObject.safeParse(value);
  if (!parsed.success) throw new AiOutputError("Boss estimate did not match the schema");
  return {
    boss_name: clampBossName(parsed.data.boss_name),
    total_hours: clamp(parsed.data.total_hours, 2, 40),
    per_person_hours: clamp(parsed.data.per_person_hours, 2, 40),
    reason: clampReason(parsed.data.reason),
  };
}
