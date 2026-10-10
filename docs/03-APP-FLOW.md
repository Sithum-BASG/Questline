# 03 · App Flow — Navigation and User Journeys

**Product:** Questline · **Last updated:** 9 Oct 2026
**Read with:** `01-PRD.md` (rules), `04-UI-UX-BRIEF.md` (look), `05-BACKEND-SCHEMA.md` §6 (server actions named below).

> **For the AI agent:** Every screen below has a route. Implement routes exactly as listed in `app/lib/router.dart` so screens connect. When a screen calls the server, the **action** name is given in `code`; it's sent to the Edge Function listed for it in `05-BACKEND-SCHEMA.md` §6 (e.g. `endSession` → function `sessions`). Every screen must handle loading, empty and error states as listed in §7.

---

## 1. Navigation structure

- **Bottom tab bar, 5 tabs** (floating white bar, see UI brief): **Home · Quests · Bosses · Social · Hero**. Implemented as a go_router `StatefulShellRoute` so each tab keeps its own stack.
- **Full-screen overlays** (above the tab bar, reachable from anywhere): Focus session, Session complete, Reward moments, Chest opening, Weekly recap, Onboarding story.
- **Bottom sheets** for quick input: Add task, AI judgement card, Challenge, Start focus picker, Invite.
- Android back / iOS swipe: pops the current stack; inside a running focus session it opens the "End session?" dialog instead of leaving.

---

## 2. Route map

| Route | Screen | KEY | Notes |
|---|---|---|---|
| `/welcome` | Welcome and sign-in | | Google or email |
| `/onboarding/character` | Body type A/B + name | | |
| `/onboarding/story` | 7-card story | | Skip on every card; "Begin" on card 7 |
| `/onboarding/study` | Study context (optional) | | Skip allowed |
| `/onboarding/first-task` | First task + judgement card + boss toggle | | Reuses judgement card |
| `/home` | Home | ★ | Tab 1 |
| `/quests` | Task list: Today / Upcoming / Done, stat filter | | Tab 2 |
| `/quests/new` | Add task sheet → judgement card | ★ (card) | |
| `/quests/:taskId` | Task detail | | |
| `/quests/:taskId/challenge` | Challenge sheet | | One per task |
| `/focus/start` | Start-focus picker sheet | | From Home button or a task |
| `/focus/:sessionId` | Focus session (focus / activity variants) | ★ | Overlay |
| `/focus/:sessionId/complete` | Session complete, XP breakdown | | Overlay, then reward queue |
| `/bosses` | Bosses list (solo + raids, by deadline) | | Tab 3 |
| `/bosses/new` | Create boss | | AI estimate + name |
| `/bosses/:bossId` | Boss detail: HP, tasks, submit | ★ | |
| `/bosses/:bossId/result` | Boss result: defeated / escaped | | |
| `/raids/new` | Start raid: guild fight or party | | |
| `/raids/:raidId/invite` | Invite: code, QR, link | | |
| `/raids/join` | Join party: code entry or QR scan | | `?code=` prefill |
| `/raids/:raidId` | Raid detail: live HP, members, ticker | ★ | Real-time |
| `/raids/:raidId/results` | Results: contribution, MVP, add friend | | |
| `/social` | Leaderboard (default sub-tab) | ★ | Tab 4; sub-tabs Leaderboard / Feed / Guild / Friends |
| `/social/feed` | Activity feed | | |
| `/social/friends` | Friends list + add friend | | Username, code, QR, link |
| `/social/friends/:uid` | Friend profile | | Respects privacy |
| `/social/guild` | Guild home | | Or "create or join" if none |
| `/social/guild/new` | Create or join guild | | |
| `/hero` | Profile: stage, radar 30/7, pinned badges, title | ★ | Tab 5 |
| `/hero/gear` | Gear and attunement | | |
| `/hero/wardrobe` | Skins, backgrounds, frames | | |
| `/hero/achievements` | Badges and titles | | |
| `/hero/inventory` | Consumables | | |
| `/hero/level-road` | Rewards for levels 1–50 | ★ | |
| `/chests` | Chest screen: rates, pity counter, open | | From Hero and Home |
| `/chests/open` | Chest opening and reveal | ★ | Overlay |
| `/reward` | Reward moment template | ★ | Overlay; `type` = level_up, loot, boss_defeated, badge, streak |
| `/recap/:weekId` | Weekly recap cards | | Overlay |
| `/inbox` | Inbox: guild fights, raid results, weekly results, friend requests | | Bell icon in the Home top bar, unread badge |
| `/settings` | Settings | | From Hero (gear icon) |
| `/settings/demo` | Hidden demo mode | | Tap app version 7 times; allow-listed only |

