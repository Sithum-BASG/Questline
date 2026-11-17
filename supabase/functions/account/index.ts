import { completeOnboardingStep } from "../_shared/complete_onboarding.ts";
import { deleteAccount } from "../_shared/delete_account.ts";
import { demoStatus, setDemoMode } from "../_shared/demo_mode.ts";
import { dispatch } from "../_shared/router.ts";
import { setPause } from "../_shared/set_pause.ts";
import { setRestDay } from "../_shared/set_rest_day.ts";

export function hello(): { ok: true; message: string } {
  return { ok: true, message: "hello" };
}

export const handle = dispatch({
  hello: () => hello(),
  completeOnboardingStep: (body, user) => completeOnboardingStep(user.id, body),
  setRestDay: (body, user) => setRestDay(user.id, body),
  setPause: (body, user) => setPause(user.id, body),
  deleteAccount: (_body, user) => deleteAccount(user.id),
  demoStatus: (_body, user) => demoStatus(user.id),
  setDemoMode: (body, user) => setDemoMode(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
