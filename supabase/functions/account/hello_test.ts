import { assertEquals } from "jsr:@std/assert@1";

import { hello, handle } from "./index.ts";
import { runAction } from "../_shared/router.ts";

Deno.test("hello returns a typed greeting", () => {
  assertEquals(hello(), { ok: true, message: "hello" });
});

Deno.test("unknown actions are invalid_argument", async () => {
  const req = new Request("http://localhost/functions/v1/account", {
    method: "POST",
    body: JSON.stringify({ action: "nope" }),
  });
  let code = "";
  try {
    await runAction({ hello: () => hello() }, req, { id: "user-1" });
  } catch (error) {
    code = (error as { code: string }).code;
  }
  assertEquals(code, "invalid_argument");
});

Deno.test("hello through the handler still requires a JWT", async () => {
  const res = await handle(new Request("http://localhost/functions/v1/account", {
    method: "POST",
    body: JSON.stringify({ action: "hello" }),
  }));
  assertEquals(res.status, 401);
});
