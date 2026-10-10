import { assertEquals } from "jsr:@std/assert@1";
import { z } from "zod";

import { AppError } from "./errors.ts";
import { errorResponse, handler } from "./http.ts";

Deno.test("options skips auth and returns CORS", async () => {
  const serve = handler(() => ({ ok: true }));
  const res = await serve(new Request("http://localhost/functions/v1/account", { method: "OPTIONS" }));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), "*");
});

Deno.test("a request without a bearer token is unauthorized", async () => {
  const serve = handler(() => ({ ok: true }));
  const res = await serve(new Request("http://localhost/functions/v1/account", { method: "POST" }));
  assertEquals(res.status, 401);
  assertEquals(await res.json(), { code: "unauthorized", message: "Sign in required" });
});

Deno.test("zod failures become invalid_argument", async () => {
  let caught: unknown;
  try {
    z.object({ action: z.string() }).parse({});
  } catch (error) {
    caught = error;
  }
  const res = errorResponse(caught);
  assertEquals(res.status, 400);
  const body = await res.json();
  assertEquals(body.code, "invalid_argument");
});

Deno.test("app errors keep their code and status", async () => {
  const res = errorResponse(new AppError("not_found", "Not found", 404));
  assertEquals(res.status, 404);
  assertEquals(await res.json(), { code: "not_found", message: "Not found" });
});
