/** Friend codes and usernames. Day and level math live in `_shared/game`. */

export { levelFromXp, totalForLevel, xpForLevel, type LevelCurve } from "./game/rewards.ts";
export { nextRollover, weekId, zonedParts, zonedTime, type ZonedParts } from "./game/time.ts";

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
