# 06 · Implementation Plan — Build Sequence

**Product:** Questline · **Team:** 6 · **Order:** Phase 0 → Phase 16 · **Feature freeze:** when core is complete (end of Phase 13)
**Who does what:** `VERSION-CONTROL.md` §8–§9 (phases, branches, task owners, task order)
**Stack:** Flutter + Supabase (Free plan) + Groq free API for the AI judge — no credit card anywhere
**Last updated:** 10 Oct 2026 (v3: dates removed — order only)

> **For the AI agent:** Build in this order. Never start a phase whose "Depends on" isn't done. Each numbered step is sized for one Cursor chat: read the docs it cites, propose a short plan, then implement, then run the listed checks. A step is done only when its **Done when** line is true. Don't build ahead into a later phase.

---

## 0. How to use these docs with Cursor

1. These docs live in `docs/` (reading order in `docs/README.md`); `.cursor/rules/questline.mdc` and `.cursor/rules/git-workflow.mdc` are always applied. Backend details in `00-PROJECT-OVERVIEW.md` (§22, Firebase) are **superseded** by `02-TRD.md` and `05-BACKEND-SCHEMA.md`.
2. **Work phase by phase.** Each phase is one branch and one PR (`docs/VERSION-CONTROL.md`). Its steps map to tasks (T001–T134) with owners in `VERSION-CONTROL.md` §9. Cursor works through a phase's tasks in order without stopping between them, then opens the phase PR and stops until the user has merged it. A typical start:
   > Do Phase 6 following @docs/VERSION-CONTROL.md §3. For each task, implement its step from @docs/06-IMPLEMENTATION-PLAN.md using @docs/05-BACKEND-SCHEMA.md and @docs/02-TRD.md.
3. **Plan first, then code — per task.** Before each task, state in one short paragraph which files change and which tests are added, then implement. Stop and ask only if the step needs something outside the plan: a new package, a renamed column or action, a change to another phase's code, or a doc that contradicts another.
4. **Tests first for `_shared/game/*`.** Paste the test cases from `05-BACKEND-SCHEMA.md` §10, make them fail, then implement.
5. **Every schema change is a migration.** Ask Cursor to write `supabase/migrations/<timestamp>_<name>.sql` and a pgTAP test; run `supabase db reset` and `supabase test db`.
6. Run checks before accepting: `flutter analyze`, `flutter test`, `deno test` in `supabase/functions`, `supabase test db`.
7. One PR per phase; the user reviews and merges it manually. The reviewer's #1 check: **every SQL in an Edge Function filters by the caller's user id** (functions bypass RLS).
8. When a doc is wrong or a decision changes, update the doc in the same phase branch (a `docs(...)` commit under the related task) and mention it in the PR description.

---

## 1. Roles

Task-level owners, phase branches and task order are in `VERSION-CONTROL.md` §8–§9.


| # | Role | Owns |
|---|---|---|
| R1 | Design lead | Figma design system and KEY screens, theme tokens, shared widgets, reward moments, settings screen (+ rest day/pause actions), motion polish, screen reviews |
| R2 | Tasks and focus | App bootstrap, router, API client, auth + onboarding screens, Quests, judgement card wiring, rescheduleTask, focus + activity mode, session complete, bosses UI |
| R3 | Character and loot | Asset import, data models, StageCard/PortraitFrame, loot.ts + chest actions, Home, profile, radar, gear/attunement, wardrobe, inventory, chests, level road, achievements, recap, deleteAccount |
| R4 | Social | Google OAuth setup, CI, friends, leaderboard, feed, guilds, raid screens (live), presence, inbox |
| R5 | Backend | Supabase setup, migrations, grants/RLS + pgTAP tests, XP engine, cron jobs, notification planner, seed scripts |
| R6 | AI and bosses | Prompts, judge actions, AI test set, rewards.ts, combat.ts, bosses and raids logic, balancing, security test pass, test lead, report |

---

## 2. Order at a glance

Work through the phases in order. Phases may overlap only where their **Depends on** lines allow (e.g. Phase 5 game modules only need 1.6, so they can run alongside Phases 2–4). Stretch goals are off by default.

