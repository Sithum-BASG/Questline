# 02 · TRD — Technical Requirements Document

**Product:** Questline · **Last updated:** 10 Oct 2026 (v5: Groq is the AI provider everywhere; fake mode for tests)
**Read with:** `01-PRD.md` (what), `05-BACKEND-SCHEMA.md` (data), `06-IMPLEMENTATION-PLAN.md` (order).

> **For the AI agent:** The stack below is **fixed**. Do not add Firebase, another backend, another state-management library, router or AI provider. If a task seems to need a new package, stop and ask. The most important rule is §2. **This document and `05-BACKEND-SCHEMA.md` replace the Firebase architecture in `00-PROJECT-OVERVIEW.md` §22.**

---

## 1. Stack (all free tiers, no credit card)

| Layer | Choice | Notes |
|---|---|---|
| App | **Flutter** (stable), Dart 3, Android + iOS | Android is the demo platform |
| State management | **Riverpod** (`flutter_riverpod`) | Providers per feature |
| Routing | **go_router** | `StatefulShellRoute` for the 5 tabs |
| Models | **freezed** + **json_serializable** | snake_case JSON ↔ camelCase Dart (`fieldRename: snake` in `build.yaml`) |
| Backend | **Supabase** (Free plan), region **ap-south-1 (Mumbai)** | One platform for everything below |
| Auth | Supabase Auth | Email/password + Google (native sign-in → `signInWithIdToken`) |
| Database | Supabase **Postgres** with **Row Level Security** and column-level grants | Schema in `05-BACKEND-SCHEMA.md` |
| Server logic | Supabase **Edge Functions** (Deno, **TypeScript**) | Game logic; AI judge calls; scheduled jobs |
| Realtime | Supabase **Realtime** (Postgres changes) | Live raid HP, damage ticker, inbox, focusing-now |
| Scheduling | **pg_cron + pg_net** calling Edge Functions | Hourly rollover, 15-min deadlines, weekly reset |
| Tuning | `game_config` table (replaces Remote Config) | Edit live in the Supabase Table Editor |
| Notifications | **On-device** `flutter_local_notifications` + **in-app inbox** table | No push service; see §8 |
| AI | **Groq** free API (OpenAI-compatible), JSON-schema structured output, models `openai/gpt-oss-120b` → `openai/gpt-oss-20b` → `qwen/qwen3.8-27b`; called **only** from Edge Functions through `_shared/ai` | §7 — fake mode for tests, optional backup provider |
| Local dev | **Supabase CLI** local stack (Docker Desktop) on **Windows + PowerShell** (Cursor's terminal); macOS/Linux also work | Develop locally (functions call Groq over the internet); the cloud project is for integration and the demo. The team git commands run through Git for Windows' built-in shell, so they work from PowerShell |
| Animation | Flutter animations; **Rive or Lottie** only for reward moments | Respect reduced motion |
| Testing | `deno test` (game modules, functions), **pgTAP** via `supabase test db` (RLS/grants), `flutter_test` (app) | |

### Free-plan constraints to design around
| Limit (Free plan) | Impact | What we do |
|---|---|---|
| Project pauses after **1 week of inactivity** | Cloud project sleeps between bursts of work | Develop locally; use the cloud project at least weekly; check it's awake before every rehearsal and the demo |
| **2 active projects** | No separate dev/staging/prod | One cloud project (`questline`) + local stacks |
| 500 MB database, 5 GB egress, 1 GB storage | Plenty for ~50 users | Images ship inside the app, not in Storage |
| Edge Functions: 500k invocations/month, **2 s CPU** and 150 s wall clock per request | Fine for light game logic | Keep functions lean; batch scheduled work |
| Realtime: 200 concurrent connections, 2M messages/month | Fine | Subscribe only on screens that need live data; unsubscribe on leave |
| pg_cron availability on Free | Believed available; **verify on day 1** | Fallback: a GitHub Actions scheduled workflow that calls the same cron functions |

---

## 2. The core rule: server owns the game state

The app **never writes** XP, coins, levels, inventory, damage, chest results, streaks, achievements, scores, feed or inbox entries. It calls an Edge Function, which validates, calculates and writes in one database transaction.

Enforcement is in the database, not the UI:
1. **Revoke everything** from the `anon` and `authenticated` roles on all public tables, then grant back only `SELECT` (filtered by RLS) and a few **column-level** `INSERT`/`UPDATE` grants.
2. **RLS on every table** (deny by default).
3. **Triggers** validate the few client writes (e.g. you can only equip items you own).

The client may write only:
- `profiles`: `display_name`, `equipped_skin_id`, `equipped_background_id`, `equipped_frame_id`, `pinned_badges`, `title_id`, `hide_radar`, `show_boss_names`.
- `user_settings`: everything except `demo_mode`.
- `tasks`: insert a `draft` (title, notes, due_at, boss_id, raid_id); update `stat` while draft/open; update `status` draft→open once judged; delete draft/open tasks.
- `presence`: its own row.
- `inbox`: `read_at` on its own rows.

Edge Functions use a direct Postgres connection with elevated rights, which **bypasses RLS**, so every query in a function must filter by the authenticated user's id. This is the #1 thing to check in code review.

---

## 3. Flutter packages

Use the latest stable version at project start and commit `pubspec.lock`.

| Purpose | Package |
|---|---|
| Supabase (auth, db, functions, realtime) | `supabase_flutter` |
| Google sign-in | `google_sign_in` (native) → `supabase.auth.signInWithIdToken` |
| State | `flutter_riverpod` |
| Routing | `go_router` |
| Models | `freezed_annotation`, `json_annotation` (+ dev: `build_runner`, `freezed`, `json_serializable`) |
| Notifications | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Offline snapshot cache | `shared_preferences` (last Home / task list JSON) |
| Charts (radar) | `fl_chart` |
| QR | `qr_flutter` (show), `mobile_scanner` (scan) |
| Share / deep links | `share_plus`, `app_links` |
| Reward animation | `rive` **or** `lottie` (pick one at kickoff) |
| Fonts | Nunito bundled as an asset |
| Utils | `intl` |

## 4. Edge Function dependencies (Deno, `npm:` / `jsr:` specifiers)

`@supabase/supabase-js` (verify the caller's JWT, admin auth API), `postgres` (direct connection + transactions via `sql.begin`), `zod`. Groq (and the optional backup provider) are called with plain `fetch` on the OpenAI-compatible API — no AI SDK. Pinned in `supabase/functions/deno.json`. Tests with `deno test`.

---

## 5. Repository structure

```
questline/
├─ app/                              # Flutter app
│  ├─ lib/
│  │  ├─ main.dart                   # Supabase.initialize, ProviderScope, timezone init
│  │  ├─ app.dart  router.dart
│  │  ├─ core/
│  │  │  ├─ theme/                   # app_colors.dart, app_text.dart, shadows.dart, app_theme.dart
│  │  │  ├─ assets/                  # game_assets.dart (from the asset handoff pack)
│  │  │  ├─ widgets/                 # shared components (04-UI-UX-BRIEF.md §6)
│  │  │  ├─ supabase/                # client providers, api_client.dart (typed Edge Function calls)
│  │  │  ├─ config/                  # game_config reader (typed getters, cached)
│  │  │  ├─ notifications/           # notification_planner.dart (local scheduling rules)
│  │  │  └─ utils/
│  │  ├─ data/
│  │  │  ├─ models/                  # freezed models mirroring the tables
│  │  │  └─ repositories/            # queries + realtime subscriptions per domain
│  │  └─ features/
│  │     ├─ onboarding/ home/ quests/ focus/ bosses/ raids/
│  │     ├─ social/ hero/ chests/ rewards/ recap/ inbox/ settings/
│  │     └─ <feature>/{presentation/, providers/}
│  ├─ assets/images/<category>/      # from questline_assets.zip
│  └─ test/
├─ supabase/
│  ├─ config.toml                    # local stack config (auth providers, functions)
│  ├─ migrations/                    # timestamped SQL: tables, grants, RLS, triggers, cron
│  ├─ seed.sql                       # catalog, level rewards, game_config (local)
│  ├─ tests/                         # pgTAP: RLS + grants tests
│  └─ functions/
│     ├─ .env.example                # template for the git-ignored .env (AI_PROVIDER, GROQ_*, AI_BACKUP_*)
│     ├─ _shared/
│     │  ├─ game/                    # PURE modules: xp, rewards, loot, combat, achievements, streaks, time
│     │  ├─ ai/                      # prompts, schemas, judge client, validation
│     │  ├─ db.ts  auth.ts  config.ts  errors.ts  http.ts
│     ├─ account/  tasks/  sessions/  bosses/  raids/  loot/  social/     # client-facing
│     └─ cron-rollover/  cron-deadlines/  cron-weekly/                    # scheduled
├─ scripts/                          # seed-cloud.ts (catalog + config), seed-demo.ts
│  └─ git/                           # team git commands (git phase / task / pr) — see docs/VERSION-CONTROL.md
├─ docs/                             # README (reading order), 00 overview, 01–06 specs, VERSION-CONTROL.md (git-ignored: holds tokens)
├─ .githooks/                        # commit-msg + pre-commit (installed by scripts/git/setup.sh)
├─ .gitconfig                        # git aliases, included by setup
├─ .gitattributes                    # LF line endings for scripts and hooks (so they run on Windows)
├─ AGENTS.md                         # entry point for AI agents
└─ .cursor/rules/                    # questline.mdc, git-workflow.mdc (incl. PowerShell rules), flutter-app.mdc, supabase-backend.mdc
```

**Conventions**
- Dart: `snake_case.dart` files, `PascalCase` classes, `lowerCamelCase` members.
- SQL: `snake_case` tables and columns, plural table names, `text` + `check` constraints instead of Postgres enums (easier migrations), `timestamptz` for times, `date` for day keys.
- TS: `camelCase.ts`; action names exactly as in `05-BACKEND-SCHEMA.md` §6.
- Day keys are computed **on the server** in the user's IANA timezone with a **4 a.m.** boundary.
- XP, coins, HP and damage are integers. Compute in floats, round once at the end (half up).
- Every schema change is a migration (`supabase migration new <name>`); never edit tables by hand in the cloud dashboard (except `game_config` values).

---

## 6. Edge Function contract

Client-facing functions are grouped by domain; the body carries an `action`:
```dart
await supabase.functions.invoke('sessions', body: {'action': 'endSession', 'sessionId': id, 'interruptions': [...]});
```
Every action:
1. Requires a valid user JWT (default `verify_jwt`); reads the user id from it. Never trusts a user id in the body.
2. Validates the body with `zod`; returns `400 {code:'invalid_argument', message}` on failure.
3. Reads `game_config` (cached ~60 s per function instance) with fallback to `_shared/config.ts` defaults.
4. Does all writes in **one transaction** (`sql.begin`) where values change, filtering every query by the user id.
5. Is **idempotent** where retries could double-pay (`endSession`, `openChest`, `submitBoss`).
6. Returns typed JSON the UI renders directly; errors as `{code, message}` with HTTP 4xx/5xx.

Cron functions are deployed with `--no-verify-jwt` and require an `x-cron-secret` header matching the `CRON_SECRET` secret.

Client wrapper: `core/supabase/api_client.dart`, one typed method per action, mapping error codes to friendly text.

---

## 7. AI provider — Groq

All AI calls (task judge, challenge, boss/raid estimate) go through **one interface** in `supabase/functions/_shared/ai/`. Nothing outside that folder knows which provider is used.

```ts
// _shared/ai/provider.ts
export interface AiProvider {
  generateJson(req: { system: string; user: string; schemaName: string; schema: object }): Promise<unknown>;
}
// getProvider() reads AI_PROVIDER: 'groq' (default — local development, cloud, demo) | 'fake'
```
`judge.ts` and `boss.ts` build the prompt, call `getProvider().generateJson(...)`, then validate and clamp.

### 7.1 Groq request (OpenAI-compatible Chat Completions, plain `fetch`, no SDK)
```http
POST https://api.groq.com/openai/v1/chat/completions
Authorization: Bearer ${GROQ_API_KEY}
Content-Type: application/json

{
  "model": "openai/gpt-oss-120b",
  "messages": [ { "role": "system", "content": "<system prompt>" }, { "role": "user", "content": "<input JSON>" } ],
  "temperature": 0.2,
  "reasoning_effort": "low",
  "response_format": { "type": "json_schema", "json_schema": { "name": "task_judgement", "strict": true, "schema": { ... } } }
}
```
- Parse `choices[0].message.content` as JSON.
- `reasoning_effort`: `"low"` for `openai/gpt-oss-*` models (keeps output tokens small); `"none"` for `qwen/*` models. Don't send `logprobs`, `logit_bias`, `n` or `messages[].name` (Groq rejects them).
- Strict JSON-schema mode needs every property in `required` and `additionalProperties: false` (schemas in `05-BACKEND-SCHEMA.md` §11 already follow this).
- Timeout per attempt: `game_config.ai_timeout_ms` (10 000 ms).

### 7.2 Fallback chain
1. **Model rotation:** try each model in `GROQ_MODELS` in order (default `openai/gpt-oss-120b,openai/gpt-oss-20b,qwen/qwen3.8-27b`). On HTTP 429 or 5xx, or a timeout, move to the next model — each model has its own free-tier limits.
2. **Optional backup provider:** if `AI_BACKUP_URL`, `AI_BACKUP_KEY` and `AI_BACKUP_MODEL` are set, send the same request to that OpenAI-compatible endpoint (e.g. an OpenRouter free model, or Cerebras during demo week). Empty = skipped.
3. **Provisional:** if everything fails, save the task as provisional (difficulty 3, estimate 30 min) and re-judge it later in `cron-deadlines`. The user is never blocked.

### 7.3 Fake mode
`AI_PROVIDER=fake` returns an instant, deterministic judgement without any network call: stat from simple keywords (gym/run/walk → vitality, code/design/build → craft, meet/call/email → charisma, else intellect), difficulty 3, 30 minutes, `too_big` false, reason "Development judge (fake mode)."; boss estimate 6 hours, name "The Practice Shade". Use it:
- **always** in automated tests (`deno test` injects the fake provider; CI has no Groq key), and
- while working on anything that isn't the AI itself (screens, sessions, bosses, social), to save the free quota.
Switch to `groq` when working on or demonstrating the AI judge.

### 7.4 Free-tier limits and budget
Groq's free limits apply **per organisation, per model**: 30 requests/min, 1,000 requests/day, 8,000 tokens/min, 200,000 tokens/day (check the account's Limits page; Groq may change them). A judge call is ~1,000 input tokens (system prompt + few-shots) plus a few hundred output tokens, so tokens are the binding limit: **≈ 6 judge calls/min and ≈ 150/day per model, ≈ 450/day across the three models.** With one person working at a time and fake mode for non-AI work, that is far more than needed. Count every call against the app's own daily limit (`ai_daily_limit`, 50 per user).

### 7.5 Shared rules
- Prompts and few-shots copied **verbatim** from `00-PROJECT-OVERVIEW.md` §23 into `_shared/ai/prompts.ts`. The prompts already say "Return only JSON".
- Validation: zod parse → reject unknown stat → clamp (difficulty 1–5, minutes 5–180, hours 2–40) → truncate reason to 20 words → boss name 2–4 words else "The Deadline Shade". Invalid output counts as a failure (next model / backup / provisional).
- Send **only** task text, notes, parent title, due-in-days, participants and optional study context. Never names, emails or ids.
- **Data:** Groq doesn't retain inference inputs/outputs by default; turn on **Zero Data Retention** (Groq Console → Data Controls) so nothing is kept even for abuse monitoring. The in-app privacy line: "Task text and your optional study context are sent to our AI provider (Groq) to rate the task. Nothing else is shared."
- `GROQ_API_KEY` and backup keys live only in `supabase/functions/.env` (local, git-ignored) and Supabase secrets (cloud). Never in the app, never in git.

---

## 8. Notifications without a push service

Supabase can't deliver phone push on its own (Android push always goes through Google's FCM), so v1 uses:

