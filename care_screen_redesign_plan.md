# Care Screen — UI Audit & Redesign Plan

> Screenshots captured live from `emulator-5554` (Pixel 10, Android 17) on 2026-05-31.

---

## Section-by-Section Screenshots

### Section 1 — Gamified Header
![Header screenshot captured from emulator]

**What's visible:** Red wave header, 1-day streak flame circle, "Lv 2 · Curious Pup", 100/250 XP bar, "150 XP to Lv 3 · Attentive Owner", pet switcher pill, dark-mode moon button.

### Section 2 — Trophy Room
![Trophy room captured from emulator]

**What's visible:** 4-column badge grid (First Log = owned/teal; 3-Day, 7-Day Hero, Routine Master, 30-Day Legend, Care Champion = locked/grey). Two rows, uneven distribution (4 + 2).

### Section 3 — Quest Cards (Task list)
![Task cards captured from emulator]

**What's visible:** 9+ completed tasks rendered alphabetically. Time format "10:00:00" visible. Pet avatar bleeds into first card on scroll. All tasks shown as completed (strikethrough), various color-coded icon boxes.

### Section 4 — Weekly Chart
![Weekly chart captured from emulator]

**What's visible:** Almost entirely empty — only today (Sunday) has a tall red bar. Mon–Sat show tiny grey pills near the bottom. "🐾" paw emoji floats above Sunday bar.

### Section 5 — Utility Banners
![Nutrition and medical vault banners]

**What's visible:** "Smart Nutrition & Weight" and "Automated medical vault" — minimal list-row style with teal icon box and chevron.

---

## Identified UI Issues

### 🔴 Section 1 — Gamified Header (Critical)

| # | Issue | Detail |
|---|---|---|
| 1 | **XP bar has no fill colour contrast** | Progress bar track is visible but the fill appears near-white/transparent on the red background — impossible to distinguish progress at 40% fill |
| 2 | **Streak circle is oversized relative to XP panel** | The 120px flame circle dominates ~40% of the header width, leaving the level/XP text cramped on the right. At Lv2 the text panel feels squeezed |
| 3 | **No date context in header** | The header shows streak + level but gives no indication of "today's date" or whether the streak represents *today*. Users can't tell if "1 day" means they've done today yet |
| 4 | **App header (CARE · JHONTU pill) overlaps wave header** | The floating pet-switcher pill sits on top of the wave header with no visual separation. The pet avatar inside the pill is tiny (40px) and hard to recognize |
| 5 | **Dark mode button placement feels isolated** | The moon icon button top-right has no visual grouping with the header — floats as a lone circle with too much whitespace between it and the pet pill |
| 6 | **Missing quick-stats row** | No summary of today's completion (e.g. "7/9 tasks done") visible in the header — users must scroll past the trophy room to see the "All done 🎉" counter |

---

### 🔴 Section 2 — Trophy Room (Critical)

| # | Issue | Detail |
|---|---|---|
| 7 | **Uneven grid layout (4 + 2 orphan tiles)** | 6 badges in a 4-column grid produces a top row of 4 and a bottom row of only 2, leaving a large empty gap bottom-right. Looks broken/incomplete |
| 8 | **Locked badges are indistinguishable from broken assets** | Grey locked tiles use low-contrast monochrome emoji on grey background with no lock icon overlay. Users don't know these are *achievable* — looks like placeholder content |
| 9 | **No progress indicator on locked badges** | There is no hint of how close the user is to unlocking each badge (e.g. "3/7 days to 7-Day Hero"). Motivational dead zone |
| 10 | **Badge tiles have no tap affordance** | No ripple, no shadow, no tap-to-see-details interaction. Tiles feel static and decorative rather than interactive |
| 11 | **"Vault →" link is stylistically inconsistent** | The "Vault →" text link in purple sits next to a bold "Trophy room" section title but uses a different weight and no matching icon, making the row feel unbalanced |

---

### 🟠 Section 3 — Quest/Task Cards (High)