| Stage | Phases | Checkpoints, in order |
|---|---|---|
| 1 · Foundations | 0 Kickoff · 1 Setup · 2 Schema and security · 3 Auth and onboarding · 4 Tasks and AI judge (5 and 10 can start early) | Schema + RLS tests green → AI prompt frozen → sign in → onboarding → add a judged task |
| 2 · Core | 5 Game modules · 6 Focus and XP engine · 7 Progression UI · 8 Rollover · 9 Bosses · 10 Social · 11 Raids · 12 Achievements/weekly · 13 Notifications | Solo loop demo (after Phase 8) → **core complete** (after Phase 13) |
| 3 · Finish | 14 Polish · 15 Testing · 16 Demo and release | **Feature freeze** → demo build on 3 phones → rehearsals → demo / submission |

**If core complete is at risk, cut in this order:** weekly recap (show a simple summary card) → guild weekly quest → Sunday nudge and comeback notifications → guild fights (keep parties) → Early Bird / Steady Pace / Balanced badges. Never cut: AI judge, verified focus, XP/levels, chests, solo bosses, party raid, leaderboard, server-owned state.

## Phase 0 — Kickoff (everyone, 2 hours)

- 0.1 Walk through the 6 docs. Confirm or change decisions **D1–D15** (`05-BACKEND-SCHEMA.md` §13). Update the doc.
- 0.2 Confirm conventions (`02-TRD.md` §5). Pick Rive **or** Lottie.
- 0.3 Accounts (all free, no card): one **Supabase** organisation with all 6 members, project `questline` in **ap-south-1**; a **Groq** account and API key (Zero Data Retention on — see `docs/SETUP.md`); a **Google Cloud** project for OAuth client IDs only (no billing); **GitHub** repo.
- 0.4 Everyone who develops installs Flutter, Docker Desktop, the Supabase CLI, Deno, Git and the GitHub CLI (`docs/SETUP.md`); `supabase start` works on each laptop, and a test call to Groq with the key succeeds.
- 0.5 In the cloud project, enable the `pg_cron` and `pg_net` extensions. **If pg_cron isn't available on Free**, record it here and use the GitHub Actions fallback in Phase 8.
- **Done when:** decisions recorded, every developer runs the local Supabase stack, the Groq key works, cron path decided.

## Phase 1 — Setup · R5 lead, R1 tokens

- 1.1 Monorepo per `02-TRD.md` §5: `app/` (`flutter create`), `supabase/` (`supabase init`), `scripts/`, `.gitignore`, `.gitattributes` (the skeleton and the git tooling come from setup — this step checks and completes the layout).
- 1.2 `supabase_flutter` init in `main.dart` from `--dart-define` values (local by default; a `cloud` launch config for the shared project). Riverpod providers for the client and auth state.
- 1.3 Import `questline_assets.zip` (placed at `_handoff/questline_assets.zip`, git-ignored — see `docs/SETUP.md` B5): images to `app/assets/images/`, `game_assets.dart` → `core/assets/`, `app_colors.dart` → `core/theme/`; register in `pubspec.yaml`; bundle Nunito; launcher icons.
- 1.4 Theme tokens from `04-UI-UX-BRIEF.md` §2–4.
- 1.5 `router.dart` with **every route** from `03-APP-FLOW.md` §2 as placeholders; 5-tab `StatefulShellRoute`; floating tab bar.
- 1.6 Edge Function scaffold: `_shared/http.ts` (CORS, JWT → user, zod errors), `_shared/db.ts` (`postgres` on `SUPABASE_DB_URL`, transactions), `_shared/config.ts` (defaults from §8 + `game_config` cache), `_shared/errors.ts`; empty `account`, `tasks`, `sessions`, `bosses`, `raids`, `loot`, `social`, `cron-*` functions; `deno.json`; `deno test` sample.
- 1.7 `core/supabase/api_client.dart` — typed `invoke(function, action, body)` with error mapping.
- 1.8 CI (GitHub Actions, free): `flutter analyze` + `flutter test`; `deno test`; `supabase start` + `supabase test db`.
- **Done when:** app runs on an Android phone with the 5 empty tabs in the right fonts/colours and calls a hello action on the local stack; CI is green.

