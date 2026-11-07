import { assertEquals, assertThrows } from "jsr:@std/assert@1";

import { assertCronSecret } from "./cron_auth.ts";
import { AppError } from "./errors.ts";

Deno.test("cron secret must match the expected value", () => {
  assertThrows(
    () => assertCronSecret(new Request("http://local", { headers: { "x-cron-secret": "nope" } }), "test-secret"),
    AppError,
    "Invalid cron secret",
  );
  assertCronSecret(
    new Request("http://local", { headers: { "x-cron-secret": "test-secret" } }),
    "test-secret",
  );
});

Deno.test("missing expected secret is an internal error", () => {
  try {
    assertCronSecret(new Request("http://local", { headers: { "x-cron-secret": "x" } }), null);
    throw new Error("expected throw");
  } catch (error) {
    assertEquals(error instanceof AppError, true);
    assertEquals((error as AppError).code, "internal");
  }
});
