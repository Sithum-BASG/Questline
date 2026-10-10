# Questline — setup before handing over to Cursor (Windows + PowerShell)

Do these steps once, in order, in **PowerShell**. When the checklist at the end is all ticked, Cursor can build the project phase by phase on its own.

**What you'll end up with:** a GitHub repo with the first commit on `main` and a `develop` branch, the docs and Cursor rules in place, a working local Supabase stack, a working Groq key, and Cursor ready to start Phase 1.

**About the shell:** every command here is PowerShell (Windows PowerShell 5.1 or PowerShell 7). Run them one line at a time. The team git commands (`git phase`, `git task`, `git pr`, …) and the git hooks are shell scripts, but you never run them yourself — Git for Windows runs them with its own built-in shell when you type the `git …` command in PowerShell.

---

## A. Install the tools

### A1. With winget (PowerShell)
```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id Docker.DockerDesktop -e
winget install --id DenoLand.Deno -e
winget install --id Google.AndroidStudio -e
winget install --id Microsoft.PowerShell -e
```
- **Git for Windows:** keep the installer defaults. Line endings are handled by the repo's `.gitattributes`, so the "checkout style" choice doesn't matter.
- **PowerShell 7** (the last line) is optional but recommended: Cursor's terminal handles UTF-8 better with it, and it accepts `&&`. Everything in these docs also works in Windows PowerShell 5.1.
- **Docker Desktop** needs WSL 2. If it asks, run `wsl --install` and restart Windows. Open Docker Desktop once and wait until it says it's running.
- **Cursor:** install from cursor.com.

### A2. Flutter
1. Download the Flutter SDK zip (stable, Windows) from docs.flutter.dev/get-started and extract it to **`C:\dev\flutter`**. Don't use `Program Files` or a path with spaces.
2. Add it to your user PATH:
   ```powershell
   [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';C:\dev\flutter\bin', 'User')
   ```
3. Open Android Studio once and let it install the Android SDK. Then create an emulator (Device Manager), or plug in a phone with USB debugging on.

### A3. Supabase CLI (through Scoop)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```
The first line lets PowerShell run Scoop's installer for your user account only. It's Scoop's documented setup.

### A4. Windows settings
- **Developer Mode on:** run `start ms-settings:developers` and switch it on. Flutter needs symlinks for plugins on Windows.
- **Long paths:** `git config --global core.longpaths true`. Keep the repo at a short path such as **`C:\dev\questline`**, because Gradle builds can hit Windows' path-length limit.

### A5. Check everything
**Close and reopen PowerShell** first, so the new commands are on the PATH. Then:
```powershell
git --version
gh --version
docker info
supabase --version
deno --version
flutter doctor
flutter doctor --android-licenses
flutter devices
```
`flutter doctor` should be green for Android. Visual Studio isn't needed, so ignore that line. `flutter devices` must list your emulator or phone. `gh` needs no login.

---

## B. Accounts and keys

### B1. GitHub (repo owner = R5)
1. On R5's account create a **private, empty** repo `questline`, with no README, licence or .gitignore.
2. Settings → Collaborators → invite the other five members. **Each must accept** the invite.
3. Settings → General → Pull Requests: tick **Allow merge commits** only; untick squash and rebase.
4. Every member creates a **classic token**: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic). Use the scope **`repo`**, with an expiry a little after the submission date. Each member also notes their **no-reply email** from GitHub → Settings → Emails (`12345678+username@users.noreply.github.com`).

The default branch and branch rules come after the first commit (step C6).

### B2. Groq (the AI judge)
1. Sign up at **console.groq.com**. It's free and needs no card.
2. **API Keys → Create API key**, named `questline`. Copy it now; you can't see it again.
3. **Settings → Data Controls → turn on Zero Data Retention**, so task text sent to Groq is never stored.
4. Open **Limits** and check the free limits for `openai/gpt-oss-120b`, `openai/gpt-oss-20b` and `qwen/qwen3.8-27b`. Expect 30 requests/min, 1,000/day, 8K tokens/min and 200K tokens/day each.
5. Test the key in PowerShell. `Read-Host` keeps the key out of your command history:
   ```powershell
   $key = Read-Host 'Paste your Groq key'
   $body = @{ model = 'openai/gpt-oss-20b'; messages = @(@{ role = 'user'; content = 'Reply with the word OK' }) } | ConvertTo-Json -Depth 5
   $r = Invoke-RestMethod -Uri 'https://api.groq.com/openai/v1/chat/completions' -Method Post -Headers @{ Authorization = "Bearer $key" } -ContentType 'application/json' -Body $body
   $r.choices[0].message.content
   Remove-Variable key
   ```
   It should print `OK` or similar. A `401` means the key is wrong; a `429` means wait a minute.