## Phase 2 — Schema and security · R5

Depends on: 1
- 2.1 Migrations for every table in `05-BACKEND-SCHEMA.md` §2 (reference data → players → tasks/sessions/bosses → inventory/stats → social → raids).
- 2.2 Migration: grants (§3), helper functions and RLS policies (§4), triggers `validate_profile_update` and `validate_task_update`, realtime publication and indexes (§5).
- 2.3 pgTAP tests: owner / friend / stranger / party member for every table; every forbidden column write gets `permission denied`; task draft→open path; equip only owned items; `demo_allowlist` unreadable.
- 2.4 `supabase/seed.sql` with all `catalog_items`, `level_rewards` (§9) and `game_config` (§8); `scripts/seed-cloud.ts` to load the same into the cloud project.
- 2.5 freezed models for each table the app reads (`data/models/`), snake_case JSON.
- **Done when:** `supabase db reset` builds everything from migrations + seed; `supabase test db` is green.

## Phase 3 — Auth and onboarding · R2 UI, R5 server

Depends on: 2
- 3.1 Supabase Auth: email/password (confirmation off, D15) and Google (`google_sign_in` → `signInWithIdToken`); OAuth client IDs; sign-out; redirect logic (`03-APP-FLOW.md` §3).
- 3.2 `account/completeOnboardingStep` (creates `player_state`, `user_settings`, `profiles`, starter inventory, `presence`, `friend_summaries`; generated username + friend code (D14); timezone; starter XP once per step).
- 3.3 Character screen with live `StageCard`.
- 3.4 Story: 7 cards, images by body type, Skip/Begin, `{Name}` in card 7.
- 3.5 Study context screen (optional), with the AI privacy line (task text and study context are sent to Groq to rate tasks; nothing else).
- **Done when:** a new account goes welcome → character → story → study and resumes at the right step after an app kill.

## Phase 4 — Tasks and AI judge · R6 server, R2 UI

Depends on: 2 (server), 3.1 (UI)
- 4.1 `_shared/ai/`: prompts (verbatim from the overview §23), response schemas (§11), the `AiProvider` interface with the **Groq** implementation (model rotation via `GROQ_MODELS`, optional backup via `AI_BACKUP_*`) and the **fake** provider (`02-TRD.md` §7); timeouts from `ai_timeout_ms`. Keys: `supabase/functions/.env` locally (from `.env.example`, git-ignored), `supabase secrets set AI_PROVIDER=groq GROQ_API_KEY=…` in the cloud.
- 4.2 `tasks/judgeTask` + `tasks/challengeTask`: validation, clamping, daily limit, provisional fallback.
- 4.3 **AI test set**: `supabase/functions/_shared/ai/judge-set.json` (~30 tasks: all stats, easy/hard, vague, 3 injections). A script runs them against Groq (pause ~2 s between calls to stay under the per-minute token limit) and writes a Markdown results table for the report, including which model answered. Adjust, then **freeze the prompt**.
- 4.4 Quests tab (Today / Upcoming / Done, stat filter); add-task sheet inserts a `draft` row; `JudgementCard`; Save (`status = 'open'`); discard deletes the draft.
- 4.5 Challenge sheet → `challengeTask`.
- 4.6 Onboarding step 4 reusing the card; boss toggle hidden until Phase 9.
- **Done when:** "Write introduction for Computer Forensics report (800 words)" → Intellect, difficulty 4, ~90 min; injections ignored; with a wrong `GROQ_API_KEY` (and no backup) the app shows a provisional card instead of an error; `AI_PROVIDER=fake` returns instant canned judgements.

## Phase 5 — Pure game modules · R5 + R6

