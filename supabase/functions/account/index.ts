import { dispatch } from "../_shared/router.ts";
import { completeOnboardingStep } from "../_shared/complete_onboarding.ts";

export function hello(): { ok: true; message: string } {
  return { ok: true, message: "hello" };
}

export const handle = dispatch({
  hello: () => hello(),
  completeOnboardingStep: (body, user) => completeOnboardingStep(user.id, body),
});

if (import.meta.main) Deno.serve(handle);
