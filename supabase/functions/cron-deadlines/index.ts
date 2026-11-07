import { cronHandler } from "../_shared/cron_auth.ts";
import { runDeadlines } from "../_shared/deadlines.ts";

export const handle = cronHandler(async (req) => {
  let body: unknown = {};
  try {
    body = await req.json();
  } catch {
    body = {};
  }
  return await runDeadlines(body);
});

if (import.meta.main) Deno.serve(handle);