Depends on: 1.6. **Tests first** (`deno test`).
- 5.1 `xp.ts` — §10.1 incl. the listed tests and the 8-hour limit.
- 5.2 `rewards.ts` — level curve, totals table, multi-level rewards.
- 5.3 `loot.ts` — injectable RNG, pity, unowned-first, pouches, overflow, refunds, Mythic set; 100,000-roll simulation test (rates within ±0.5%).
- 5.4 `combat.ts` — tiers, HP, damage, healing, solo loot, raid result, fair share, MVP.
- 5.5 `streaks.ts` — rest day, pause, shields (not two days in a row), milestones once.
- 5.6 `achievements.ts` — thresholds, tier-up rewards, titles.
- 5.7 `time.ts` — 4 a.m. day keys per timezone, `weekId` in `LEADERBOARD_TZ`.
- **Done when:** coverage ≥ 90% and every number in `01-PRD.md` §6 has a test.

## Phase 6 — Focus sessions and the XP engine · R2 UI, R5 server

Depends on: 4, 5.1–5.2, 5.7
- 6.1 `sessions/startSession` (one active per user via the unique index, activity only for Vitality/Charisma, potion arming).
- 6.2 Focus screen: timer from server `started_at`, ring vs estimate, ongoing local notification, lifecycle tracking (`03-APP-FLOW.md` §6), 30 s grace with a local "return" notification, "End session?" dialog, activity variant.
- 6.3 `sessions/endSession` in one transaction: verified minutes → `xp.ts` → `daily_stats` → `weekly_scores` → level-ups + level rewards → `friend_summaries` → `activity_events` (`level_up`). Idempotent via `processed` + stored `summary`. (Boss damage added in Phase 9, guild quest in 11, achievements in 12.)
- 6.4 `tasks/tickTask` (50% path).
- 6.5 Session complete screen from `SessionSummary`.
- 6.6 Presence: client sets its `presence` row to `focusing` (unless appear offline), heartbeats `last_seen` every 60 s, sets `idle` on finish.
- 6.7 Onboarding steps 5–6 (5-minute first session, starter XP, level 2).
- 6.8 Demo mode: uid in `demo_allowlist` + `demo_mode` on → server treats 30 s as 5 min.
- **Done when:** a 60-minute difficulty-4 on-time session shows **86 XP**; calling `endSession` twice pays once; a friend sees "focusing" and it disappears ~2 min after killing the app.

## Phase 7 — Progression UI · R3, R1 for reward moments

Depends on: 6.3
- 7.1 Home (layout in `03-APP-FLOW.md` §4) with live data and the offline snapshot cache; boss card placeholder.
- 7.2 Profile: stage, title, pinned badges, radar 30/7 from `daily_stats`.
- 7.3 Level road from `level_rewards`.
- 7.4 Gear and attunement (`loot/equipGear`, `loot/attuneGear`).
- 7.5 Wardrobe (client updates `profiles.equipped_*`; trigger rejects unowned items) + `PortraitFrame`.
- 7.6 Inventory (consumables, hold limits, `loot/usePotion`).
- 7.7 `loot/openChest` + Chest screen (rates from `game_config`, pity counter) + reveal overlay.
- 7.8 `RewardOverlay` template + reward queue after Session complete; reduced-motion variant.
- 7.9 Onboarding steps 6–7 (free chest, Home with "Add friends" card).
- **Done when:** a fresh account reaches level 2 in onboarding, opens the free chest, equips the frame, and the portrait updates everywhere.

## Phase 8 — Rollover, streaks, safeguards · R5

Depends on: 5.5, 6.3
- 8.1 `cron-rollover` (§6 Scheduled) with `x-cron-secret`; schedule with pg_cron + pg_net (Vault secrets `project_url`, `cron_secret`). **Fallback:** `.github/workflows/cron.yml` with `schedule:` calling the same URLs.
- 8.2 `account/setRestDay`, `account/setPause` + Settings UI; streak tile on Home.
- 8.3 Integration test on the local stack: simulate 10 days for one user (met, missed, rest, shield, pause) by calling `cron-rollover` with a faked clock parameter (local only) and assert streak values.
- **Done when:** the 10-day simulation passes and comeback 2× applies on the right session.

### Checkpoint — solo loop
Demo the full solo loop (focus → XP → level up → chest) to the team before going further. **Plan for no stretch goals**; only reconsider AI calibration if Phases 1–8 are green with time to spare.

