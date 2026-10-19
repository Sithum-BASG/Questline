export interface StreakMilestone {
  days: number;
  coins?: number;
  freeChest?: number;
  item?: string;
  title?: string;
}

export const defaultMilestones: StreakMilestone[] = [
  { days: 7, coins: 100 },
  { days: 14, coins: 150 },
  { days: 30, freeChest: 1 },
  { days: 60, item: "frame_unbroken" },
  { days: 100, title: "title_unbroken" },
];

export interface StreakState {
  count: number;
  best: number;
  lastCountedDay: string | null;
  shields: number;
  lastShieldDay: string | null;
  paidMilestones: number[];
}

export interface CloseDayOptions {
  rest: boolean;
  paused: boolean;
  minimumRawXp?: number;
  milestones?: StreakMilestone[];
}

function previousDay(day: string): string {
  const [year, month, date] = day.split("-").map(Number);
  const prev = new Date(Date.UTC(year, month - 1, date) - 86_400_000);
  const pad = (value: number) => String(value).padStart(2, "0");
  return `${prev.getUTCFullYear()}-${pad(prev.getUTCMonth() + 1)}-${pad(prev.getUTCDate())}`;
}

/// Close one game day. A rest day or a pause does nothing. A shield cannot cover two days in a row.
export function closeDay(
  state: StreakState,
  day: string,
  rawXp: number,
  options: CloseDayOptions,
): { state: StreakState; milestone: StreakMilestone | null } {
  const minimum = options.minimumRawXp ?? 40;
  const milestones = options.milestones ?? defaultMilestones;
  const next: StreakState = { ...state, paidMilestones: [...state.paidMilestones] };

  if (rawXp >= minimum) {
    next.count += 1;
    next.lastCountedDay = day;
    next.best = Math.max(next.best, next.count);
  } else if (options.rest || options.paused) {
    // The day neither counts nor breaks.
  } else if (next.shields > 0 && next.lastShieldDay !== previousDay(day)) {
    next.shields -= 1;
    next.lastShieldDay = day;
  } else {
    next.count = 0;
  }

  const earned = milestones.find((milestone) => milestone.days === next.count && !next.paidMilestones.includes(milestone.days));
  if (earned) next.paidMilestones.push(earned.days);
  return { state: next, milestone: earned ?? null };
}
