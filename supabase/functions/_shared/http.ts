import { createClient } from "@supabase/supabase-js";
import { ZodError } from "zod";

import { AppError, unauthorized } from "./errors.ts";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export type AuthedUser = { id: string };

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function errorResponse(error: unknown): Response {
  if (error instanceof ZodError) {
    const message = error.issues.map((issue) => issue.message).join("; ") || "Invalid input";
    return json({ code: "invalid_argument", message }, 400);
  }
  if (error instanceof AppError) {
    return json({ code: error.code, message: error.message }, error.status);
  }
  console.error(error);
  return json({ code: "internal", message: "Something went wrong" }, 500);
}

/// User id comes from the JWT only. The request body is never consulted.
export async function userFromRequest(req: Request): Promise<AuthedUser> {
  const header = req.headers.get("Authorization");
  if (!header?.startsWith("Bearer ")) throw unauthorized();

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new AppError("internal", "Auth is not configured", 500);

  const client = createClient(url, key, {
    global: { headers: { Authorization: header } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw unauthorized();
  return { id: data.user.id };
}

export function handler(
  action: (req: Request, user: AuthedUser) => Promise<unknown> | unknown,
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
      const user = await userFromRequest(req);
      const result = await action(req, user);
      return json(result ?? { ok: true });
    } catch (error) {
      return errorResponse(error);
    }
  };
}