1. **Local notifications planned on the device** by `notification_planner.dart`. It recomputes the next 7 days of notifications from current state on app start, resume, after `endSession`/`tickTask`/boss and raid changes, and after settings changes. It enforces the 2-per-day cap, quiet hours and category toggles.
2. **In-app inbox** (`inbox` table, realtime while the app is open, bell with unread count) for things only the server knows at the moment they happen: guild fight started, raid result, weekly results, friend requests.

| Notification (PRD) | How |
|---|---|
| Boss 48 h / 24 h warning (if < 75% damage) | Local, scheduled from the deadline; cancelled when damage passes 75% |
| "Your boss healed 3% today" | Local, scheduled for the next morning after a no-work day; cancelled when the user works on it |
| Streak reminder 20:00 | Local |
| Focus timer + "return within 30 s" | Local (ongoing notification) |
| Comeback after 3 inactive days | Local, rescheduled every app open |
| Weekly results Monday morning | Local Monday 08:00 + inbox entry with the actual results |
| Sunday "X XP behind 2nd" (off by default) | Local Sunday 18:00 using the last known gap |
| Raid result | Local at deadline + 20 min ("Your raid has ended") + inbox entry |
| Guild fight started, friend request | **Inbox only** (no notification if the app is closed) |
| Live party invite | Not needed: parties join by code/QR/link in person |

