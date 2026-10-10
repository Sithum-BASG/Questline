# 04 · UI/UX Design Brief

**Product:** Questline · **Last updated:** 10 Oct 2026 (v3: build order instead of dates)
**Visual reference:** Home **v1** mockup (`questline_main_mock.png`, Figma canvas "Questline Home Style"). Code tokens ship in the asset pack as `lib/app_colors.dart` and `lib/game_assets.dart`.

> **For the AI agent:** Never hard-code a colour, font size, radius or shadow inside a screen. Use the tokens in `core/theme/`. Game visuals appear in **only two places**: the character stage card and reward moments. Everything else stays a clean productivity UI. If a design detail isn't specified here, keep it plain and ask.

---

## 1. Aesthetic

- **Minimal white soft UI with a magical character.** Calm white surfaces, one brand colour (teal), colourful characters and items.
- **Theme: the awakening.** The student's own world turning magical; not a different fantasy world. Copy and art follow that ("Your deadlines were always monsters. Now you can fight back.").
- **A productivity app, not a mobile game.** No ambient particles, no constant auras, no dark game HUDs. The only persistent effect is a soft glow behind the character in the colour of their highest-rarity equipped gear.
- **Light mode only** for this release.

### Surface rule (9 Oct direction — supersedes the earlier "neumorphic containers" note)
- **Containers** (cards, panels, tab bar, sheets): flat **white cards on Paper** with one soft shadow. No neumorphic inset/outset on containers.
- **Clay depth only on tappable things:** primary buttons, chips, active tab indicator. Slightly rounded and "pressable", matching the characters.
- If the design lead reverts to neumorphic containers, only `core/theme/shadows.dart` should need to change.

---

## 2. Colour tokens

### Brand and neutrals (fixed)
| Token | Hex | Use |
|---|---|---|
| `teal` (Awakening Teal) | `#14B8A6` | Accent: glows, progress fills, highlights, selected states |
| `tealDeep` | `#0F766E` | Primary buttons, links, teal text on white (5.5:1 on white) |
| `ink` | `#101935` | Headings, dark surfaces, logo tile |
| `paper` | `#F7F6F3` | App background |
| `white` | `#FFFFFF` | Cards, tab bar, sheets |

### Rarity (fixed meaning; suggested hexes)
| Rarity | Hex | Notes |
|---|---|---|
| Common | `#9CA3AF` | grey |
| Rare | `#3B82F6` | blue |
| Epic | `#8B5CF6` | purple |
| Legendary | `#F5B301` | gold — **gold is reserved for Legendary** |
| Mythic | `#B3123A` | deep crimson, always with a shimmer or gradient, never flat |

**Teal is never a rarity colour.** Rarity colour appears only on item cards, chest reveal bursts, frames and the stage glow.

### Supporting (proposed — design lead to confirm)
| Token | Hex | Use |
|---|---|---|
| `inkMuted` | `#5B6178` | Body secondary text |
| `inkFaint` | `#9AA0B4` | Captions, disabled |
| `line` | `#E8E6E1` | Dividers, card borders if needed |
| `ember` | `#F97316` | Streak flame, streak tile |
| `success` | `#16A34A` | Rank tile, "pulled their weight" check, success toasts |
| `bossHp` (rose) | `#E2557A` | Boss/raid HP bars — **never** a rarity colour |
| `error` | `#D9480F` | Flat red-orange, so a Mythic item never looks like an error |
| Stat tints (muted, icon + chip background at 12% opacity) | Intellect `#5B7C99` · Vitality `#5E9A6E` · Craft `#B07A4F` · Charisma `#B0708F` | Muted so they don't clash with rarity |

Contrast: all body text ≥ 4.5:1 on its background; teal text uses `tealDeep`, never `teal`.

---

## 3. Typography

**Nunito only**, bundled as an asset. Tabular figures for numbers (XP, timers, coins).

| Style | Size / line | Weight | Use |
|---|---|---|---|
| `display` | 32 / 38 | 800 | Reward moment titles, timer digits use 56/60 800 |
| `h1` | 24 / 30 | 800 | Screen titles |
| `h2` | 20 / 26 | 700 | Section titles, card titles |
| `title` | 17 / 22 | 700 | List item titles, button labels |
| `body` | 16 / 24 | 500 | Default text (minimum body size 16) |
| `bodySmall` | 14 / 20 | 500 | Secondary info |
| `caption` | 12 / 16 | 600 | Labels, chips, tab labels |

Headings in `ink`, body in `ink`/`inkMuted`. Sentence case everywhere ("Start focus", not "START FOCUS").

---

## 4. Shape, spacing, depth

| Token | Value |
|---|---|
| Spacing scale | 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 (4-pt grid) |
| Screen side padding | 20 |
| Bottom padding above floating tab bar | ~100 |
| Radius: card | 20 |
| Radius: stage card | 28 |
| Radius: button | 16 (pill for small chips) |
| Radius: sheet top | 28 |
| Card shadow | `0 4 16 rgba(16,25,53,0.06)` |
| Clay button | Fill `tealDeep`, 1 px lighter top inner highlight, bottom edge shadow `0 4 0 #0B5A54`; pressed = translate 2 px down, edge shadow 2 px |
| Clay chip (selected) | White fill, `tealDeep` text, bottom edge `0 2 0 #D9D6CF` |
| Tap targets | ≥ 48 × 48 dp |

**Tab bar:** floating white pill, 16 px from the sides and bottom, card shadow, 5 icons with captions; active tab gets a clay teal indicator.

---

## 5. Game visuals (only two places)

