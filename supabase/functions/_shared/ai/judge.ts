import { clampBossEstimate, clampJudgement, type BossEstimate, type TaskJudgement } from "./clamp.ts";
import {
  bossEstimateSystem,
  bossEstimateUser,
  challengePrompt,
  challengeUser,
  taskJudgePrompt,
  taskJudgeUser,
  type BossEstimateInput,
  type ChallengeInput,
  type TaskJudgeInput,
} from "./prompts.ts";
import type { AiProvider } from "./provider.ts";
import { bossEstimateSchema, taskJudgementSchema } from "./schemas.ts";

export async function requestJudgement(provider: AiProvider, input: TaskJudgeInput): Promise<TaskJudgement> {
  const value = await provider.generateJson({
    system: taskJudgePrompt,
    user: taskJudgeUser(input),
    schemaName: "task_judgement",
    schema: taskJudgementSchema,
    validate: clampJudgement,
  });
  return value as TaskJudgement;
}

export async function requestChallenge(provider: AiProvider, input: ChallengeInput): Promise<TaskJudgement> {
  const value = await provider.generateJson({
    system: challengePrompt,
    user: challengeUser(input),
    schemaName: "task_judgement",
    schema: taskJudgementSchema,
    validate: clampJudgement,
  });
  return value as TaskJudgement;
}

export async function requestBossEstimate(provider: AiProvider, input: BossEstimateInput): Promise<BossEstimate> {
  const value = await provider.generateJson({
    system: bossEstimateSystem,
    user: bossEstimateUser(input),
    schemaName: "boss_estimate",
    schema: bossEstimateSchema,
    validate: clampBossEstimate,
  });
  return value as BossEstimate;
}