**Limitation (state in the report):** notifications reflect the state the phone last saw, and "guild fight started" can't reach a closed app. Adding FCM later would fix both without schema changes.

---

## 9. Configuration and secrets

| Name | Where | Purpose |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | app via `--dart-define` (local and cloud values) | Public client config; safe in the app |
| `AI_PROVIDER` | `supabase/functions/.env` locally; Supabase secret in the cloud | `groq` (default) or `fake` (§7.3) |
| `GROQ_API_KEY` | `supabase/functions/.env` locally; Supabase secret in the cloud | Groq API key. Never in the app, never in git |
| `GROQ_MODELS` | same (optional) | Comma-separated model order for rotation; default `openai/gpt-oss-120b,openai/gpt-oss-20b,qwen/qwen3.8-27b` |
| `AI_BACKUP_URL`, `AI_BACKUP_KEY`, `AI_BACKUP_MODEL` | same (optional) | Second OpenAI-compatible provider (§7.2); leave empty to skip |
| `CRON_SECRET` | Supabase secret + Vault (for pg_cron) | Authenticates scheduled calls |
| `LEADERBOARD_TZ` | Supabase secret, default `Asia/Colombo` | Global leaderboard week boundary (Monday 4 a.m.) |
| `SUPABASE_DB_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Provided to Edge Functions automatically | Never used in the app |
| Google OAuth client IDs | Google Cloud console (free, no billing) + Supabase Auth settings | Google sign-in |
| `game_config` table | Database | All game numbers |
| `demo_allowlist` table | Database (no client access) | Demo-mode uids |

`.gitignore`: `docs/VERSION-CONTROL.md`, `.env`, `.env.*` (except `.env.example`), `supabase/functions/.env`, `**/key.properties`, `*.jks`, `*.keystore`, `_handoff/`, any service-role key. `.gitattributes` keeps `*.sh` and `.githooks/*` on LF line endings.

---

## 10. Non-functional requirements

| Area | Requirement |
|---|---|
| Security | Grants revoked by default; RLS on every table; pgTAP tests for owner / friend / stranger / party member and every forbidden write |
| Performance | Live raid updates on another phone within ~2 s; leaderboard in one query |
| Offline | Last Home and task-list snapshot cached locally and shown with an "Offline" pill; actions need network |
| Cost | Free plan only; no listeners on whole tables; feed paginated 20 at a time |
| Accessibility | WCAG AA contrast, 48 dp targets, reduced motion, semantics labels |
| Privacy | Task text only to Groq (Zero Data Retention on); account deletion cascades from `auth.users` |
| Testing | `_shared/game/*` ≥ 90% line coverage; every number in `01-PRD.md` §6 has a test; AI calls mocked in automated tests |
| Platforms | Android (demo), iOS builds |

## 11. Known technical limitations (say so in the report)

- Session verification relies on the app reporting time away from the foreground; the server clock fixes start and end.
- The AI judge depends on Groq's free tier: limits and available models can change without notice. Mitigated by model rotation, an optional backup provider, the provisional fallback and a pre-judged backup task for the demo.
- Activity mode trusts the user while the phone is locked.
- Gear attunement is a stopgap (10 items, 4 stats).
- Notifications are planned on the device (§8); no server push in v1.
- "Focusing now" uses a heartbeat, so a killed app shows as focusing for up to ~2 minutes.
- Free-plan project pauses after a week of inactivity.