6. **Optional backup provider**, only if you want a second AI source for the demo. Use an **OpenRouter** key and a free model that supports structured outputs, or Cerebras' trial credit activated in demo week. If unsure, leave it out for now. The app falls back to provisional judgements anyway.

### B3. Supabase
1. On supabase.com, create an **organisation** and invite the team.
2. Create a new project **`questline`** in region **ap-south-1 (Mumbai)** on the Free plan. Save the **database password**.
3. In Project Settings → API, note the **Project URL**, **anon key** and **project ref** (the id in the URL).
4. In Database → Extensions, enable **`pg_cron`** and **`pg_net`**. If `pg_cron` isn't available, note it; Phase 8 then uses the GitHub Actions fallback.
5. In PowerShell, run `supabase login`. It opens the browser.

### B4. Google sign-in (can wait until Phase 3)
1. In the Google Cloud console (free, no billing), create a project.
2. Set up the OAuth consent screen: External, with the team as test users.
3. Create two OAuth client IDs:
   - **Web:** its ID and secret go into Supabase Auth → Google.
   - **Android:** the package name is the `applicationId` in `app\android\app\build.gradle.kts` (or `build.gradle`), which will be `com.questline.questline`.
4. For the Android client you also need the debug SHA-1. The debug keystore exists after the first `flutter run` on Android. Get the SHA-1 with Android Studio's bundled keytool:
   ```powershell
   & "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android
   ```

Cursor's task for this is in Phase 3; it will ask you for the values.

### B5. Asset pack
Put `questline_assets.zip` (the art hand-off pack) at **`_handoff\questline_assets.zip`** in the repo folder (after step C1). `_handoff/` is git-ignored; Cursor imports the images into `app/assets/` in task T004.

---

## C. Create the repository

### C1. Extract the kit
```powershell
mkdir C:\dev\questline
Expand-Archive -Path "$HOME\Downloads\questline-repo-kit.zip" -DestinationPath C:\dev\questline
cd C:\dev\questline
Get-ChildItem -Force
```
You should see `AGENTS.md`, `docs`, `supabase`, `.cursor`, `.githooks`, `scripts`, `.gitattributes`, `.gitconfig` and `.gitignore`. Now put the asset pack in place (B5):
```powershell
mkdir _handoff
Copy-Item "$HOME\Downloads\questline_assets.zip" _handoff\
```

### C2. Fill in the team credentials
Open `docs\VERSION-CONTROL.md` §1 in Cursor or Notepad and fill in:
- the repository URL (`https://github.com/<R5-username>/questline.git`);
- for R1–R6: name, GitHub username, no-reply email and classic token.

Keep the table layout as it is, because the scripts read it. This file is git-ignored; never upload it anywhere.

### C3. Initialise git and the team tooling
```powershell
git init -b main
git remote add origin https://github.com/<R5-username>/questline.git
git -c "alias.ql-setup=!sh scripts/git/setup.sh" ql-setup
git as R5
```
- The third line is the one-time setup. It installs the team git commands, the hooks and the credential helper. The `git -c …` form makes git run the setup script with its own shell, because the `git phase`/`git task` commands don't exist until it has run. Expect `OK: Setup done.`
- `git as R5` should print `OK: Token works for origin`. If it says it couldn't reach origin, check R5's row in §1.
- The repo uses the tokens from §1, not your saved Windows Git login, so no browser login window should appear.

### C4. Create the project skeleton (task T001)
```powershell
flutter create --org com.questline --project-name questline app
supabase init
Set-Content -Path README.md -Value '# Questline'
```
If `supabase init` asks about **VS Code** settings for Deno, answer **y**: Cursor reads them, so install the Deno extension in Cursor. Answer **n** for IntelliJ.

### C5. First commit, `develop` branch
```powershell
git task T001
git add -A
git status
git commit -m 'chore(repo): set up monorepo and team git tooling'
git push -u origin main
git switch -c develop
git push -u origin develop
```
`git status` must **not** list `docs/VERSION-CONTROL.md`, `_handoff/` or any `.env` file. If one appears, stop and check `.gitignore`.

### C6. GitHub settings that need the branches
- Settings → General → **Default branch → `develop`**.
- Settings → Branches → add a rule for `main`, `develop` and `release/*` with:
  - **require a pull request before merging**;
  - force pushes blocked;
  - **required approvals 0**. You merge manually, and GitHub won't let you approve your own PRs.

