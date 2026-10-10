/** Leaderboard day boundary and week id. Monday 04:00 in the leaderboard timezone. */

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] as const;

export type ZonedParts = {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  weekday: number;
};

export function zonedParts(date: Date, timeZone: string): ZonedParts {
  const fmt = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    weekday: "short",
  });
  const bag: Record<string, string> = {};
  for (const part of fmt.formatToParts(date)) bag[part.type] = part.value;
  const hour = Number(bag.hour);
  return {
    year: Number(bag.year),
    month: Number(bag.month),
    day: Number(bag.day),
    hour: hour === 24 ? 0 : hour,
    minute: Number(bag.minute),
    weekday: WEEKDAYS.indexOf(bag.weekday as typeof WEEKDAYS[number]),
  };
}

/** UTC instant of a civil date and hour in [timeZone]. */
export function zonedTime(year: number, month: number, day: number, hour: number, timeZone: string): Date {
  let utc = Date.UTC(year, month - 1, day, hour, 0, 0);
  for (let i = 0; i < 3; i++) {
    const got = zonedParts(new Date(utc), timeZone);
    const gotAsUtc = Date.UTC(got.year, got.month - 1, got.day, got.hour, got.minute);
    const want = Date.UTC(year, month - 1, day, hour, 0);
    utc += want - gotAsUtc;
  }
  return new Date(utc);
}

/** Next 04:00 in [timeZone], or today's 04:00 if it is still ahead. */
export function nextRollover(now: Date, timeZone: string, hour = 4): Date {
  const parts = zonedParts(now, timeZone);
  const today = zonedTime(parts.year, parts.month, parts.day, hour, timeZone);
  if (now.getTime() < today.getTime()) return today;
  const tomorrow = new Date(Date.UTC(parts.year, parts.month - 1, parts.day) + 86_400_000);
  return zonedTime(tomorrow.getUTCFullYear(), tomorrow.getUTCMonth() + 1, tomorrow.getUTCDate(), hour, timeZone);
}

function isoWeek(year: number, month: number, day: number): { year: number; week: number } {
  const date = new Date(Date.UTC(year, month - 1, day));
  const weekday = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - weekday);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((date.getTime() - yearStart.getTime()) / 86_400_000 + 1) / 7);
  return { year: date.getUTCFullYear(), week };
}

/** `2026-W41`. Before Monday 04:00 the previous week is still open. */
export function weekId(now: Date, timeZone: string, hour = 4): string {
  const parts = zonedParts(now, timeZone);
  let { year, month, day } = parts;
  if (parts.weekday === 1 && parts.hour < hour) {
    const prev = new Date(Date.UTC(year, month - 1, day) - 86_400_000);
    year = prev.getUTCFullYear();
    month = prev.getUTCMonth() + 1;
    day = prev.getUTCDate();
  }
  const iso = isoWeek(year, month, day);
  return `${iso.year}-W${String(iso.week).padStart(2, "0")}`;
}

const FRIEND_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function friendCode(random: () => number): string {
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += FRIEND_ALPHABET[Math.floor(random() * FRIEND_ALPHABET.length)];
  }
  return code;
}

/** Display name plus 4 digits, matching `^[a-z0-9_]{3,20}$`. */
export function usernameFromDisplayName(displayName: string, digits: string): string {
  const slug = displayName.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "");
  const base = (slug.length > 0 ? slug : "player").slice(0, 15);
  const suffix = digits.replace(/\D/g, "").slice(0, 4).padStart(4, "0");
  return `${base}_${suffix}`.slice(0, 20);
}

export type LevelCurve = { base: number; coef: number; exp: number; roundTo: number; maxLevel: number };

export function xpForLevel(level: number, curve: LevelCurve): number {
  const raw = curve.base + curve.coef * (level - 2) ** curve.exp;
  const step = curve.roundTo;
  return Math.round(raw / step) * step;
}

export function totalForLevel(level: number, curve: LevelCurve): number {
  let total = 0;
  for (let k = 2; k <= level; k++) total += xpForLevel(k, curve);
  return total;
}

export function levelFromXp(xp: number, curve: LevelCurve): number {
  let level = 1;
  for (let next = 2; next <= curve.maxLevel; next++) {
    if (totalForLevel(next, curve) <= xp) level = next;
    else break;
  }
  return level;
}
