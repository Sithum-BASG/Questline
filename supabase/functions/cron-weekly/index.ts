import { dispatch } from "../_shared/router.ts";

export const handle = dispatch({});

if (import.meta.main) Deno.serve(handle);
