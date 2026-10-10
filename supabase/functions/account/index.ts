import { dispatch } from "../_shared/router.ts";

export function hello(): { ok: true; message: string } {
  return { ok: true, message: "hello" };
}

export const handle = dispatch({
  hello: () => hello(),
});

if (import.meta.main) Deno.serve(handle);
