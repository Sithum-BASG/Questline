/// Strict JSON schemas from docs/05-BACKEND-SCHEMA.md §11.
/// Ranges are applied later by the clamp, not here.
export const taskJudgementSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    stat: { type: "string", enum: ["intellect", "vitality", "craft", "charisma"] },
    difficulty: { type: "integer" },
    estimated_minutes: { type: "integer" },
    too_big: { type: "boolean" },
    reason: { type: "string" },
  },
  required: ["stat", "difficulty", "estimated_minutes", "too_big", "reason"],
} as const;

export const bossEstimateSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    boss_name: { type: "string" },
    total_hours: { type: "number" },
    per_person_hours: { type: "number" },
    reason: { type: "string" },
  },
  required: ["boss_name", "total_hours", "per_person_hours", "reason"],
} as const;
