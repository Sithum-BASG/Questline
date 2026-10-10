# 01 · PRD — Product Requirements Document

**Product:** Questline
**Version:** 1.0 (course release)
**Last updated:** 10 Oct 2026 (v3: aligned with the phase-by-phase build)
**Source of truth:** `00-PROJECT-OVERVIEW.md` for game rules and numbers — if this file and the overview disagree on a rule or number, the overview wins; fix this file. For technology (backend, database, notifications delivery), `02-TRD.md` and `05-BACKEND-SCHEMA.md` win.

> **For the AI agent:** Read this file first. It defines *what* to build and *what not* to build. Never add a feature that isn't in "Must have" without being asked. Every number here is a starting value that lives in the `game_config` table (see `05-BACKEND-SCHEMA.md` §8), so never hard-code a game number in UI code. The backend is **Supabase** on free plans only (see `02-TRD.md`); where the project overview mentions Firebase, the TRD and Backend Schema win.

---

## 1. App name, tagline, problem

- **Name:** Questline
- **Tagline:** Your deadlines were always monsters. Now you can fight back.
- **One-liner:** A student productivity app where real tasks earn XP for an RPG character. An AI judges each task, deadlines become bosses, and friends compete and raid together.

**Problem.** University students procrastinate, and most productivity apps feel like chores. Existing gamified to-do apps (Habitica and similar) reward ticking checkboxes, so users farm XP with trivial tasks and the game stops meaning anything.

**Who feels it.** Undergraduates juggling several modules, group assignments and deadlines at once.

---

## 2. Target user

**Primary persona: "Third-year IT student."** 20–23, carries 4–5 modules, each with coursework and an exam, plus at least one group project. Uses their phone constantly, already plays mobile games, and has tried a to-do app and abandoned it within two weeks. Studies best in bursts and responds to visible progress and friendly competition with classmates.

**Secondary persona: "Group project member."** Someone outside the user's friend group who joins a single raid via a code or QR to fight a shared group-assignment deadline.

---

## 3. Core value proposition

1. **The AI judges effort**, so trivial tasks can't farm XP.
2. **XP comes mainly from verified focus time**, not from tapping a checkbox.
3. **Deadlines are bosses** with HP equal to the estimated work, and they can be fought together in real time.
4. **The leaderboard uses raw effort** (before gear boosts), so it stays fair.

---

## 4. Core loop

1. Add a task (or a deadline, which becomes a boss).
2. The AI judges it: stat, difficulty, estimated minutes, one-line reason.
3. Do the work in a focus session (or activity mode for Vitality and Charisma).
4. Earn XP: stats grow, the character levels up, rewards unlock.
5. Damage bosses if the task belongs to one. Submit the assignment to defeat it.
6. Compete and cooperate: weekly leaderboard with friends; raids with a guild or party.
7. Spend coins on chests for cosmetics and consumables.

---

## 5. Features

### 5.1 Must have (core — ships in v1)

| # | Feature | Summary | Detail |
|---|---|---|---|
| F1 | Auth + onboarding | Google or email sign-in, body type A/B, character name, 7-card story, optional study context, first judged task, first 5-min session, level up to 2, free chest | `03-APP-FLOW.md` §3 |
| F2 | Tasks + AI judge | The AI judge (Groq, `02-TRD.md` §7) returns stat, difficulty 1–5, minutes 5–180, too_big, reason. Shown on a judgement card before saving. Stat editable; difficulty/minutes only via one challenge. Provisional fallback when AI is down. ~50 calls/user/day | §6.1 |
| F3 | Focus sessions | Verified focus (foreground, 30 s grace), activity mode (Vitality/Charisma, phone may lock), tick-off without session | §6.2 |
| F4 | XP engine | Base XP = minutes × difficulty multiplier, completion share, timing modifiers, personal boosts. Raw vs final XP | §6.2 |
| F5 | Stats + radar | 4 fixed stats, radar of rolling 30 days with 7-day toggle | §6.3 |
| F6 | Levels 1–50 + level road | Level curve, reward on every level 2–10, then gear/cosmetic/coins rhythm | §6.4 |
| F7 | Gear + attunement | 3 slots, 10 items from levelling, boost cap 25%, re-attune 200 coins | §6.5 |
| F8 | Cosmetics + wardrobe | Skins (A/B), backgrounds, frames, titles | §6.6 |
| F9 | Coins + chests | 500-coin chest, server-side roll, unowned-first, Legendary pity at 30 | §6.6 |
| F10 | Consumables + inventory | Streak Shield, Focus Potion, Reschedule Scroll, Free Chest | §6.7 |
| F11 | Streaks | 40 raw XP/day, 4 a.m. boundary, rest day, shields, milestones | §6.8 |
| F12 | Penalties + safeguards | Late/reschedule penalties, rest day, pause mode, comeback 2× | §6.9 |
| F13 | Solo deadline bosses | AI estimate + name, HP = minutes, tiers, damage, healing, submit, escape | §6.10 |
| F14 | Guilds, parties, raids | One raid system; guild (≤10) or party (2–8, join by code/QR/link); live HP and ticker | §6.11 |
| F15 | Friends + leaderboard + feed | Friends-only weekly raw-XP board, rank rewards, activity feed | §6.12 |
| F16 | Achievements | 8 badges × 3 tiers, titles, pin 3 badges | §6.13 |
| F17 | Weekly recap | Story-style swipe cards | `03-APP-FLOW.md` |
| F18 | Notifications | On-device notifications (max 2/day, quiet hours, categories toggleable) + in-app inbox | §6.14 |
| F19 | Privacy settings | Appear offline, show boss names, hide radar; rules-enforced | §6.15 |
| F20 | Hidden demo mode | Allow-listed accounts only: 30 s counts as 5 min, forced chest drop | §6.16 |

