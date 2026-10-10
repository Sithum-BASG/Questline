import { z } from "zod";

import { invalidArgument } from "./errors.ts";
import { handler, type AuthedUser } from "./http.ts";

const envelope = z.object({ action: z.string() }).passthrough();

export type Action = (
  body: Record<string, unknown>,
  user: AuthedUser,
) => Promise<unknown> | unknown;

/// Routes `{ action }` to a function. The user id is the one from the JWT.
export async function runAction(
  actions: Record<string, Action>,
  req: Request,
  user: AuthedUser,
): Promise<unknown> {
  const body = envelope.parse(await req.json()) as Record<string, unknown>;
  const name = String(body.action);
  const action = actions[name];
  if (!action) throw invalidArgument(`Unknown action: ${name}`);
  return await action(body, user);
}

export function dispatch(actions: Record<string, Action>) {
  return handler((req, user) => runAction(actions, req, user));
}
