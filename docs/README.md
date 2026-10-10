# Questline docs

Everything needed to build Questline lives in this folder. Cursor loads the rules in `.cursor/rules/` automatically; these docs are what those rules point to.

## What's here

| File | What it is | Read it when |
|---|---|---|
| `00-PROJECT-OVERVIEW.md` | The full game design: idea, every rule and number, theme, onboarding story, privacy, notifications list, screens, **AI prompts (§23)**, art and asset ids (§24), demo plan, glossary | Anything about *how the game works* or *what something looks like* |
| `01-PRD.md` | Product requirements: Must have / Nice to have / out of scope, user stories, every number in testable form (§6), success metrics | Before adding or changing a feature |
| `02-TRD.md` | Technical requirements: fixed stack, packages, repo layout, conventions, Edge Function contract, AI provider (Groq, fake mode), notifications without push, secrets | Before writing any code |
| `03-APP-FLOW.md` | Navigation, route map, auth/onboarding flow, Home layout, user journeys, focus lifecycle, empty/error states, settings | Building screens and navigation |
| `04-UI-UX-BRIEF.md` | Colour/type/spacing tokens, surfaces, game-visual rules, component library, KEY screens, motion, copy, accessibility | Building any UI |
| `05-BACKEND-SCHEMA.md` | Tables, column grants, RLS, realtime, indexes, every Edge Function action, cron jobs, `game_config` keys, catalog seed, game formulas + tests, AI response schemas, open decisions D1–D15 | Any backend work, and whenever the app reads data |
| `06-IMPLEMENTATION-PLAN.md` | Build order: Phases 0–16, each step with its *Done when* | Choosing what to do next |
| `SETUP.md` | One-time setup on Windows + PowerShell before handing over to Cursor, with a checklist and the first prompt | Once, at the start |
| `VERSION-CONTROL.md` | Git runbook: team credentials (§1), commands, agent protocol, branching, commit rules, phases (§8) and task owners (§9) | Every commit and PR. **Git-ignored — holds tokens** |

**Precedence:** technology → `02-TRD.md` + `05-BACKEND-SCHEMA.md` (the overview's Firebase §22 is superseded) · game rules and numbers → `00-PROJECT-OVERVIEW.md` · UI specifics → `04-UI-UX-BRIEF.md` · names → exactly as `05-BACKEND-SCHEMA.md`.

## Reading order for a new chat
1. `.cursor/rules/questline.mdc` (automatic) → `01-PRD.md` → `02-TRD.md`
2. The phase you're on in `06-IMPLEMENTATION-PLAN.md` and its tasks in `VERSION-CONTROL.md` §9
3. Whatever the step cites: `05-BACKEND-SCHEMA.md` sections for backend, `03-APP-FLOW.md` + `04-UI-UX-BRIEF.md` for screens, `00-PROJECT-OVERVIEW.md` for rules, prompts and art

## First-time setup

Follow **`SETUP.md`** once before handing the repo to Cursor: tools, GitHub/Groq/Supabase accounts and keys, extracting this kit, filling in `VERSION-CONTROL.md` §1, the first commit (T001), local `supabase/functions/.env`, Cursor settings, and the hand-over checklist.

Other members' machines (PowerShell): clone, put the filled-in `docs/VERSION-CONTROL.md` in place (it isn't in git), `Copy-Item supabase\functions\.env.example supabase\functions\.env` and fill it in, then run `git -c "alias.ql-setup=!sh scripts/git/setup.sh" ql-setup` (SETUP.md §C3 explains it).

## Starting work in Cursor

Open the repo in Cursor and ask, for example:

> Do Phase 1 following @docs/VERSION-CONTROL.md §3. For each task, implement its step from @docs/06-IMPLEMENTATION-PLAN.md using the docs it cites.

Cursor works through the phase's tasks (each committed under its owner), opens one PR with a short plain description, and stops. Review and merge it on GitHub (**Create a merge commit**), then tell Cursor it's merged and to continue with the next phase.

After phases 1, 2, 4, 8 and 13, ask for the milestone PR (`VERSION-CONTROL.md` §5.2).
