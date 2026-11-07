import { cronHandler } from "../_shared/cron_auth.ts";
import { runWeeklyReset } from "../_shared/weekly_reset.ts";

export const handle = cronHandler(async (req) => {
  let body: unknown = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  return await runWeeklyReset(body);
});

if (import.meta.main) Deno.serve(handle);
