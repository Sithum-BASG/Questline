import { assertEquals } from "jsr:@std/assert@1";

import set from "./judge-set.json" with { type: "json" };

Deno.test("the judge set covers stats, difficulty, vague tasks and three injections", () => {
  assertEquals(set.length >= 30, true);
  const kinds = new Set(set.map((item) => item.kind));
  assertEquals(kinds.has("easy"), true);
  assertEquals(kinds.has("hard"), true);
  assertEquals(kinds.has("vague"), true);
  assertEquals(set.filter((item) => item.kind === "injection").length, 3);
  for (const stat of ["intellect", "vitality", "craft", "charisma"]) {
    assertEquals(set.some((item) => item.statHint === stat), true);
  }
  const forensics = set.find((item) => item.id === "forensics-intro");
  assertEquals(forensics?.title, "Write introduction for Computer Forensics report (800 words)");
  assertEquals(set.some((item) => "email" in item || "userId" in item), false);
});