| # | Issue | Detail |
|---|---|---|
| 12 | **Time format shows seconds: "10:00:00"** | Scheduled times render as `HH:MM:SS` instead of `HH:MM` (e.g. "10:00:00" → "10:00 AM"). The `:00` seconds are visual noise |
| 13 | **All tasks shown completed with strikethrough — hard to scan when all done** | When all tasks are completed, every title has a strikethrough and every icon box shows a ✅. The entire list looks identical and uniform — there's no visual hierarchy or summary. The user can't instantly see their achievement at a glance |
| 14 | **No grouping or sorting by frequency** | Daily, Weekly, Biweekly, and Monthly tasks are interleaved alphabetically. Users can't distinguish "what I need to do every day" vs "what I do once a month". Missing sections: DAILY / WEEKLY / MONTHLY |
| 15 | **Pet avatar from app-bar bleeds into first task card on scroll** | The floating pet switcher pill (with the cat avatar) overlaps the first task card during scroll — Z-order issue, the avatar shows on top of the task card content |
| 16 | **"Refresh AI Routine" button has poor visual hierarchy** | The outlined button is styled identically to a ghost/tertiary button and sits between the "All done 🎉" counter and the first task card — no breathing room. On an "all done" day it looks like a residual/leftover action |

---

### 🟠 Section 4 — Weekly Chart (High)

| # | Issue | Detail |
|---|---|---|
| 17 | **6 of 7 bars are visually empty** | Mon–Sat bars render as small grey pills (~15% height) at the base while Sunday has a tall red bar. The chart communicates nothing meaningful about the week — looks like a bug or data error to users |
| 18 | **Chart container is too tall for its content** | The chart card has ~128px height but past-day bars only use ~15% of it, leaving ~110px of dead white space above 6 of 7 bars. The proportions feel wrong |

---

### 🟡 Section 5 — Utility Banners (Medium)

| # | Issue | Detail |
|---|---|---|
| 19 | **Nutrition and Medical Vault banners are visually identical** | Same layout, same teal icon box size, same chevron — no personality difference between the two. They blend together and neither stands out as a CTA |
| 20 | **No visual hook / preview content** | Banners show generic subtitles ("Track weight history · View caloric needs") but no actual pet data preview (e.g. last weight, next vaccine date). Missed opportunity to surface useful info inline |

---

## Redesign Plan

---

### Phase 1 — Header Redesign

**Goal:** Make the header more impactful, scannable and information-dense without feeling cluttered.

#### 1.1 — Restructure the Layout

Replace the current side-by-side [streak circle | XP panel] with a **stacked hero layout**:

