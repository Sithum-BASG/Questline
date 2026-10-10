import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { completeOnboardingStep } from "./complete_onboarding.ts";
import type { Sql } from "./db.ts";

Deno.test("character step without a name never touches the database", async () => {
  let began = false;
  const sql = {
    begin() {
      began = true;
    },
  } as unknown as Sql;
  await assertRejects(() => completeOnboardingStep("user-1", { step: "character" }, sql));
  assertEquals(began, false);
});
