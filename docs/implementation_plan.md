# UI/UX Improvement Implementation Plan

This plan outlines the surgical fixes for 5 identified UI/UX issues in the **PetFolio** app.

---

## Proposed Changes

### 1. Market Intro Bottom Sheet blocked by Navigation Bar
- **File:** [shop_intro_screen.dart](file:///j:/GitHub/petfolio/lib/features/marketplace/presentation/screens/shop_intro_screen.dart)
- **Change:**
  - Update `ShopIntroSheet.show` to include `useRootNavigator: true` in `showModalBottomSheet`.
  - Replace `context.pop()` in the "Let's explore" button's `onPressed` with `Navigator.of(context).pop()` (since standard modal bottom sheets pushed on the root navigator are popped via Navigator, not GoRouter).

---

### 2. Category Selector Flow in Market (Browse)
- **File:** [marketplace_categories_screen.dart](file:///j:/GitHub/petfolio/lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart)
- **Change:**
  - Update `MarketplaceCategoriesSheet.show` to include `useRootNavigator: true` in `showModalBottomSheet`.
  - In `_CategoryTile`'s `onTap` and in the `IconButton` (the Close "X" button), replace `context.pop()` with `Navigator.of(context).pop()`.

---

### 3. Care Streak Calendar Contrast & Readability
- **File:** [care_date_picker.dart](file:///j:/GitHub/petfolio/lib/features/care/presentation/widgets/care_date_picker.dart)
- **Change:**
  - In the calendar item builder, replace `pt.ink300` (which has color `#D6C2B0` - very low contrast) with `pt.ink500.withAlpha(140)` for future date indicators (both the day letter and day number).
  - This ensures that unselected future dates look semi-deemphasized but still pass high visual contrast checks.

---

### 4. Matching Empty State Lacks Call-to-Action (CTA)
- **File:** [matching_screen.dart](file:///j:/GitHub/petfolio/lib/features/matching/presentation/screens/matching_screen.dart)
- **Change:**
  - Add an `"Adjust Preferences"` CTA button below the subtitle in the `_EmptyDeck` widget when the deck is exhausted or when no peers are in the area.
  - Tapping this button will open `MatchPreferencesSheet.show(context)` to allow users to increase distance, change criteria, or adjust location.

---

### 5. PawsFeed Comments Autofocus
- **File:** [post_comments_bottom_sheet.dart](file:///j:/GitHub/petfolio/lib/features/social/presentation/widgets/post_comments_bottom_sheet.dart)
- **Change:**
  - Set `autofocus: true` on the primary `TextField` inside the `_CommentInput` widget. This immediately focuses the comment box and opens the system keyboard when the sheet is opened.

---

## Verification Plan

### Automated Tests & Interactive Validation
1. Run the Flutter app with environment definitions.
2. Reconnect the Marionette QA automation agent.
3. **Onboarding & Shop Intro:** Navigate to the Market. Verify the intro bottom sheet renders *above* the bottom navigation bar and the "Let's explore" button is fully visible. Tap the button to verify it dismisses correctly.
4. **Market Categories (Browse):** Tap the **Browse** tab (nav_browse). Tap **Food** category. Verify the category selector pops immediately, closes the bottom sheet, and filters storefront items.
5. **Care contrast:** Tap back and navigate to **Care**. Take a screenshot and visually verify that the contrast of future calendar days is significantly more readable.
6. **Matching CTA:** Tap back and navigate to **Match**. Verify the empty deck view has the `"Adjust Preferences"` button. Tap it to confirm it opens the Match Preferences modal sheet.
7. **Autofocus Comments:** Tap back to home, navigate to **PawsFeed**, open comments, and verify that the keyboard / input autofocuses.