**Deep links** (`app_links`): `questline://join/{code}` → `/raids/join?code={code}`; `questline://friend/{friendCode}` → add-friend confirm; `questline://auth-callback` for email auth. Shared invite text always includes the plain code too, so it works even where custom-scheme links aren't clickable. If signed out, store the link and apply it after onboarding. (An https link would need web hosting; GitHub Pages could do it later for free.)

---

## 3. Entry point and auth flow

```
App start
 ├─ not signed in ───────────────────────────────► /welcome
 ├─ signed in, onboarding not finished ──────────► resume at player_state.onboarding_step
 └─ signed in, onboarding finished ──────────────► /home
```

**Onboarding (~3 minutes, solo-first):**

| Step | Route | What happens | Server |
|---|---|---|---|
| 1 | `/welcome` | One sentence about the app; Google or email | Supabase Auth; `completeOnboardingStep('signed_in', {timezone})` creates `player_state` + `user_settings` |
| 2 | `/onboarding/character` | Pick body type A/B, name the character; starter skin appears on the stage | `completeOnboardingStep('character', {bodyType, displayName})` creates `profiles` + starter items → +20 starter XP |
| 2b | `/onboarding/story` | 7 cards, images follow body type, "{Name}" in card 7, Skip on every card | none |
| 3 | `/onboarding/study` | "What are you studying?" (optional, private; note that it's sent to our AI provider, Groq, with tasks) | client updates `user_settings.study_context` |
| 4 | `/onboarding/first-task` | Type a real task → judgement card. Toggle "Part of an assignment or exam with a deadline?" → creates a boss with this as its first task | `judgeTask`; optional `createBoss`; `completeOnboardingStep('first_task')` → +20 |
| 5 | `/focus/:id` | First focus session, **5-minute minimum** during onboarding | `startSession`, `endSession`, then `completeOnboardingStep('first_session')` → +40 starter XP + 1 free chest |
| 6 | `/reward?type=level_up` → `/chests/open` | Level up to 2, unlock frame, open free chest | level-up from the step result + `openChest({useFreeChest: true})` |
| 7 | `/home` | Home with first card "Got a deadline coming up? Turn it into a boss." + optional "Add friends" card | `completeOnboardingStep('done')` |

Permissions: **notifications** asked after the first session ("Want a reminder before your boss heals?"); **camera** only when the user taps "Scan QR".

**Redirects**
- After sign-in → resume onboarding or `/home`.
- After sign-out → `/welcome`.
- After `deleteAccount` → `/welcome` with a confirmation snackbar.
- After saving a task → back to where the user started (Home or Quests), task highlighted.
- After `endSession` → `/focus/:id/complete` → reward queue → back to the screen that started the session.
- After `submitBoss` → `/bosses/:id/result` → reward queue → `/bosses`.

---

## 4. Home (KEY) layout, top to bottom

1. Top bar: greeting + inbox bell with unread badge (→ `/inbox`) (the small avatar from the mockup is dropped).
2. **Character stage card** (skin over background with frame glow; the character breaks out of the top of the card).
3. XP bar with "next reward" label ("2 levels until the Epic Weapon") → tap opens `/hero/level-road`.
4. Three stat tiles: **Streak** (ember), **This week** XP, **Rank this week** (label "this week").
5. **Closest boss** card (only one: name, HP bar in rose, time left) → `/bosses/:id`. Empty: "Got a deadline coming up? Turn it into a boss."
6. **Today's top tasks** (max 3) with play buttons → `/focus/start?taskId=`.
7. Large **Start focus** primary button → `/focus/start`.
8. ~100 px bottom padding so content clears the floating tab bar.

Social is offered at natural moments only: after the first chest, when creating a boss ("Fight it with friends?"), and at level 5.

---

## 5. Core user journeys

### J1 · Add a task and focus on it
1. Quests tab (or Home) → **+** → `/quests/new` sheet: title, optional notes, optional due date, optional parent boss.
2. Tap **Judge** → client creates a `draft` task → `judgeTask(taskId)` → **judgement card** shows: stat chip, difficulty, ~minutes, XP preview, "Why: …".
   - User can change the stat chip (free).
   - "Disagree?" → `/quests/:id/challenge` → one sentence → `challengeTask` → card updates, marked final.
   - `too_big` → card shows "This looks bigger than one sitting" with **Split** (back to edit) and **Make it a boss** (→ `/bosses/new` prefilled).
   - AI down → card shows "Provisional rating, we'll re-check it soon" at difficulty 3.
3. **Save** → status `open` → back to list.
4. Tap play → `/focus/start` (mode toggle shown only for Vitality/Charisma: Focus / Activity; Focus Potion toggle if owned and task estimate ≥ 25 min) → `startSession` → `/focus/:sessionId`.
5. Timer runs (server start time). Leaving the app shows a local notification "Return within 30 seconds to keep your session". Back within 30 s → continues. Away > 30 s → session breaks (see §6).
6. **Finish** → `endSession` → `/focus/:id/complete`: verified minutes, base XP, multipliers, timing modifier, boosts, raw vs final, boss damage, streak status.
7. Reward queue plays in order: level up → loot from level → badge → streak milestone. Each is a `/reward` overlay with **Claim**.

Alternative: swipe a task → **Tick off** → confirm "Ticking off earns 50% and deals no boss damage" → `tickTask`.

### J2 · Turn a deadline into a boss and beat it
1. Bosses tab → **New boss** → title, type (exam / assignment / project), deadline, description → `createBoss` (AI estimate + name) → preview: name, tier art, hours slider 2–40, HP, loot by tier, warning if deadline < 48 h ("no coins for this boss").
2. **Summon** → `/bosses/:id`: HP bar, tasks under the boss, time left, "Add task" (J1 with parent prefilled).
3. Each focus session on a boss task deals damage (shown on Session complete and in the boss HP).
4. Days with no work: boss heals 3% (rest days and pause exempt); detail shows "Healed 3% yesterday".
5. HP hits 0 early → status **Staggered** ("Submit to finish it").
6. **Mark submitted** (confirm dialog) → `submitBoss` → `/bosses/:id/result` (defeated, full or half loot) → reward queue.
7. Deadline passes unsubmitted → scheduled job sets **escaped** → next open shows the result screen once (loot lost, −100 coins, "XP you earned is kept").

### J3 · Party raid with classmates
1. Bosses tab → **Start raid** → `/raids/new`: choose **Guild fight** (if in a guild) or **Party** → title, deadline, participants count → `createRaid` (AI per-person hours) → confirm.
2. Party → `/raids/:id/invite`: 6-character code, QR, share link.
3. Classmate taps link or scans QR → `/raids/join?code=` → preview (raid name, members, deadline) → **Join** → `joinRaid`.
4. `/raids/:id` (live): HP bar, member cards with "focusing now", damage ticker ("Sithum hit for 45"). One Supabase Realtime channel subscribed to changes on `raids` (this id), `raid_members` and inserts on `raid_events` (filtered by `raid_id`), plus `presence` rows for members; last 20 events loaded on open.
5. At the deadline (scheduled job) → `/raids/:id/results`: Victory / Narrow win / Escape, per-member check marks (creator sees exact numbers), MVP + special item roll, **Add as friend** for non-friends.

### J4 · Open a chest
Hero → **Chests** → `/chests`: coin balance, price 500, rates table, "Legendary guaranteed in N chests" → **Open** → `openChest` → `/chests/open` reveal (rarity burst colour, item, "New!" or duplicate refund) → **Equip now** (cosmetics) or **Done**.

### J5 · Weekly reset
Monday 08:00 local notification "Weekly results are in" (and an inbox entry with the actual results) → `/recap/:weekId` cards: total raw XP, stat split, best day, bosses beaten, rank and rewards → last card "Claim" (rewards are already credited server-side; claim just plays the reward moment).

---

## 6. Focus session lifecycle

| Event | Client | Server |
|---|---|---|
| Start | `startSession({taskId, mode, usePotion})`; then updates own `presence` row to `focusing` (unless appear offline) and heartbeats `last_seen` every 60 s | Creates the `sessions` row with server `started_at` |
| App backgrounded (focus mode) | Record `leftAt`; schedule local notification at once; start 30 s timer | — |
| Returned ≤ 30 s | Record interruption `{leftAt, returnedAt}` | — |
| Away > 30 s | Session marked broken locally; on return show "Session ended" screen | `endSession({sessionId, interruptions, broken: true})` |
| Activity mode | Backgrounding is allowed; no interruption tracking | Minutes = server elapsed, capped 1.0× estimate |
| Finish | `endSession({sessionId, interruptions})` | Verified minutes = (serverEnd − serverStart) − interruptions; full pipeline |
| Finish / break | Sets own `presence` back to `idle` | — |
| App killed | Heartbeat stops; friends stop seeing "focusing" after ~2 min (`presence_stale_seconds`) | Stale `active` sessions older than 3× estimate are closed as broken by `cron-deadlines` |

Persistent notification shows the running timer for the whole session.

---

## 7. Empty, loading and error states

| Screen | Empty | Error / special |
|---|---|---|
| Home | No tasks: "Add your first quest"; no boss: boss prompt card | Offline: cached data + small "Offline" pill |
| Quests | Per tab: "Nothing due today" / "No upcoming quests" / "Nothing done yet" | Provisional tasks show a small clock icon |
| Judgement card | — | AI timeout → provisional card; daily AI limit reached → "AI judge resting until tomorrow; saved as provisional" |
| Bosses | "No bosses yet. Turn a deadline into one." | Limit 15 active → disable New with explanation |
| Raid detail | Only creator joined: invite card | Lost realtime connection → "Reconnecting…" banner |
| Leaderboard | < 4 friends: own weekly XP + invite card with friend code | Below 500 raw XP: "Reach 500 XP to qualify for rewards" |
| Feed | "When friends level up or beat bosses, it shows here" | — |
| Guild | "Create or join a guild" | Guild full (10) on join |
| Achievements | Locked badges in greyscale with progress | — |
| Inventory | "No consumables yet. Find them in chests." | At holding limit: item shows "Max" |
| Chests | Not enough coins: button disabled with "Need N more coins" | — |
| Inbox | "Nothing new" | — |
| Any server action | — | Map error codes to friendly text + Retry; never show raw exception text |
| Supabase project paused (free plan) | — | Generic "Server is waking up, try again in a minute" for connection errors |

Loading: skeletons matching card shapes (no spinners on full screens); buttons show an inline spinner while a server action runs and are disabled to prevent double taps.

## 7b. Notifications on the device

`core/notifications/notification_planner.dart` re-plans the next 7 days of local notifications on app start, resume, after `endSession`/`tickTask`, after creating/submitting a boss or joining a raid, and after settings change. It applies category toggles, quiet hours and the 2-per-day cap (priority: boss warning > raid result > streak > weekly > comeback > boss healed > Sunday nudge). Every notification's payload is a route (e.g. `/bosses/{id}`), opened on tap. Mapping of each notification is in `02-TRD.md` §8.

---

## 8. Settings

Notifications (per category: bosses, streak, raids, weekly, leaderboard nudge), quiet hours (default 23:00–07:00), privacy (appear offline, show boss names in feed, hide stat radar), rest day (weekday picker), pause mode (start/end, shows days left this month of 7), sign out, delete account (two-step confirm → `deleteAccount`). Hidden: demo mode (tap version 7×; visible only if the uid is allow-listed).
