import type { AiProvider, GenerateJsonRequest } from "./provider.ts";

const reason = "Development judge (fake mode).";

/// Keyword stat from TRD §7.3. First matching group wins.
export function fakeStat(text: string): string {
  const lower = text.toLowerCase();
  if (/\b(gym|run|walk)\b/.test(lower)) return "vitality";
  if (/\b(code|design|build)\b/.test(lower)) return "craft";
  if (/\b(meet|call|email)\b/.test(lower)) return "charisma";
  return "intellect";
}

export function fakeJudgement(text: string): Record<string, unknown> {
  return {
    stat: fakeStat(text),
    difficulty: 3,
    estimated_minutes: 30,
    too_big: false,
    reason,
  };
}

export function fakeBossEstimate(): Record<string, unknown> {
  return {
    boss_name: "The Practice Shade",
    total_hours: 6,
    per_person_hours: 6,
    reason,
  };
}

/// Instant deterministic answers. No network.
export class FakeProvider implements AiProvider {
  generateJson(req: GenerateJsonRequest): Promise<unknown> {
    const value = req.schemaName === "boss_estimate" ? fakeBossEstimate() : fakeJudgement(req.user);
    return Promise.resolve(req.validate ? req.validate(value) : value);
  }
}