```
┌──────────────────────────────────────────────────┐
│  [pet avatar 52px] [pet name · species]  [moon]  │  ← App header bar
├──────────────────────────────────────────────────┤
│                                                  │
│   🔥  1        Lv 2 · Curious Pup               │
│  DAY STREAK    ████████░░░░░░░░ 100 / 250 XP     │
│                150 XP → Lv 3 · Attentive Owner   │
│                                                  │
│  ┌──────────────────────────────────────┐        │
│  │  7/9 tasks done today   All done! 🎉 │        │  ← Summary chip
│  └──────────────────────────────────────┘        │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### 1.2 — Fix XP Bar Visibility
- Change XP bar fill to a **warm gold → tangerine gradient** (`AppColors.sunny → AppColors.tangerine`) with `1.5dp` white border outline on the track
- Increase bar height from 12px → **16px** with stronger contrast border

#### 1.3 — Add Today's Summary Chip
- A pill chip below the XP bar: `"7/9 tasks done · Today"` using `AppColors.sunny` background
- On "All done": transitions to `AppColors.mint` with `"All done! 🎉"` text

#### 1.4 — Tighten Pet Switcher
- Move the pet avatar pill to a **proper top safe-area header bar** with fixed positioning — not overlapping the wave
- Increase pet avatar from 40px → **52px** with species accent ring

---

### Phase 2 — Trophy Room Redesign

**Goal:** Turn a static decorative grid into a motivational progress showcase.

#### 2.1 — Fix Grid Layout: 3 Columns Instead of 4

Switch from 4-column to **3-column grid** so 6 badges produce 2 even rows of 3:

```
┌──────────┐ ┌──────────┐ ┌──────────┐
│ 🐾 First │ │ 🔥 3-Day │ │ 🦸 7-Day │
│   Log    │ │          │ │   Hero   │
│  OWNED   │ │  LOCKED  │ │  LOCKED  │
└──────────┘ └──────────┘ └──────────┘
┌──────────┐ ┌──────────┐ ┌──────────┐
│ 💯Routine│ │ 👑30-Day │ │🏆 Champ  │
│  Master  │ │  Legend  │ │          │
│  LOCKED  │ │  LOCKED  │ │  LOCKED  │
└──────────┘ └──────────┘ └──────────┘
```

#### 2.2 — Differentiate Locked vs Owned States

| State | Visual Treatment |
|---|---|
| **Owned** | Vibrant background with badge color, full-opacity emoji, animated subtle glow/pulse, `EARNED` label chip at bottom |
| **Locked** | `surface2` grey background, 30%-opacity emoji, **🔒 lock icon** overlay bottom-right corner, progress hint text |

#### 2.3 — Add Progress Hints on Locked Badges
- Under each locked badge: small progress text
  - "3-Day: `🔥 1/3 days`" 
  - "7-Day Hero: `🦸 1/7 days`"
  - "Care Champion: `🏆 13/100 logs`"
- Uses real data from `petAwardsSummaryProvider` (streak + logs_count)

#### 2.4 — Make Tiles Tappable
- On tap: show a bottom sheet with badge name, description, unlock criteria, and current progress bar
- Add subtle `InkWell` ripple

#### 2.5 — Redesign Section Header Row
```
┌────────────────────────────────┐
│ 🏆 Trophy Room    1/6 earned   │  Vault →
└────────────────────────────────┘
```
- Replace plain "Trophy room" + "Vault →" with a row that shows `N/6 earned` count

---

### Phase 3 — Quest Cards Redesign

**Goal:** Better information hierarchy, frequency grouping, and time formatting.

#### 3.1 — Fix Time Format
- Strip seconds: `"10:00:00"` → `"10:00 AM"` using `TimeOfDay` formatting

#### 3.2 — Group Tasks by Frequency
Add frequency section headers between task groups:

```
━━━━━━━━ DAILY ━━━━━━━━
[Morning Feeding card]
[Evening Feeding card]
[Interactive Playtime card]

━━━━━━━━ WEEKLY ━━━━━━━━
[Clicker Training - Sit card]
[Puzzle Toy card]
[Weekly Brushing card]
[Weekly Grooming card]