### 5.1 Character stage card
- Layers bottom to top: background image (`bg_<id>`, 1024 × 1536, cropped to the card) → rarity glow (radial, colour of highest-rarity equipped gear, 30–40% opacity) → soft floor shadow (drawn in code) → skin (`skin_<id>_<a|b>`, 1024 × 1536 transparent, feet at y = 1490).
- The character **breaks out of the top of the card** (head and shoulders overlap the card edge).
- Placement constants come from `game_assets.dart`; never eyeball offsets per skin.
- Used on Home and Profile only.

### 5.2 Reward moments
- One reusable full-screen template; variants: level up, loot, boss defeated, badge earned, streak milestone.
- Paper background, code-drawn radial burst in the reward's colour (rarity colour for loot; teal for level up; ember for streak), item art centred, title (`display`), one-line subtitle, primary **Claim** button.
- 1.2–1.8 s entrance; tap anywhere after 0.6 s skips to the end state. Multiple rewards play as a queue.
- Mythic: crimson gradient + shimmer sweep. Legendary/Mythic frames shimmer in code.

### 5.3 Profile portrait and frames
- Portrait = head-and-shoulders crop of the equipped skin over the equipped background, composited at runtime.
- Rounded square (not circle). In the 1024 frame canvas the portrait sits at x/y 182–842 (660 px, corner radius 84; `frame_window_mask.png`) **under** the frame PNG. Scale proportionally for smaller sizes (48 px leaderboard rows, 96 px profile header).

### 5.4 Other art rules
- Bosses: deep indigo ink with amber eyes; need a light card behind them on any dark scrim.
- Gear item art has no baked rarity glow below Epic; the UI card border/background supplies rarity colour. Gear art must not hint at a stat (attunement icon shows the stat).
- Badges: circular medallions, tiers by frame (not bronze/silver/gold). Locked = Tier I in greyscale (code). 512 px WebP.
- Consumable colours avoid rarity colours (shield silver + orange flame, potion teal, scroll cream + emerald seal).

---

## 6. Component library (`core/widgets/`)

| Component | Variants / notes |
|---|---|
| `QButton` | primary (clay tealDeep), secondary (white clay), text, destructive (error colour); loading state; disabled |
| `QCard` | default, tappable (ripple), highlighted (teal 1.5 px border) |
| `QChip` | stat chip (icon + muted tint), filter chip, rarity chip |
| `StatIcon` | 4 stats, sizes 16/20/24 |
| `ProgressBar` | XP (teal), boss HP (rose, with damage tick animation), streak; label left/right |
| `StatTile` | icon, value, label (Home: Streak / This week / Rank) |
| `StageCard` | skin, background, glow, overflow top; sizes Home/Profile |
| `PortraitFrame` | skin crop + background + frame PNG; 48/64/96 |
| `JudgementCard` | stat chip (editable), difficulty pips 1–5, minutes, XP preview, reason, provisional badge, challenged badge, too_big actions |
| `TaskTile` | title, stat icon, due label (late in error colour), play / tick actions, provisional icon |
| `BossCard` | tier art, name, HP bar, time left, status pill (active, staggered, defeated, escaped) |
| `MemberCard` | portrait, name, title, focusing-now dot, damage or check mark |
| `ItemCard` | art, name, rarity border/background, owned/new/equipped states, attuned stat icon |
| `BadgeMedallion` | tier 0–3, progress ring caption |
| `RadarChart` | 4 axes, 30/7 toggle (`fl_chart`) |
| `LeaderboardRow` | rank, portrait, name, title, raw XP, "you" highlight |
| `EmptyState` | illustration slot, title, body, action |
| `QBottomSheet` | drag handle, title, content, primary action |
| `RewardOverlay` | template from §5.2 |
| `TimerDisplay` | mm:ss tabular, ring progress against the estimate |

Build these in Phase 1 (setup) with a hidden **component gallery** route (`/dev/gallery`, debug builds only) so every member reuses them.

---

## 7. KEY screens (design lead finishes these in Figma first)

Home · AI judgement card · Focus session (focus + activity) · Boss detail · Raid detail · Leaderboard · Profile · Level road · Chest opening and reveal · Reward moment template. That is 10; the plan says 12, so the suggested other two are **Session complete** (the XP breakdown is the core payoff) and **Task list**. All other screens are built straight from components and reviewed by the design lead as they land (Phases 7–13), with a final pass in Phase 14.

---

## 8. Motion

| Motion | Spec |
|---|---|
| Standard transitions | 200–250 ms, ease-out |
| Sheets | 300 ms spring, slight overshoot |
| Button press | 80 ms down, 120 ms up |
| XP bar fill | 600 ms ease-out, number counts up |
| Boss damage | HP bar shrinks 400 ms, "−45" floats up 600 ms |
| Raid ticker | new line slides in 200 ms; max 5 visible |
| Reward moments | Rive or Lottie, 1.2–1.8 s |
| Reduced motion (OS setting) | Replace all of the above with 150 ms fades; no bursts, no shimmer |

---

## 9. Copy and tone

- Friendly, short, plain. No guilt ("You missed yesterday!" ✗ → "40 XP keeps your 12-day streak alive" ✓).
- Penalties are shown once, clearly, then the UI moves on to what can still be earned.
- Numbers always say what they are: "86 XP", "~60 min", "720 HP".
- Never show a task title in anything other users can see.

---

## 10. Mobile, layout and accessibility

- Phone portrait only (lock orientation). Design width 390; must work 360–430 and with system font scaling up to 130% (wrap, don't clip).
- Safe areas respected; floating tab bar sits above the gesture bar.
- Semantics labels for icon-only buttons, stat icons and rarity (rarity is never shown by colour alone: always a label or chip text).
- Haptics: light on Claim and chest open; none elsewhere.