### C7. Local backend config
```powershell
Copy-Item supabase\functions\.env.example supabase\functions\.env
notepad supabase\functions\.env
git check-ignore supabase/functions/.env
```
In the file, paste your Groq key after `GROQ_API_KEY=` and leave `AI_PROVIDER=fake`. Save it from Notepad or Cursor; don't write it with `echo` or `Set-Content`, which can save it as UTF-16 or with a BOM, and the functions then can't read it. The last command must print the path, which proves the file is ignored.

`AI_PROVIDER=fake` keeps the free Groq quota for when it matters. Set it to `groq` while working on or testing the AI judge (Phase 4, boss estimates) and for demos.

Then, with Docker Desktop running, start the local stack once:
```powershell
supabase start
```
The first run downloads Docker images and takes a while. It prints the local API URL and anon key; Cursor uses these in task T002.

The cloud project's secrets are set later by Cursor's Phase 4 task (`supabase secrets set AI_PROVIDER=groq GROQ_API_KEY=…`). It will ask you to run that command or confirm it.

---

## D. Prepare Cursor

1. **Open the folder:** File → Open Folder → `C:\dev\questline`. The whole repo must be the workspace so the rules load.
2. **Terminal:** press Ctrl+Shift+P → *Terminal: Select Default Profile* → **PowerShell 7** if you installed it, otherwise **Windows PowerShell**. Cursor's agent runs its commands there. The rules tell it how to write PowerShell: no bash syntax, single-quoted commit messages, files written with the editor tools.
3. **Check the rules are picked up:** Cursor Settings → Rules → Project Rules should list:
   - `questline` and `git-workflow` (always applied);
   - `flutter-app` and `supabase-backend` (applied by folder).
4. **Agent mode with terminal access.** Cursor needs to run `git`, `flutter`, `dart`, `supabase`, `deno` and `gh`, plus basic PowerShell commands such as `Get-ChildItem` and `Copy-Item`. If you use auto-run, allow those, and keep confirmation on for anything that deletes files.
5. **Commit attribution:** if your Cursor version has a setting that adds Cursor as a co-author to commits, turn it off. The commit hook strips `Co-authored-by` lines anyway, and the rules forbid them in PR descriptions.
6. **Open decisions:** skim `docs/05-BACKEND-SCHEMA.md` §13 (D1–D15). Cursor uses the proposed defaults unless you tell it otherwise.

---

## E. Hand over

**Checklist**
- [ ] All tools in A install, and the A5 checks pass in a fresh PowerShell window
- [ ] Developer Mode on; repo at a short path (`C:\dev\questline`)
- [ ] Groq key works (B2 test) and Zero Data Retention is on
- [ ] Supabase cloud project created, `supabase login` done, `supabase start` works locally
- [ ] Collaborators accepted; every member's classic token and no-reply email are in `docs/VERSION-CONTROL.md` §1
- [ ] `git as R5` prints `OK: Token works for origin`
- [ ] `main` and `develop` exist on GitHub; default branch is `develop`; branch rules set; merge commits only
- [ ] `supabase\functions\.env` exists with the Groq key and is git-ignored
- [ ] `_handoff\questline_assets.zip` is in place
- [ ] Cursor's default terminal is PowerShell and it shows the 4 project rules

**First prompt to Cursor**
> Read @docs/README.md and @docs/VERSION-CONTROL.md. Then do Phase 1 following VERSION-CONTROL.md §3: for each task in ID order, implement its step from @docs/06-IMPLEMENTATION-PLAN.md using the docs it cites, commit it with `git task <ID>`, and when the phase is done open the phase PR and stop. The terminal is PowerShell.

**The loop after that**
1. Cursor finishes the phase, opens one PR and stops.
2. Review it on GitHub and merge with **Create a merge commit**.
3. Tell Cursor: *"Phase N is merged. Continue with Phase N+1."*
4. After Phases 1, 2, 4, 8 and 13 you can also ask: *"Open the milestone PR for M0"* (then M1, M2 and so on). Merge it, and Cursor tags `main`.

**If something stops Cursor:** it will say why: a hook, a missing key, a failing test or an open PR. The fixes for common cases, including Windows-specific ones, are in `docs/VERSION-CONTROL.md` §10.

---

## Another Windows machine later

1. Clone with any member's token, then remove the token from the saved URL. `-c credential.helper=` stops Windows' credential manager from saving the token:
   ```powershell
   git -c credential.helper= clone https://<username>:<token>@github.com/<R5-username>/questline.git C:\dev\questline
   cd C:\dev\questline
   git remote set-url origin https://github.com/<R5-username>/questline.git
   ```
2. Copy the filled-in `VERSION-CONTROL.md` into `docs\`. It isn't in git.
3. Run the setup command from C3: `git -c "alias.ql-setup=!sh scripts/git/setup.sh" ql-setup`.
4. Create `supabase\functions\.env` as in C7.
