import { roundHalfUp } from "./round.ts";

export interface XpRates {
  multipliers: number[];
  focusCapRatio: number;
  activityCapRatio: number;
  activityShare: number;
  tickShare: number;
  onTimeBonus: number;
  latePenaltyPerDay: number;
  lateFloor: number;
  reschedulePenalty: number;
  dailyFocusMinutes: number;
  gearStatCap: number;
  deepFocusMinutes: number;
  deepFocusBonus: number;
  potionMultiplier: number;
  potionMinMinutes: number;
  comebackMultiplier: number;
}

export const defaultXpRates: XpRates = {
  multipliers: [0.5, 0.75, 1, 1.3, 1.6],
  focusCapRatio: 1.5,
  activityCapRatio: 1,
  activityShare: 0.8,
  tickShare: 0.5,
  onTimeBonus: 0.1,
  latePenaltyPerDay: 0.1,
  lateFloor: 0.5,
  reschedulePenalty: 0.2,
  dailyFocusMinutes: 480,
  gearStatCap: 0.25,
  deepFocusMinutes: 45,
  deepFocusBonus: 0.1,
  potionMultiplier: 1.5,
  potionMinMinutes: 25,
  comebackMultiplier: 2,
};

export interface XpInput {
  difficulty: number;
  estimatedMinutes: number;
  verifiedMinutes: number;
  mode: "focus" | "activity" | "tick";
  dated?: boolean;
  onTime?: boolean;
  overdueDays?: number;
  rescheduled?: boolean;
  scrollUsed?: boolean;
  focusMinutesToday?: number;
  gearBoost?: number;
  deepFocus?: boolean;
  comebackArmed?: boolean;
  potion?: boolean;
  rates?: XpRates;
}

export interface XpResult {
  countedMinutes: number;
  raw: number;
  final: number;
}

export function sessionXp(input: XpInput): XpResult {
  const rates = input.rates ?? defaultXpRates;
  const multiplier = rates.multipliers[input.difficulty - 1] ?? 1;
  let minutes = input.estimatedMinutes;
  if (input.mode === "focus") {
    minutes = Math.min(input.verifiedMinutes, rates.focusCapRatio * input.estimatedMinutes);
  } else if (input.mode === "activity") {
    minutes = Math.min(input.verifiedMinutes, rates.activityCapRatio * input.estimatedMinutes);
  }
  if (input.mode !== "tick") {
    const room = Math.max(0, rates.dailyFocusMinutes - (input.focusMinutesToday ?? 0));
    minutes = Math.min(minutes, room);
  }

  const share = input.mode === "activity" ? rates.activityShare : input.mode === "tick" ? rates.tickShare : 1;
  let timing = 1;
  if (input.dated) {
    if (input.onTime) timing = 1 + rates.onTimeBonus;
    else timing = Math.max(rates.lateFloor, 1 - rates.latePenaltyPerDay * (input.overdueDays ?? 0));
  }
  const reschedule = input.rescheduled && !input.scrollUsed ? 1 - rates.reschedulePenalty : 1;
  const raw = roundHalfUp(minutes * multiplier * share * timing * reschedule);

  const gear = Math.min(rates.gearStatCap, Math.max(0, input.gearBoost ?? 0));
  const deep = input.deepFocus && input.mode === "focus" && minutes >= rates.deepFocusMinutes ? rates.deepFocusBonus : 0;
  const special = input.comebackArmed
    ? rates.comebackMultiplier
    : input.potion && minutes >= rates.potionMinMinutes
    ? rates.potionMultiplier
    : 1;
  const final = roundHalfUp(raw * (1 + gear + deep) * special);
  return { countedMinutes: minutes, raw, final };
}
