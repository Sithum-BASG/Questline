/// A jsonb object read back from Postgres. Rows written before the `::text::jsonb` fix hold the
/// object as a JSON string, so a string is parsed; anything that is not an object gives null.
export function jsonObject<T = Record<string, unknown>>(value: unknown): T | null {
  let parsed = value;
  if (typeof parsed === "string") {
    try {
      parsed = JSON.parse(parsed);
    } catch {
      return null;
    }
  }
  return parsed !== null && typeof parsed === "object" && !Array.isArray(parsed) ? parsed as T : null;
}
