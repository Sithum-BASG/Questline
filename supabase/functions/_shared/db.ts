import postgres from "postgres";

import { AppError } from "./errors.ts";

export type Sql = ReturnType<typeof postgres>;

/// Direct Postgres connection. `prepare: false` is required on the pooler.
/// The client is created on first use so tests that never query do not connect.
let cached: Sql | undefined;

export function createSql(url?: string): Sql {
  const resolved = url ?? Deno.env.get("SUPABASE_DB_URL");
  if (!resolved) {
    throw new AppError("internal", "Database is not configured", 500);
  }
  return postgres(resolved, { prepare: false, max: 1 });
}

export function getSql(): Sql {
  if (!cached) cached = createSql();
  return cached;
}
