import { assertEquals } from "jsr:@std/assert@1";

import { jsonObject } from "./json_value.ts";

Deno.test("jsonObject keeps objects", () => {
  assertEquals(jsonObject({ a: 1 }), { a: 1 });
});

Deno.test("jsonObject parses objects stored as JSON strings", () => {
  assertEquals(jsonObject('{"raid_mvps":2}'), { raid_mvps: 2 });
});

Deno.test("jsonObject rejects non-objects", () => {
  assertEquals(jsonObject(null), null);
  assertEquals(jsonObject("not json"), null);
  assertEquals(jsonObject("[1,2]"), null);
  assertEquals(jsonObject(3), null);
});
