import { cronHandler } from "../_shared/cron_auth.ts";
import { runRollover } from "../_shared/rollover.ts";

export const handle = cronHandler(async (req) => {
  let body: unknown = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  return await runRollover(body);
});

if (import.meta.main) Deno.serve(handle);
