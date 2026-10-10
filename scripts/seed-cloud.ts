// Loads supabase/seed.sql into the database named by SUPABASE_DB_URL.
// The URL is a secret: set it in the shell, and never print it.
// PowerShell: $env:SUPABASE_DB_URL = '<connection string>'
// deno run --allow-env --allow-read --allow-net scripts/seed-cloud.ts

import postgres from "npm:postgres@3.4.5";

const url = Deno.env.get("SUPABASE_DB_URL");
if (!url) {
  console.error("SUPABASE_DB_URL is not set");
  Deno.exit(1);
}

const seedPath = new URL("../supabase/seed.sql", import.meta.url);
const seed = await Deno.readTextFile(seedPath);
const sql = postgres(url, { prepare: false });

try {
  await sql.unsafe(seed);
  const [row] = await sql<{ catalog: number; rewards: number; config: number }[]>`
    select
      (select count(*)::int from catalog_items) as catalog,
      (select count(*)::int from level_rewards) as rewards,
      (select count(*)::int from game_config) as config
  `;
  console.log(
    `Loaded catalog_items=${row.catalog} level_rewards=${row.rewards} game_config=${row.config}`,
  );
} finally {
  await sql.end();
}
