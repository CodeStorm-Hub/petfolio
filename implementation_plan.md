# PetFolio Redesign — Implementation Plan

## Summary

The `PetFolio Redesign/` folder contains a complete React-based design mockup with 7 screens. The Flutter codebase already has the **design system tokens** (colors, typography, wave headers, PetAvatar, pill buttons, PfCard) fully aligned. The implementation focuses on **applying the redesign language to key screens** that haven't been fully updated yet.

## What's Already Correct

- `AppColors` — exact same palette as design file (tangerine, poppy, mint, sunny, lilac, sky)
- `AppTheme` — Nunito + Fraunces fonts, correct dark-mode surfaces
- `PetAvatar` with rainbow ring (conic gradient), species disc
- `PrimaryPillButton` with 3D shadow effect (translateY on press)
- `WaveHeader` + `PfSectionTitle` + `PfCard` — match design exactly
- `_FloatingNav` — floating pill nav with colored tabs, already correct

## Proposed Changes

---

### Core Widgets — New / Enhanced

#### [NEW] lib/core/widgets/pf_stat_tile.dart
Reusable coloured stat tile (used on Home and future screens):
- Icon + big number + small label
- Soft background color, no border, mild inner highlight shadow
- Matches `StatTile` from `home.jsx`

#### [MODIFY] lib/core/widgets/wave_header.dart
- Add `PfGreetingWaveHeader` variant: a colored wave header that accepts an eyebrow string, a display headline (Fraunces), and an inline floating card widget that peeks out the bottom of the wave area. This matches the home screen hero pattern from `home.jsx`.

#### [MODIFY] lib/core/widgets/widgets.dart
- Export new `PfStatTile` and `PfGreetingWaveHeader`

---

### Home / Pet Profile Screen

#### [MODIFY] lib/features/pet_profile/presentation/screens/pet_profile_screen.dart
Replace the current `AppHeader` + flat layout with the full redesign:

1. **Wave hero header** — species-color background, "Good morning, [user]" eyebrow in white, Fraunces display headline "**[PetName]** is feeling cuddly today", pet switcher button (glassmorphic pill) top-left, bell + settings icons top-right.
2. **Floating pet card** — white card peeking out of wave: PetAvatar (ring=true), name/breed/age, streak flame chip. Overlaps the wave bottom.
3. **Quick stats trio** — 3-column grid: Day streak (sunny-soft), XP earned (lilac-soft), Care logs (mint-soft). Each is a `PfStatTile`.
4. **Today's quests preview** — `PfSectionTitle` + `PfCard` containing 3 `DailyQuestRow` items (linked to real care tasks from `careDashboardProvider`). "See all →" navigates to `/care`.
5. **Recent moments** — 3-up photo grid (`PlaceholderImg`-style containers, or real photos if available).
6. **Recent achievements** — horizontal scroll of badge tiles (from `petAwardsProvider`).

The current tab-bar layout (`Overview / Health / Care / Awards`) is preserved but moved below a condensed version of the hero.

---

### Care Screen

#### [MODIFY] lib/features/care/presentation/screens/care_screen.dart
The care screen already exists but the header section needs a significant visual upgrade:

1. **Streak hero** — 110×110 radial gradient circle with bouncing animation, big fire emoji + streak number + "DAY STREAK" label. Pulse ring animation around it.
2. **XP / Level bar** — Level number + "Caretaker" label, XP progress bar with multi-color gradient (sunny→tangerine→poppy), "N XP to Lv 8" subtitle.
3. **Task rows** — Replace existing task cards with `PfTaskRow`: colored icon box, label with WEEKLY chip, time + due indicator, "+N XP" chip, circle check button. On check: XP burst float-up animation.
4. **Weekly chart** — Colored bar chart (7 bars, one per day, today highlighted with paw emoji above it). Already in a `PfCard`.
5. **Trophy room** — 4-column grid of `BadgeTile`s (locked ones greyed + `filter: grayscale`).

