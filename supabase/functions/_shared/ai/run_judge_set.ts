import { GroqProvider } from "./groq.ts";
import { requestJudgement } from "./judge.ts";
import { getProvider } from "./index.ts";

interface JudgeCase {
  id: string;
  kind: string;
  statHint: string;
  title: string;
  notes: string;
  parent: string | null;
  dueInDays: number | null;
  studentContext: string | null;
}

const setUrl = new URL("./judge-set.json", import.meta.url);
const outUrl = new URL("./judge-set-results.md", import.meta.url);
const cases = JSON.parse(await Deno.readTextFile(setUrl)) as JudgeCase[];
const provider = getProvider();
const mode = Deno.env.get("AI_PROVIDER") ?? "groq";

const lines = [
  "# Judge set results",
  "",
  `Provider: ${mode}`,
  "",
  "| Id | Kind | Stat | Difficulty | Minutes | Too big | Model | Reason |",
  "|---|---|---|---|---|---|---|---|",
];

for (let index = 0; index < cases.length; index += 1) {
  const item = cases[index];
  if (index > 0) await new Promise((resolve) => setTimeout(resolve, 2000));
  const judgement = await requestJudgement(provider, {
    taskTitle: item.title,
    taskNotes: item.notes,
    parent: item.parent,
    dueInDays: item.dueInDays,
    studentContext: item.studentContext,
  });
  const model = provider instanceof GroqProvider ? provider.lastModel : "fake";
  const reason = judgement.reason.replaceAll("|", "/");
  lines.push(
    `| ${item.id} | ${item.kind} | ${judgement.stat} | ${judgement.difficulty} | ${judgement.estimated_minutes} | ${judgement.too_big} | ${model} | ${reason} |`,
  );
  console.log(`${item.id}: ${judgement.stat} d${judgement.difficulty} ${judgement.estimated_minutes}m (${model})`);
}

await Deno.writeTextFile(outUrl, lines.join("\n") + "\n");
console.log(`Wrote ${outUrl.pathname}`);
