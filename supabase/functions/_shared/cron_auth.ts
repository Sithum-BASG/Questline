import { AppError } from "./errors.ts";
import { corsHeaders, errorResponse, json } from "./http.ts";

/// Cron Edge Functions use x-cron-secret instead of a user JWT.
export function assertCronSecret(req: Request, expected?: string | null): void {
  const secret = expected === undefined ? Deno.env.get("CRON_SECRET") : expected;
  if (!secret) throw new AppError("internal", "Cron secret is not configured", 500);
  const got = req.headers.get("x-cron-secret");
  if (got !== secret) throw new AppError("unauthorized", "Invalid cron secret", 401);
}

export function cronHandler(
  action: (req: Request) => Promise<unknown> | unknown,
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
      assertCronSecret(req);
      const result = await action(req);
      return json(result ?? { ok: true });
    } catch (error) {
      return errorResponse(error);
    }
  };
}