---

### Onboarding Screen

#### [MODIFY] lib/features/pet_profile/presentation/screens/onboarding_screen.dart
The onboarding screen already exists (73KB). Align it more closely with the design:

1. **Step 0 (Hello)**: Conic gradient paw-print logo circle, Fraunces "Hi! I'm PetFolio." headline, warm body copy, "Start the tail-wag" pill button, ghost "I already have an account" link.
2. **Species step**: 3×2 grid of species cards. Selected card shows species color bg + white text + scale-up + color shadow.
3. **Name step**: Large styled text input, quick-name chips (Mochi, Biscuit, etc.).
4. **Age step**: Bone-slider (already in design, needs a custom Flutter slider with bone-shaped thumb).
5. **Personality step**: Wrap chip grid. Selected = species color.
6. **Progress dots**: Pill-style progress indicators.
7. **Floating paw decorations**: Animated paw icons in background.

---

### Social Feed Screen

#### [MODIFY] lib/features/social/presentation/screens/social_screen.dart
Already 50KB with a solid implementation. Align with design:

1. **Header**: "Pawsfeed" Fraunces title, pack member count, search + send icon buttons.
2. **Story bar**: Horizontal scroll with `PetAvatar(ring=true)` per pet. "Your story" add button with dashed orange ring.
3. **Post cards**: Match `PostCard` from design — avatar + name + location·time in header, full-width photo placeholder, text, reaction stack visualizer (paw/heart/bone circles), action row (React / Comment / Share / Save) with long-press reaction picker.

---

### Match Screen

#### [MODIFY] lib/features/matching/presentation/screens/matching_screen.dart
Align swipe card visuals with the design:

1. **Swipe cards** — Gradient card background using species colors, large emoji in center, name/age/breed overlay with gradient, trait chips (glassmorphic pills), distance badge (top-right).
2. **Like/Nope stamps** — WOOF YES / NEXT overlays on drag direction.
3. **Action buttons** — 5 round action buttons (×, ⭐, 🐾 primary, 🦴, ↺) with 3D shadow effect.
4. **Mutual match overlay** — Radial gradient bg, confetti, two avatars + paw connector, "Pawfect Match!" headline, "Send a tail wag 🐾" button.

---

## Implementation Order

1. `pf_stat_tile.dart` — new shared widget (no deps)
2. `wave_header.dart` — add `PfGreetingWaveHeader`
3. `widgets.dart` — export updates
4. `pet_profile_screen.dart` — redesign Home screen header + stat tiles + quest preview + badges
5. `care_screen.dart` — redesign header (streak hero + XP bar)
6. `onboarding_screen.dart` — refine species grid + bone slider + personality chips
7. `social_screen.dart` — refine post cards + story bar + reaction picker
8. `matching_screen.dart` — refine swipe cards + action buttons

## Verification Plan

- `flutter analyze` — no new errors
- Visual inspection of each modified screen in the running app
- Confirm dark mode still works across all updated screens
- Confirm existing providers (`careDashboardProvider`, `petListProvider`, `careStreakRealtimeProvider`) are still wired correctly

## Open Questions

> [!IMPORTANT]
> The design URL (https://api.anthropic.com/v1/design/h/pAKpm5a-SwYHglqZ2fz7ew) returned 404. Implementation is based on the local `PetFolio Redesign/` folder which contains the complete design mockup.

> [!NOTE]
> The onboarding bone-slider requires a custom Flutter `SliderTheme` to render a bone-shaped thumb. A simpler pill-shaped thumb with bone icon can be used as a Flutter-idiomatic approximation.

> [!NOTE]
> Reaction burst animations (floating paw/heart/treat/star emojis) will use Flutter's `AnimationController` + `SlideTransition` + `FadeTransition`. This is a best-effort approximation of the CSS `pf-float-up` keyframe.
