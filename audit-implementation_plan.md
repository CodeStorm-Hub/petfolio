# PetFolio UX/UI & Backend Integration Plan

This plan addresses the layout and contrast issues identified in the UX/UI audit and replaces the hardcoded (mock) gamification data with real data from Supabase.

## User Review Required

> [!IMPORTANT]
> The `AppShell` bottom padding requires a global update to scrollable views to prevent content from being eclipsed. We plan to add ~100px of bottom padding to the main scroll views in Home, Care, Social, and Market. Does this approach work for you, or would you prefer resizing the main body inside the `AppShell` Stack?

> [!TIP]
> The Gamification (Trophy Room / Achievements) is currently mocked in the UI. We will connect this to the `pet_badges` table in Supabase. Let me know if you want any specific default badges to be seeded in the DB for first-time users.

## Proposed Changes

### UI & Layout Fixes

#### [MODIFY] `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`
- Add `SizedBox(height: 120)` to the bottom of the `CustomScrollView` to ensure the `AppShell` does not obscure the bottom content.
- Unify the fallback avatar logic to ensure consistency across the dashboard.
- Update `_RecentAchievementsRow` to consume real badges from a new Riverpod provider instead of the hardcoded `_badges` list.

#### [MODIFY] `lib/features/care/presentation/screens/care_screen.dart`
- Add bottom padding to the main `CustomScrollView` to prevent the empty state or bottom content from being hidden by `AppShell`.

#### [MODIFY] `lib/features/social/presentation/screens/social_screen.dart`
- Add bottom padding to the feed `ListView` / `CustomScrollView` to prevent the bottommost post from being eclipsed.

#### [MODIFY] `lib/features/matching/presentation/screens/matching_screen.dart`
- **Fix Contrast**: Darken the subtitle text on the Match empty state ("Turn on Match Discovery...").
- **Fix Contrast**: Change the icon colors in the Tinder-style circular action buttons from white to darker shades (e.g., `AppColors.ink700` or dynamic dark accents) to pass WCAG AA contrast standards.
- Add bottom padding to ensure the action buttons aren't cramped against the `AppShell`.

#### [MODIFY] `lib/features/marketplace/presentation/screens/marketplace_screen.dart`
- Fix the Market Header: Change "SHIP TO MOCHI'S HOUSE" to dynamically read "SHIP TO ${activePet.name.toUpperCase()}'S HOUSE".
- Add bottom padding to the product grid so the bottom row is fully clickable.

#### [MODIFY] `lib/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart`
- Unify the fallback avatar to ensure it matches the Home header (e.g., using initials consistently instead of mixing with generic emojis).

### Backend Integration (Gamification & Badges)

#### [NEW] `lib/features/care/presentation/controllers/pet_badges_provider.dart`
- Create a `FutureProvider.family<List<PetBadge>, String>` to fetch a pet's earned badges from the `pet_badges` table in Supabase.

#### [MODIFY] `lib/features/care/data/models/pet_badge.dart`
- Ensure the model correctly maps the database rows (e.g., icon/emoji, color, title).

#### [MODIFY] `lib/features/care/presentation/widgets/gamified_care_ui.dart`
- Update `CareGamifiedTrophyRoom` to watch `petBadgesProvider`. If the list is empty, show a fallback message or greyed-out empty slots. Replace the hardcoded `_badges` tuple.

## Verification Plan

### Automated Tests
- N/A - Mostly UI and data binding changes.

### Manual Verification
- Deploy to emulator and scroll to the bottom of Home, Care, Social, and Market to ensure content is fully visible above the `AppShell`.
- Check the Match screen to ensure text and action button icons are clearly visible and legible.
- Switch pets and verify that the Market header dynamically updates the shipping address name.
- Verify that the achievements and trophy room display real data (or empty states) from Supabase.
