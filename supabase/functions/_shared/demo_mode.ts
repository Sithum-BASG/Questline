import { z } from "zod";

import { getSql, type Sql } from "./db.ts";
import { invalidArgument } from "./errors.ts";

const setSchema = z.object({ enabled: z.boolean() });

type Tx = (strings: TemplateStringsArray, ...values: unknown[]) => Promise<Record<string, unknown>[]>;

export interface DemoStatus {
  /// Whether this account is on the demo allow-list; the switch is only shown when it is.
  allowed: boolean;
  enabled: boolean;
}

/// Reads the caller's demo status. The user id comes from the JWT.
export async function demoStatusDraft(userId: string, tx: Tx): Promise<DemoStatus> {
  const allowed = await tx`select user_id from demo_allowlist where user_id = ${userId}`;
  const settings = await tx`select demo_mode from user_settings where user_id = ${userId}`;
  return { allowed: allowed.length > 0, enabled: allowed.length > 0 && settings[0]?.demo_mode === true };
}

/// Turns demo mode on or off for an allow-listed caller. Sessions started afterwards use it.
export async function setDemoModeDraft(userId: string, body: unknown, tx: Tx): Promise<DemoStatus> {
  const input = setSchema.parse(body);
  const allowed = await tx`select user_id from demo_allowlist where user_id = ${userId}`;
  if (allowed.length === 0) throw invalidArgument("Demo mode is not available for this account");
  await tx`update user_settings set demo_mode = ${input.enabled} where user_id = ${userId}`;
  return { allowed: true, enabled: input.enabled };
}

export async function demoStatus(userId: string, sql: Sql = getSql()): Promise<DemoStatus> {
  return await sql.begin(async (tx) => demoStatusDraft(userId, tx as unknown as Tx));
}

export async function setDemoMode(userId: string, body: unknown, sql: Sql = getSql()): Promise<DemoStatus> {
  return await sql.begin(async (tx) => setDemoModeDraft(userId, body, tx as unknown as Tx));
}
