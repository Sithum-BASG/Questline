import { assertEquals, assertRejects } from "jsr:@std/assert@1";

import { FakeProvider } from "./fake.ts";
import { chatBody, GroqProvider, reasoningEffort } from "./groq.ts";
import { AiExhaustedError } from "./provider.ts";
import { providerFromEnv } from "./index.ts";

const request = {
  system: "judge",
  user: "Read chapter 3",
  schemaName: "task_judgement",
  schema: { type: "object" },
};

function jsonResponse(content: unknown, status = 200): Response {
  return new Response(JSON.stringify({ choices: [{ message: { content: JSON.stringify(content) } }] }), {
    status,
  });
}

Deno.test("fake judge maps keywords and stays off the network", async () => {
  const provider = new FakeProvider();
  const read = await provider.generateJson({ ...request, user: "Read chapter 3" });
  assertEquals(read, {
    stat: "intellect",
    difficulty: 3,
    estimated_minutes: 30,
    too_big: false,
    reason: "Development judge (fake mode).",
  });
  assertEquals((await provider.generateJson({ ...request, user: "Go to the gym" }) as { stat: string }).stat, "vitality");
  assertEquals((await provider.generateJson({ ...request, user: "Code the parser" }) as { stat: string }).stat, "craft");
  assertEquals((await provider.generateJson({ ...request, user: "Email the group" }) as { stat: string }).stat, "charisma");
  const boss = await provider.generateJson({ ...request, schemaName: "boss_estimate" });
  assertEquals(boss, {
    boss_name: "The Practice Shade",
    total_hours: 6,
    per_person_hours: 6,
    reason: "Development judge (fake mode).",
  });
});

Deno.test("gpt-oss uses low reasoning and qwen uses none", () => {
  assertEquals(reasoningEffort("openai/gpt-oss-120b"), "low");
  assertEquals(reasoningEffort("qwen/qwen3.8-27b"), "none");
  const body = chatBody("openai/gpt-oss-20b", request);
  assertEquals(body.temperature, 0.2);
  assertEquals(body.reasoning_effort, "low");
  assertEquals("logprobs" in body, false);
  assertEquals("logit_bias" in body, false);
  assertEquals("n" in body, false);
  const messages = body.messages as { role: string }[];
  assertEquals(messages.every((message) => !("name" in message)), true);
  const format = body.response_format as { json_schema: { strict: boolean; name: string } };
  assertEquals(format.json_schema.strict, true);
  assertEquals(format.json_schema.name, "task_judgement");
});

Deno.test("a 429 moves to the next model", async () => {
  const seen: string[] = [];
  const provider = new GroqProvider({
    apiKey: "test-key",
    models: ["openai/gpt-oss-120b", "openai/gpt-oss-20b"],
    timeoutMs: 50,
    fetch: (_url, init) => {
      const body = JSON.parse(String(init?.body));
      seen.push(body.model);
      if (body.model === "openai/gpt-oss-120b") return Promise.resolve(new Response("busy", { status: 429 }));
      return Promise.resolve(jsonResponse({ stat: "intellect" }));
    },
  });
  const value = await provider.generateJson(request);
  assertEquals(value, { stat: "intellect" });
  assertEquals(seen, ["openai/gpt-oss-120b", "openai/gpt-oss-20b"]);
  assertEquals(provider.lastModel, "openai/gpt-oss-20b");
});

Deno.test("invalid JSON and a timeout both move on", async () => {
  let calls = 0;
  const provider = new GroqProvider({
    apiKey: "test-key",
    models: ["openai/gpt-oss-120b", "openai/gpt-oss-20b", "qwen/qwen3.8-27b"],
    timeoutMs: 20,
    fetch: (_url, init) => {
      calls += 1;
      if (calls === 1) {
        return Promise.resolve(new Response(JSON.stringify({
          choices: [{ message: { content: "nope" } }],
        })));
      }
      if (calls === 2) {
        return new Promise((_resolve, reject) => {
          init?.signal?.addEventListener("abort", () => reject(new DOMException("timed out", "TimeoutError")));
        });
      }
      const body = JSON.parse(String(init?.body));
      assertEquals(body.reasoning_effort, "none");
      return Promise.resolve(jsonResponse({ ok: true }));
    },
  });
  const value = await provider.generateJson(request);
  assertEquals(value, { ok: true });
  assertEquals(calls, 3);
});

Deno.test("backup is used only after every Groq model fails", async () => {
  const urls: string[] = [];
  const provider = new GroqProvider({
    apiKey: "groq-key",
    models: ["openai/gpt-oss-120b"],
    timeoutMs: 50,
    backup: { url: "https://backup.example/v1/chat/completions", apiKey: "backup-key", model: "backup-model" },
    fetch: (url, init) => {
      urls.push(String(url));
      const body = JSON.parse(String(init?.body));
      const header = new Headers(init?.headers).get("authorization");
      if (body.model === "openai/gpt-oss-120b") {
        assertEquals(header, "Bearer groq-key");
        return Promise.resolve(new Response("down", { status: 503 }));
      }
      assertEquals(body.model, "backup-model");
      assertEquals(header, "Bearer backup-key");
      return Promise.resolve(jsonResponse({ ok: true }));
    },
  });
  assertEquals(await provider.generateJson(request), { ok: true });
  assertEquals(urls[1], "https://backup.example/v1/chat/completions");
  assertEquals(provider.lastModel, "backup-model");
});

Deno.test("an empty backup is skipped and exhaustion is reported", async () => {
  const provider = new GroqProvider({
    apiKey: "groq-key",
    models: ["openai/gpt-oss-120b"],
    timeoutMs: 50,
    fetch: () => Promise.resolve(new Response("down", { status: 500 })),
  });
  await assertRejects(() => provider.generateJson(request), AiExhaustedError);
});

Deno.test("providerFromEnv selects fake without a key", async () => {
  const provider = providerFromEnv({ AI_PROVIDER: "fake" });
  const value = await provider.generateJson(request) as { reason: string };
  assertEquals(value.reason, "Development judge (fake mode).");
});
