# Questline — instructions for AI agents

Questline is a Flutter + Supabase gamified productivity app for students (free platforms only). Before doing anything:

1. **Project rules:** `.cursor/rules/questline.mdc` (always), plus `flutter-app.mdc` for `app/` and `supabase-backend.mdc` for `supabase/` and `scripts/`.
2. **Git rules:** `.cursor/rules/git-workflow.mdc` and the runbook `docs/VERSION-CONTROL.md` §3. Work phase by phase; commit each task under its owner with `git task <ID>`; one PR per phase, then stop. Do not add co-authored-by or any AI attribution.
3. **Specs:** `docs/README.md` lists every document, what it's for and which one wins when they disagree.

Hard rules in one line each:
- The server owns game state; the app only writes the column grants in `docs/05-BACKEND-SCHEMA.md` §3.
- Fixed stack, no Firebase, no new packages without asking.
- Every schema change is a migration with pgTAP tests; every Edge Function query filters by the JWT user id.
- No hard-coded game numbers (`game_config`) or design values (`core/theme/`).
- Task titles never reach other users; only task text goes to Groq (the AI provider); automated tests use the fake provider and never call Groq.
- Never print, copy or commit the tokens in `docs/VERSION-CONTROL.md`.
- The terminal is PowerShell on Windows: no bash syntax, single-quoted commit messages, files created with the editor tools (see `git-workflow.mdc`).