## Phase 9 — Solo bosses · R6 server, R2 UI

Depends on: 6.3, 5.4, 8.1
- 9.1 `bosses/createBoss` (dryRun preview with AI estimate + name; confirm with hours slider; 48 h coin rule; 15-fight limit).
- 9.2 Damage in `endSession`; healing in `cron-rollover`; `bosses/submitBoss`; escape in `cron-deadlines` (every 15 min) + inbox `boss_result`.
- 9.3 Bosses list, Create boss, Boss detail (KEY), Boss result; Home closest-boss card; onboarding boss toggle on.
- **Done when:** a 2-hour boss due in 3 days loses HP from a demo-mode session, is submitted for full loot; an unsubmitted boss past its deadline escapes with −100 coins.

## Phase 10 — Friends, leaderboard, feed · R4

Depends on: 6.3
- 10.1 `social/sendFriendRequest`, `respondFriendRequest`, `removeFriend`; Friends list; add by username, code, QR (`mobile_scanner`, camera on demand), share text with the code.
- 10.2 Friend profile (`profiles` + `friend_summaries` + radar unless hidden).
- 10.3 Leaderboard (KEY): one query on `weekly_scores` (RLS = me + friends), empty state, "reach 500 XP" note.
- 10.4 Activity feed (paginated, `visible_to`).
- 10.5 "Focusing now" from `presence` (realtime on Home/Social).
- **Done when:** two accounts befriend each other and see each other's weekly XP, feed and focusing dot; a stranger sees none of it (pgTAP proves it).

## Phase 11 — Guilds, parties, raids · R4 UI, R6 server

Depends on: 9, 10
- 11.1 `social/createGuild`, `joinGuild`, `leaveGuild` + Guild home (members, focusing now, weekly quest, trophies).
- 11.2 `raids/createRaid` (guild fight → inbox `guild_fight` for guild members; party → invite code), `raids/joinRaid`, `raids/leaveRaid`.
- 11.3 Raid damage in `endSession` (`raid_damage`, `raids.damage`, `raid_events`, live `met_fair_share`).
- 11.4 Raid resolution in `cron-deadlines`: result, fair share, loot, penalty, MVP, trophies, feed `raid_won`, inbox `raid_result`, delete events.
- 11.5 Screens: Start raid, Invite (code/QR/share), Join, Raid detail (KEY, Realtime), Raid results (+ Add as friend).
- 11.6 Guild weekly quest progress in `endSession`; payout in `cron-weekly`.
- **Done when:** two phones in a party raid see HP and ticker update within ~2 s; results show correct check marks and MVP.

## Phase 12 — Achievements, weekly reset, recap · R3 UI, R5 server

Depends on: 5.6, 9, 10, 11
- 12.1 Achievement counters wired into `endSession`, `submitBoss`, raid resolution, rollover; Achievements screen; pin 3 badges; titles.
- 12.2 `cron-weekly` (ranks, weekly target coins, guild quest, Balanced/Steady Pace, inbox `weekly_results`, resets).
- 12.3 Weekly recap cards from `daily_stats` + the weekly results entry.
- **Done when:** a scripted week on the local stack produces correct ranks, coins, badge counts and a recap.

## Phase 13 — Notifications and inbox · R5 planner, R4 inbox UI

Depends on: 8, 9, 11
- 13.1 Android notification channels; permission asked after the first session; `timezone` init.
- 13.2 `notification_planner.dart`: boss 48/24 h warnings (cancel at ≥ 75% damage), boss healed, streak 20:00, comeback, Monday weekly results, raid ended, Sunday nudge (off by default); 2/day cap, quiet hours, category toggles; re-plan triggers from `03-APP-FLOW.md` §7b. Unit-test the planner with a fake clock.
- 13.3 Inbox screen + bell badge (realtime on `inbox` while the app is open; mark read).
- 13.4 Every notification and inbox item deep-links to its screen.
- **Done when:** planner tests pass; on a phone, each notification type fires once at a faked time and opens the right screen; a third notification in a day is suppressed.

### Checkpoint — core complete
Everything in `01-PRD.md` §5.1 works end to end on Android. Unfinished items are cut or simplified now.

