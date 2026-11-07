# Questline

Gamified productivity for university students: real tasks are judged by an AI, done in verified focus sessions, and turned into XP, levels, gear, cosmetics, deadline bosses, raids and a friends leaderboard.

**Stack:** Flutter (Android demo, iOS builds) + Supabase (Postgres + RLS, Auth, Edge Functions, Realtime, pg_cron) + Groq free API for the AI judge. Free platforms only.

Specs and reading order: [`docs/README.md`](docs/README.md). First-time machine/account setup: [`docs/SETUP.md`](docs/SETUP.md). Git workflow: [`docs/VERSION-CONTROL.md`](docs/VERSION-CONTROL.md) (local only — holds tokens).

---

## Setup

1. Install tools from `docs/SETUP.md` §A (Flutter, Docker Desktop, Supabase CLI, Deno, Git, GitHub CLI).
2. Clone the repo and run the team git setup (`docs/SETUP.md` §C).
3. Start the local stack (Docker must be running):

```powershell
supabase start
```

4. Copy env templates (never commit real keys):

```powershell
Copy-Item supabase\functions\.env.example supabase\functions\.env
Copy-Item app\dart_defines.example.json app\dart_defines.local.json
```

Put `GROQ_API_KEY` in `supabase/functions/.env` (keep `AI_PROVIDER=fake` while developing). Paste the local API URL and anon key from `supabase status` into `app/dart_defines.local.json`.

5. App packages:

```powershell
cd app
flutter pub get
```

---

## Run

**Local Supabase + Android**

```powershell
# terminal 1 — already: supabase start
cd app
flutter run --dart-define-from-file=dart_defines.local.json
```

**Cloud backend** — use `app/dart_defines.cloud.json` (from `dart_defines.cloud.example.json`) with the project URL and anon key.

**Edge Functions (local)**

```powershell
supabase functions serve --env-file supabase/functions/.env
```

Keep `AI_PROVIDER=fake` unless you are testing the AI judge or running a demo.

---

## Test

```powershell
# Flutter
cd app
flutter analyze
flutter test

# Edge Function pure modules + action drafts
cd ..\supabase\functions
deno test

# Schema / RLS (needs Docker + supabase start)
cd ..\..
supabase test db
```

Balance pace check (no DB):

```powershell
deno run --allow-read scripts/balance-sim.ts
```

---

## Deploy (cloud)

Assumes `supabase link` to the Free project in `ap-south-1`.

```powershell
# Migrations
supabase db push

# Catalog + game_config (needs SUPABASE_DB_URL)
deno run --allow-env --allow-read --allow-net scripts/seed-cloud.ts

# Demo cohort: hero ~L42, friends, guild, party raid, backup task (needs DB URL + service role)
# $env:SUPABASE_DB_URL = '...'
# $env:SUPABASE_URL = '...'
# $env:SUPABASE_SERVICE_ROLE_KEY = '...'
deno run --allow-env --allow-read --allow-net scripts/seed-demo.ts

# Functions
supabase functions deploy

# Secrets (example — do not paste real values into chat/git)
supabase secrets set AI_PROVIDER=groq GROQ_API_KEY=... CRON_SECRET=...
```

Cron functions that are called by pg_cron / GitHub Actions use `--no-verify-jwt` and the `x-cron-secret` header (`docs/02-TRD.md`).

**Signed release APK:** GitHub → Actions → **Release APK** → Run workflow. Requires repo secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. See `app/android/key.properties.example`. Never commit `key.properties` or `*.jks`.

**Keep the Free project awake:** open the dashboard and hit the app once the day before and the morning of the demo.

---

## Demo accounts (after `seed-demo.ts`)

| Role | Email | Notes |
|---|---|---|
| Phone B (hero) | `hero@questline.demo` | ~level 42, guild leader, demo mode |
| Phone C (raid) | `party@questline.demo` | Party raid member, demo mode |
| Friends | `friend1@questline.demo` … `friend9@…` | Varied weekly XP |

Password defaults to `QuestlineDemo1!` (override with `DEMO_PASSWORD`). Guild invite `DEMOGUILD`, raid invite `DEMORAID1`.