### 5.2 Nice to have (stretch — only if core is stable, in this order)

1. AI personal calibration (no stretch planned; reconsider only if Phases 1–8 are done with time to spare): median actual/estimate ratio over last 20 verified tasks, clamped 0.5–2.0, passed to the prompt.
2. Voice brain dump (speak tasks, AI splits them).
3. Seasons and weekly leagues.
4. Deadline extraction from PDF module outlines.
5. Home-screen widget.
6. Health Connect / HealthKit verification for Vitality.

### 5.3 Out of scope for v1 (do not build)

- Real money, in-app purchases, buying coins. **Never.**
- Stat gear in chests. Mythic gear. Trading between players.
- Dark mode. Skin-tone, hairstyle or separate-clothing customisation.
- Gear drawn on the character body. Multiple poses per skin.
- Losing levels, gear or cosmetics as a penalty.
- Sharing task titles or details with anyone.
- Web or desktop clients.
- Push notifications for friends' level-ups or chest drops (feed only).

---

## 6. Feature rules (the numbers)

### 6.1 AI judge
- Output: `stat` (intellect | vitality | craft | charisma), `difficulty` 1–5 (effort per minute, not length), `estimated_minutes` 5–180, `too_big` (> 180 min → suggest split or boss), `reason` (≤ 20 words, no XP mention).
- Stat: user may change freely. Difficulty and minutes: only via **one challenge** per task (one sentence of context, re-judged from scratch, final, can go up or down).
- Prompt injection inside task text is ignored. Server validates and clamps.
- AI unavailable / invalid / timeout (~8 s): save as **provisional** (difficulty 3, user's estimate or 30 min), re-judge in background.
- Only task text and optional study context are sent to the AI provider (Groq, zero data retention). No names or emails.

### 6.2 XP
| Difficulty | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Multiplier | 0.5 | 0.75 | 1.0 | 1.3 | 1.6 |

| Completion mode | Minutes used | Share |
|---|---|---|
| Focus session (foreground, 30 s grace) | Verified minutes, capped at 1.5× estimate | 100% |
| Activity mode (Vitality, Charisma only) | Actual minutes, capped at 1.0× estimate | 80% |
| Ticked off | AI estimate | 50% |

- Timing modifiers (after base): on-time dated task +10%; late −10% per overdue day, floor 50%; rescheduled −20% unless a Reschedule Scroll is used.
- **Raw XP** = base × share × timing. Used for leaderboard, weekly target, guild quest, streak minimum.
- **Final XP** = raw + personal boosts (gear, Focus Potion 1.5×, comeback 2×, Legendary passives). Used for levelling.
- Verified focus beyond 8 hours/day earns no XP.
- Worked example: difficulty 4, 60-min estimate, 60 verified minutes, on time → 60 × 1.3 × 1.1 = **86 XP**. Ticked off → 60 × 1.3 × 0.5 = **39 XP**.

### 6.3 Stats
Intellect (learning, revision, research, essays and reports) · Vitality (exercise, sport, sleep routine, healthy cooking, physical chores) · Craft (making and building incl. coursework coding and design) · Charisma (meetings, calls, thoughtful messages, events, societies, helping someone). Mixed tasks use the stat that takes most of the time. Radar = XP split over rolling 30 days (default) with 7-day toggle.

### 6.4 Levels
- XP for the next level = `80 + 5.5 × (level − 1)^1.4`, rounded to nearest 10. Totals: L10 1,110 · L25 6,390 · L50 29,360.
- Target pace (~750 raw XP/week): L2 in onboarding, L10 ~1.5 weeks, L25 ~8–9 weeks, L50 ~8–9 months.
- Rewards: L2–10 every level; L11–50 gear every 5 levels, cosmetic on most even levels, coins on most odd levels. **The full level table in the overview §8 is authoritative** and is seeded into the `level_rewards` table (`05-BACKEND-SCHEMA.md` §9).
- Cosmetic rarity by band: Common L2–10, Rare L11–25, Epic L26–50. Legendary/Mythic cosmetics only from chests. Legendary gear only from levelling.

### 6.5 Gear
- Slots: weapon, armour, accessory. Boost by rarity: Common 3%, Rare 5%, Epic 7%, Legendary 9% + passive. Per-stat cap 25%.
- L5 Common weapon · L10 Common armour · L15 Rare accessory · L20 Rare weapon · L25 Rare armour · L30 Epic accessory · L35 Epic weapon · L40 Epic armour · L45 Legendary accessory (**Deep Focus**: 45+ min sessions +10% XP) · L50 Legendary weapon (**Boss Slayer**: +20% boss damage).
- Attunement: player picks the stat on unlock; re-attune costs 200 coins.

### 6.6 Coins and chests
- Chest = 500 coins. Contents: cosmetics, coin pouches, consumables. **Never stat gear.** Rolled on the server. Rates shown in app.
- Rarity: Common 55%, Rare 30%, Epic 12%, Legendary 2.5%, Mythic 0.5%. Legendary guaranteed within 30 chests; Mythic pure luck.
- Roll: rarity → an unowned item of that rarity. Duplicate refund only once the rarity is fully owned (Rare 100, Epic 200, Legendary 400, Mythic 500).
- Pools: Common = coin pouches (50/100/200/500 at 60/30/9/1%). Rare = 50% unowned Rare cosmetic (2 frames, 2 backgrounds) / 50% consumable (Shield 40, Potion 35, Scroll 25); consumable at holding limit → 100 coins. Epic = 3 frames, 2 backgrounds. Legendary = 2 skins, 2 backgrounds, 2 frames. Mythic = one set (skin + background + frame together).
- Coin sources: see `00-PROJECT-OVERVIEW.md` §10. Coin uses: chests (500), re-attune (200).

### 6.7 Consumables
| Item | Effect | Hold max |
|---|---|---|
| Streak Shield | Covers one missed day, auto, not two in a row | 2 |
| Focus Potion | Next verified 25+ min session earns 1.5× (personal only) | 3 |
| Reschedule Scroll | Move a due date without the 20% penalty | no limit |
| Free Chest | One standard chest, counts toward pity | no limit |

### 6.8 Streaks
Daily minimum 40 raw XP; day boundary 4 a.m. local; one chosen rest day/week (doesn't break or add); milestones 7 d = 100 coins, 14 d = 150 coins, 30 d = free chest, 60 d = "Unbroken" frame, 100 d = "Unbroken" title.

### 6.9 Penalties and safeguards
Penalties are small, capped, shown once and recoverable. **Players never lose levels, gear or cosmetics.** Pause mode (illness/holiday) freezes streaks and bosses, max 7 days/month. Comeback bonus 2× on first session after 3+ inactive days.

### 6.10 Deadline bosses
- AI estimates total hours (2–40, user-adjustable) and names the boss. HP = hours × 60.
- Tiers / defeat coins: Minion < 4 h 100 · Brute 4–12 h 150 · Warlord 12–25 h 200 · Titan 25 h+ 300. Weekly boss-coin cap ~600; no coins if created < 48 h before deadline.
- 1 verified focus minute = 1 damage (+20% Boss Slayer). Ticked tasks deal no damage.
- Solo defeat = mark submitted before deadline. Full loot at ≥ 75% HP dealt, half otherwise. 0 HP before submission = "staggered".
- Heals 3% max HP per day with no work (rest days and pause exempt). Escape = loot lost, −100 coins (floor 0), XP kept.
- Max 15 active boss fights total (solo + raids).

### 6.11 Guilds, parties, raids
- Guild: ≤ 10 members, one per user, members are friends, preset emblem, weekly quest (e.g. 5,000 raw XP; contributors with 200+ XP get coins).
- Party: 2–8, one raid, anyone with code/QR/link (account required), dissolves after, results offer "Add as friend".
- Raid HP = AI per-person estimate × participants. Victory (0 HP before deadline) full loot + 25%; Narrow win (75–99%) half; Escape (< 75%) none.
- Loot per person, only if ≥ 50% of fair share (HP ÷ participants). Below share: no loot and −100 coins on escape. MVP: 30% chance at a special item. Creator sees exact damage; others see a "pulled their weight" check. Leaving: damage stays, loot forfeited.

### 6.12 Friends, leaderboard, feed
- Friends via username, friend code, QR, link, party results.
- Weekly leaderboard: friends only, raw XP, weekly reset. Rank rewards need ≥ 4 active friends and the 500 raw XP weekly target. 1st 300 coins + 50% special item; 2nd 200 + 30%; 3rd 150 + 20%. Special pool: Shield 40, Potion 35, Scroll 20, Free Chest 5.
- Feed: level-ups, boss/raid wins, Epic+ chest drops, badges. Never task titles.

### 6.13 Achievements
8 badges × 3 tiers: Deep Worker (focus hours 10/50/200) · Boss Hunter (bosses 1/10/40) · Team Player (raids won 1/5/20) · Unbroken (streak 7/30/100) · Balanced (weeks with every stat ≥ 15% of 30-day XP 1/4/12) · Early Bird (sessions before 8 a.m. 5/25/100) · Steady Pace (weeks with sessions on 5+ days 1/4/12) · Punctual (on-time dated tasks 10/50/200). Rewards: Tier I 50, II 100, III 200 coins + title. Titles also from L3, L25, L32, L46, L50 and 10× raid MVP. Pin up to 3 badges.

### 6.14 Notifications
Max 2 notifications/day (excluding focus-session alerts), quiet hours 11 p.m.–7 a.m. default, no guilt messages, one comeback message after 3 inactive days. Full list in `00-PROJECT-OVERVIEW.md` §20 (its "Build" note about FCM is superseded by `02-TRD.md` §8).
**v1 delivery (free platforms):** notifications are scheduled on the phone from what the app knows (deadlines, streak, weekly reset); events only the server knows at that moment (guild fight started, raid result, weekly results, friend requests) also appear in an **in-app inbox**. There's no server push in v1, so "guild fight started" can't alert a closed app. Mapping in `02-TRD.md` §8.

### 6.15 Privacy
Task titles and details are never shared. Visibility matrix in `05-BACKEND-SCHEMA.md` §4. Enforced by database grants and Row Level Security, not only UI. Account deletion removes all data. Task text and optional study context go to Groq to rate the task (Zero Data Retention turned on in the Groq console); the privacy notice says so.

### 6.16 Demo mode
Hidden, allow-listed accounts only. 30 s counts as 5 min; force a chest drop (e.g. Mythic). Seed script recreates all demo data.

---

## 7. User stories (acceptance-level)

**Tasks and AI**
- As a student, I want to type a task and see its stat, difficulty, time and XP before saving, so that I know what it's worth.
- As a student, I want to challenge a rating with one sentence of context, so that unusual tasks are judged fairly.
- As a student, I want my task saved even if the AI is down, so that I'm never blocked.

**Focus**
- As a student, I want to start a focus session from Home in one tap, so that I start working immediately.
- As a gym-goer, I want activity mode with my phone locked, so that Vitality tasks still earn XP.
- As a student, I want a warning when I leave the app mid-session, so that I don't lose the session by accident.

**Progression**
- As a player, I want to see the next reward on the level road, so that I have something to aim for.
- As a player, I want to choose which stat new gear boosts, so that it matches what I'm working on.
- As a player, I want to see chest drop rates and my Legendary guarantee counter, so that chests feel fair.

**Bosses and raids**
- As a student, I want to turn an assignment into a boss, so that every focus minute visibly damages it.
- As a group-project member, I want to invite classmates to a party by QR, so that we fight the deadline together.
- As a raid member, I want to see the boss HP drop live when a teammate focuses, so that I feel the team working.

**Social and privacy**
- As a student, I want a friends-only weekly leaderboard based on effort, so that gear doesn't decide who wins.
- As a student, I want my task titles never shown to anyone, so that I can add personal tasks safely.
- As a student, I want to appear offline, so that friends don't see when I'm focusing.

**Wellbeing**
- As a student, I want a weekly rest day and pause mode, so that being ill doesn't destroy my streak.

---

## 8. Success metrics (for the course demo and report)

| Metric | Target |
|---|---|
| Onboarding completes to level 2 | ≤ 3 minutes, no dead ends |
| AI judge test set (~30 tasks incl. 3 injections) | Sensible stats on all; similar tasks within ±1 difficulty; all 3 injections ignored |
| XP / loot / combat modules | `deno test` passes; numbers match this PRD |
| Security | No client can write XP, coins, levels, inventory, damage or chest results (pgTAP grant/RLS tests prove it) |
| Live raid | HP and ticker update on a second phone within ~2 s |
| Demo | Full 12-minute run, 3 clean rehearsals, seed script resets in one command |
| Build order | Phases 0–16 in order (`06-IMPLEMENTATION-PLAN.md`); feature freeze once core is complete (after Phase 13) |

---

## 9. Constraints

- 6 members, about 4 weeks. Flutter + Supabase + Groq (AI judge via Edge Functions) — fixed.
- **Free platforms only, no credit card:** Supabase Free plan, Groq free API, Google OAuth (free), GitHub.
- Light mode only. Android is the demo platform; iOS should build but isn't demo-critical.
- All tunable numbers in the `game_config` table.
- Every member must understand and be able to explain the code they submit.
