import { AiExhaustedError, type AiProvider, type GenerateJsonRequest } from "./provider.ts";

export const groqChatUrl = "https://api.groq.com/openai/v1/chat/completions";

export interface BackupEndpoint {
  url: string;
  apiKey: string;
  model: string;
}

export interface GroqOptions {
  apiKey: string;
  models: string[];
  timeoutMs: number;
  fetch?: typeof fetch;
  backup?: BackupEndpoint;
}

/// `low` keeps gpt-oss output small. Qwen only accepts `none`.
export function reasoningEffort(model: string): "low" | "none" {
  return model.startsWith("qwen/") ? "none" : "low";
}

export function chatBody(model: string, req: GenerateJsonRequest): Record<string, unknown> {
  return {
    model,
    messages: [
      { role: "system", content: req.system },
      { role: "user", content: req.user },
    ],
    temperature: 0.2,
    reasoning_effort: reasoningEffort(model),
    response_format: {
      type: "json_schema",
      json_schema: { name: req.schemaName, strict: true, schema: req.schema },
    },
  };
}

function isRetryableStatus(status: number): boolean {
  return status === 429 || status >= 500;
}

async function readJsonContent(response: Response): Promise<unknown> {
  if (!response.ok) {
    if (isRetryableStatus(response.status)) throw new Error(`status ${response.status}`);
    throw new Error(`status ${response.status}`);
  }
  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string") throw new Error("missing content");
  return JSON.parse(content);
}

/// Rotates through Groq models, then the optional backup. Throws [AiExhaustedError].
export class GroqProvider implements AiProvider {
  readonly options: GroqOptions;
  lastModel = "";

  constructor(options: GroqOptions) {
    this.options = options;
  }

  async generateJson(req: GenerateJsonRequest): Promise<unknown> {
    const call = this.options.fetch ?? fetch;
    const attempts: { url: string; apiKey: string; model: string }[] = this.options.models.map((model) => ({
      url: groqChatUrl,
      apiKey: this.options.apiKey,
      model,
    }));
    const backup = this.options.backup;
    if (backup && backup.url && backup.apiKey && backup.model) attempts.push(backup);

    for (const attempt of attempts) {
      try {
        const response = await call(attempt.url, {
          method: "POST",
          headers: {
            authorization: `Bearer ${attempt.apiKey}`,
            "content-type": "application/json",
          },
          body: JSON.stringify(chatBody(attempt.model, req)),
          signal: AbortSignal.timeout(this.options.timeoutMs),
        });
        const value = await readJsonContent(response);
        this.lastModel = attempt.model;
        return value;
      } catch {
        // 429, 5xx, timeout and invalid JSON all move to the next model.
      }
    }
    throw new AiExhaustedError();
  }
}