━━━━━━━━ BIWEEKLY & MONTHLY ━━━━━━━━
[Nail Trim card]
[Annual Checkup card]
```

Section headers styled as: small caps, `pt.ink400` color, with thin divider lines on either side.

#### 3.3 — "All Done" Celebration State
When all tasks are complete, replace the card list with a **celebration panel** above the cards:
```
┌────────────────────────────────────────┐
│  🎉 All done for today!                │
│  You earned 150 XP · Streak: 1 day 🔥 │
│  [Share progress]  [View this week]    │
└────────────────────────────────────────┘
```
The individual cards can collapse into a scrollable "completed" section below.

#### 3.4 — Fix Z-Order: Pet Avatar Bleed on Scroll
- The floating app header (with pet avatar) needs `elevation` / `Material` layer with `clipBehavior: Clip.hardEdge` so task cards scroll *under* it cleanly, not *over* it

#### 3.5 — Refresh AI Routine Button Placement
- Move "Refresh AI Routine" to a **FAB extension** or put it inside the section header row for "TODAY'S QUESTS" as a trailing icon button, not a full-width ghost button between the counter and the list

---

### Phase 4 — Weekly Chart Redesign

**Goal:** Make the chart actually communicate weekly progress clearly.

#### 4.1 — Fix Bar Heights for Past Days
Current: past "miss" days use `h = 0.20` (20% height faint grey pill). Proposed:

| Day State | Height | Color |
|---|---|---|
| Future | 10% | `surface2` (faint placeholder) |
| Past miss | **30%** | `pt.ink200` with dashed border |
| Past hit | **85%** | Vibrant color per day |
| Today | Real `progressPercent` clamped 15–100% | Tangerine/poppy gradient with glow |

#### 4.2 — Add a "Week Summary" Header Inside the Card
```
┌──────────────────────────────────────────┐
│  This week  ·  1/7 goals hit    14% ↑   │
│  M   T   W   T   F   S   🐾S           │
│  ░   ░   ░   ░   ░   ░   ████          │
└──────────────────────────────────────────┘
```
- Small "N/7 goals hit" counter in the card header
- Percentage vs last week if data available

#### 4.3 — Show Day Numbers Under Letters
Change `M T W T F S S` labels to include day-of-month:
```
M    T    W    T    F    S    S
26   27   28   29   30   31   1
```

---

### Phase 5 — Utility Banner Redesign

**Goal:** Differentiate banners with personality and real data previews.

#### 5.1 — Nutrition Banner Redesign
```
┌────────────────────────────────────────────────┐
│ 🍽️  Smart Nutrition                            │
│     Jhontu · 4.2kg last logged May 28          │
│     Daily need: ~280 kcal                  >   │
└────────────────────────────────────────────────┘
```
- Background: warm `AppColors.sunnySoft` gradient
- Show last logged weight and computed caloric need inline

#### 5.2 — Medical Vault Banner Redesign
```
┌────────────────────────────────────────────────┐
│ 🏥  Medical Vault          1 record due soon   │
│     Vaccines · Medications · Vet visits        │
│     Annual Checkup · due in 3 weeks        >   │
└────────────────────────────────────────────────┘
```
- Background: `AppColors.mintSoft`
- Show next due record name + timeframe inline using `healthVaultControllerProvider`

---

### Phase 6 — Missing Feature: Date Picker Bar

The current screen has **no horizontal date picker**, meaning users can't browse past days' task history. The date picker exists in the code (`_HorizontalDatePicker`) but is **not rendered anywhere in the current scroll list** — it's been removed at some point.

**Add it back:** Insert the horizontal date strip between the gamified header wave and the Trophy Room section:

```
[← 26  27  28  29  30  31  [1] →]
      M   T   W   T   F   S   S
```

---

## Implementation Priority Order

| Priority | Phase | Effort | Impact |
|---|---|---|---|
| 🔴 P0 | Phase 3.1 — Fix time format (10:00:00 → 10:00 AM) | XS (1 line) | High |
| 🔴 P0 | Phase 3.4 — Fix pet avatar Z-order bleed | XS (elevation fix) | High |
| 🔴 P1 | Phase 2.1 — Trophy room 3-column grid | S | High |
| 🔴 P1 | Phase 2.2 — Locked badge lock icon + owned glow | S | High |
| 🟠 P2 | Phase 1.2 — XP bar contrast fix | XS | Medium |
| 🟠 P2 | Phase 1.3 — Today's summary chip in header | S | High |
| 🟠 P2 | Phase 3.2 — Group tasks by frequency | M | High |
| 🟠 P2 | Phase 4.1 — Weekly chart bar heights | S | Medium |
| 🟡 P3 | Phase 2.3 — Badge progress hints | M | High |
| 🟡 P3 | Phase 3.3 — All-done celebration panel | M | Medium |
| 🟡 P3 | Phase 4.2 — Week summary header in chart | S | Medium |
| 🟡 P3 | Phase 4.3 — Day numbers in chart | XS | Low |
| 🟢 P4 | Phase 5.1/5.2 — Banner redesign with real data | M | Medium |
| 🟢 P4 | Phase 6 — Restore date picker | M | High |
| 🟢 P4 | Phase 3.5 — Refresh AI Routine button placement | S | Low |

---

## Open Questions for User Approval

> [!IMPORTANT]
> **Trophy grid columns**: Switch from 4-column to 3-column grid? (fixes the 4+2 orphan layout)

> [!IMPORTANT]
> **Task grouping**: Should tasks be grouped by DAILY / WEEKLY / MONTHLY section headers? This changes the scrolling feel significantly.

> [!IMPORTANT]
> **All-done celebration**: Should we collapse completed cards into a summary panel when all tasks are done, or keep the full list visible with strikethroughs?

> [!NOTE]
> **Date picker**: Should the horizontal date picker be restored between the header and trophy room? It was present in earlier designs.

> [!NOTE]
> **Utility banners**: Should they show real inline data (last weight, next due record) or keep the current generic subtitle text?
