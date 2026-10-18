import { FakeProvider } from "./fake.ts";
import { GroqProvider, type BackupEndpoint } from "./groq.ts";
import { parseModelList, type AiProvider } from "./provider.ts";

export type { AiProvider, GenerateJsonRequest } from "./provider.ts";
export { AiExhaustedError, defaultModelList, parseModelList } from "./provider.ts";
export { FakeProvider, fakeBossEstimate, fakeJudgement, fakeStat } from "./fake.ts";
export { GroqProvider, chatBody, groqChatUrl, reasoningEffort } from "./groq.ts";
export type { BackupEndpoint, GroqOptions } from "./groq.ts";

export interface ProviderEnv {
  AI_PROVIDER?: string;
  GROQ_API_KEY?: string;
  GROQ_MODELS?: string;
  AI_BACKUP_URL?: string;
  AI_BACKUP_KEY?: string;
  AI_BACKUP_MODEL?: string;
}

/// `groq` is the default. Tests and non-AI work pass `AI_PROVIDER=fake`.
export function providerFromEnv(
  env: ProviderEnv,
  options: { timeoutMs?: number; fetch?: typeof fetch } = {},
): AiProvider {
  if ((env.AI_PROVIDER ?? "groq") === "fake") return new FakeProvider();
  const backup: BackupEndpoint | undefined =
    env.AI_BACKUP_URL && env.AI_BACKUP_KEY && env.AI_BACKUP_MODEL
      ? { url: env.AI_BACKUP_URL, apiKey: env.AI_BACKUP_KEY, model: env.AI_BACKUP_MODEL }
      : undefined;
  return new GroqProvider({
    apiKey: env.GROQ_API_KEY ?? "",
    models: parseModelList(env.GROQ_MODELS),
    timeoutMs: options.timeoutMs ?? 10_000,
    fetch: options.fetch,
    backup,
  });
}

export function getProvider(options: { timeoutMs?: number; fetch?: typeof fetch } = {}): AiProvider {
  return providerFromEnv(
    {
      AI_PROVIDER: Deno.env.get("AI_PROVIDER") ?? undefined,
      GROQ_API_KEY: Deno.env.get("GROQ_API_KEY") ?? undefined,
      GROQ_MODELS: Deno.env.get("GROQ_MODELS") ?? undefined,
      AI_BACKUP_URL: Deno.env.get("AI_BACKUP_URL") ?? undefined,
      AI_BACKUP_KEY: Deno.env.get("AI_BACKUP_KEY") ?? undefined,
      AI_BACKUP_MODEL: Deno.env.get("AI_BACKUP_MODEL") ?? undefined,
    },
    options,
  );
}