## Phase 14 — Polish · R1 lead, everyone

**Feature freeze starts here** (`git phase 14` cuts `release/v1.0` — `VERSION-CONTROL.md` §5.2). Only bug fixes and polish from now on.

- 14.1 Empty, loading and error states from `03-APP-FLOW.md` §7 everywhere (incl. "server waking up").
- 14.2 Motion pass, reduced-motion check, haptics.
- 14.3 Accessibility: contrast, 48 dp targets, semantics, 130% font scale.
- 14.4 Design lead reviews every non-KEY screen.

## Phase 15 — Testing and balance · R6 lead

- 15.1 pgTAP and `deno test` green in CI.
- 15.2 Balance simulation (2 h/day, 6 days/week, 12 weeks): L10 ≈ 1.5 weeks, L25 ≈ 8–9 weeks, ~1 chest per 1–1.5 weeks. Tune `game_config`, not code.
- 15.3 Manual pass on 3 Android devices (incl. a low-end one) + one iOS build.
- 15.4 Security pass: try updating `player_state.coins` or `profiles.level` from the client with the anon key; read a stranger's tasks; prompt injection; double `endSession`/`openChest`.

## Phase 16 — Demo and release · R5 seed, R6 lead

- 16.1 `scripts/seed-demo.ts` — one command recreates: hero account (≈ level 42, Legendary gear, most badges, guild, 60 days of `daily_stats`), ~9 friends with varied weekly XP, a party raid due in 3+ days, a pre-judged backup task; adds hero uids to `demo_allowlist`.
- 16.2 Demo mode forced chest drop (e.g. Mythic) for allow-listed accounts.
- 16.3 Cloud deploy: `supabase db push` (migrations), `supabase functions deploy`, secrets, seed, cron jobs. Signed release APK; demo build tagged and installed on 3 phones before the rehearsals.
- 16.4 **Keep the free project awake:** use it at least weekly; open the dashboard and run one request the day before and the morning of the demo.
- 16.5 Backup screen recording; mobile hotspot; scrcpy mirroring tested.
- 16.6 Three timed rehearsals (seed reset each time). Demo section 7 ("under the hood"): show `supabase test db` and `deno test` passing, then change `chest_cost` in the `game_config` table live.
- 16.7 Report: architecture, AI test-set table, RLS tests, known limitations (`02-TRD.md` §11), future work (FCM push, Health Connect).

---

## 3. Definition of done (whole project)

- [ ] All Must-have features in `01-PRD.md` §5.1 work end to end on Android.
- [ ] No client can write any server-owned column (pgTAP proves it).
- [ ] Game module tests pass; every PRD number has a test.
- [ ] AI test set run, prompt frozen, results table in the report.
- [ ] Live raid works on two phones on the same hotspot.
- [ ] Seed script resets demo data in one command; demo rehearsed 3 times.
- [ ] Total spend: **0**. Every member can explain their code.

## 4. Risk register

| Risk | Mitigation |
|---|---|
| An Edge Function forgets to filter by user id (bypasses RLS) | Review checklist item; shared helpers that take `userId`; integration tests with two users |
| Supabase default grants left open | Phase 2 revokes all; pgTAP checks `permission denied` on every server column |
| `endSession` grows huge | Orchestrator calling pure modules; each hook its own tested function; 2 s CPU limit keeps it honest |
| pg_cron unavailable on Free | GitHub Actions scheduled workflow fallback |
| Free project paused before the demo | Weekly use; wake-up check the day before and the morning of |
| Groq free-tier limit hit (test set, demo) | Model rotation across 3 models; fake mode for non-AI work; optional backup provider; provisional fallback; pre-judged backup task |
| Groq changes free limits or retires a model | Model ids in `GROQ_MODELS`; backup provider; re-run the AI test set if the model changes |
| Realtime lag in raid | Same hotspot; one channel per screen; test on venue network |
| Notifications out of date (planned on device) | Re-plan on every app open and state change; inbox for server events; documented limitation |
| Scope creep near the end | Freeze as soon as core is complete; no stretch goals unless Phases 1–8 are green with time to spare |
