/// One interface for every AI call. Callers never see which provider answered.
export interface GenerateJsonRequest {
  system: string;
  user: string;
  schemaName: string;
  schema: object;
}

export interface AiProvider {
  generateJson(req: GenerateJsonRequest): Promise<unknown>;
}

/// Every model and the optional backup failed. The caller saves a provisional judgement.
export class AiExhaustedError extends Error {
  constructor() {
    super("Every AI model failed");
    this.name = "AiExhaustedError";
  }
}

export const defaultModelList = [
  "openai/gpt-oss-120b",
  "openai/gpt-oss-20b",
  "qwen/qwen3.8-27b",
];

export function parseModelList(raw: string | undefined): string[] {
  const models = (raw ?? "")
    .split(",")
    .map((model) => model.trim())
    .filter((model) => model.length > 0);
  return models.length > 0 ? models : defaultModelList;
}
