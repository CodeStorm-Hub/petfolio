# Petfolio — Comprehensive Codebase & UX Review
**Date:** 2026-05-26 | **Branch:** `redesign-from-claude-design` | **Reviewer:** Claude Sonnet 4.6

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Feature & Module Inventory](#2-feature--module-inventory)
3. [Live Database Audit](#3-live-database-audit)
4. [Feature Implementation Status (Corrected)](#4-feature-implementation-status-corrected)
5. [UI Screen & Component Map](#5-ui-screen--component-map)
6. [UI/UX Review](#6-uiux-review)
7. [Architecture & Design Pattern Review](#7-architecture--design-pattern-review)
8. [Security & Auth Review](#8-security--auth-review)
9. [Data Consistency & Business Logic](#9-data-consistency--business-logic)
10. [Duplicate / Deprecated Code](#10-duplicate--deprecated-code)
11. [Critical Findings & Priority Matrix](#11-critical-findings--priority-matrix)

---

## 1. Executive Summary

Petfolio is a Flutter mobile app with 6 user-facing feature modules (auth, pet profile, care, social, matching, marketplace) plus an admin module. The codebase spans **~193 source files**, uses **Supabase + Riverpod + GoRouter**, and has **78 applied migrations** against a live production database with **31 tables** and **29 RPC functions**.

**The CLAUDE.md documentation is substantially out of date.** It describes the app as having 12 tables, mock social/matching data, and 0 rows in most feature tables. The live database tells a different story: the social, matching, care, and marketplace modules are all substantially live with real data. This review supersedes CLAUDE.md where they conflict.

**Overall Assessment:** Strong architectural foundation, active development, production-grade DB schema. Primary issues are (a) stale/wrong documentation creating a false picture of completion status, (b) several large monolithic widget files, (c) a pattern of extracting theme variables into local `pc` that are then ignored, (d) two confirmed data integrity gaps in the DB, and (e) Stripe webhook verification missing.

---

## 2. Feature & Module Inventory

### 2.1 Core Infrastructure (`lib/core/`)

| Directory | Files | Purpose |
|-----------|-------|---------|
| `core/domain/models/` | 8 | Shared domain models (Pet, CareTask, ActivityLevel, Species, Gender, AppNotification) |
| `core/domain/controllers/` | 2 | `ActivePetController`, `PetListController` — global active-pet context |
| `core/domain/repositories/` | 1 | `PetRepository` — CRUD, avatar upload, reorder, archive, discoverability |
| `core/errors/` | 1 | `AppException` — domain exception hierarchy |
| `core/router/` | 1 | `router.dart` — 702 lines, GoRouter with StatefulShellRoute, 40+ routes |
| `core/services/` | 4 | NotificationService, LocationService, LocationProviders, LatLng |
| `core/theme/` | 5 | AppColors (90+ tokens), AppTheme (735 lines, full M3), ThemeNotifier (SharedPrefs-backed) |
| `core/utils/` | 1 | DateParser |
| `core/widgets/` | 20 | Design system: PetAvatar, GlassCard, PillButton, SkeletonLoader, WaveHeader, PetSwitcherSheet, etc. |

### 2.2 Feature Modules

| Module | Screens | Widgets | Controllers | Repositories | Models |
|--------|---------|---------|-------------|--------------|--------|
| **auth** | 2 | 1 | 1 | 1 | 0 |
| **pet_profile** | 4 | 1 | 2 | 0 (uses core) | 0 (uses core) |
| **care** | 3 | 2 | 5 | 3 | 8 |
| **social** | 7 | 1 | 7 | 4 | 5 |
| **matching** | 3 | 2 | 8 | 1 (+1 datasource) | 9 |
| **marketplace** | 16 | 4 | 12 | 5 | 7 |
| **admin** | 2 | 8 | 7 | 1 | 2 |

**Total: ~193 Dart source files** (excluding `.g.dart` / `.freezed.dart` generated files)

---

## 3. Live Database Audit

### 3.1 Actual Table Count vs CLAUDE.md

**CLAUDE.md claims 12 tables. The live database has 31 tables.**

| Table | Rows | CLAUDE.md Status | Actual Status |
|-------|------|-----------------|---------------|
| `users` | 10 | Connected | Connected |
| `pets` | 23 | Connected (said 2) | Connected |
| `care_logs` | 115 | Connected (said 0) | Fully Live |
| `care_tasks` | 136 | Not mentioned | Fully Live |
| `care_streaks` | 7 | Not mentioned | Fully Live |
| `pet_badges` | 11 | Not mentioned | Fully Live |
| `pet_care_gamification` | 7 | Not mentioned | Fully Live |
| `health_vitals` | 5 | "UI not implemented" | Data exists |
| `health_logs` | 15 | Not mentioned | Data exists |
| `medical_vault` | 2 | Not mentioned | Data exists |
| `posts` | 13 | "0 rows, mock data" | Live data |
| `post_likes` | 42 | "partially connected" | Fully Live |
| `comments` | 31 | Not mentioned | Fully Live |
| `comment_likes` | 3 | Not mentioned | Live |
| `stories` | 8 | Not mentioned | Live |
| `pet_follows` | 6 | Not mentioned | Live |
| `follows` | 4 | Not mentioned | Live |
| `notifications` | 4 | Not mentioned | Live |
| `reported_posts` | 0 | Not mentioned | Schema ready |
| `match_requests` | 16 | "code schema-incompatible" | Live |
| `swipes` | 118 | "writes to nonexistent table" | **Exists & live** |
| `matches` | 20 | "writes to nonexistent table" | **Exists & live** |
| `chat_threads` | 17 | "Not implemented" | Live |
| `chat_messages` | 34 | "Not implemented" | Live |
| `products` | 11 | Connected (said 8) | Connected |
| `shops` | 7 | Not mentioned | Live |
| `marketplace_orders` | 11 | Connected (said 1) | Fully Live |
| `vendor_ledgers` | 0 | Not mentioned | Schema ready — **zero entries despite 11 orders** |
| `inventory_reservations` | 3 | Not mentioned | Live |
| `shop_deletion_requests` | 2 | Not mentioned | Live |
| `audit_logs` | 6 | Not mentioned | Live |

> **Critical CLAUDE.md Error:** The `swipes` and `matches` tables DO exist and have real data (118 swipes, 20 matches). The claim that "code writes to nonexistent swipes and matches tables" is incorrect — the tables were added in migration `matching_postgis_swipes_matches`.

> **Missing from DB:** `post_candles` table (referenced in CLAUDE.md) was removed in migration `remove_memorial_feature`. All references to it in CLAUDE.md are stale.

### 3.2 RPC Functions (29 total)

| Function | Purpose |
|----------|---------|
| `get_care_dashboard_snapshot` | Atomic care dashboard load (tasks + streak + gamification) |
| `matching_discovery_candidates` | Geo-filtered pet discovery with PostGIS |
| `get_match_inbox` | Match inbox snapshot (threads + last message) |
| `process_checkout` | Atomic checkout: inventory reserve → order create → ledger |
| `confirm_order_inventory` | Confirm inventory reservation after payment |
| `release_order_inventory` | Release expired/cancelled reservations |
| `check_daily_completion` | Compute care streak after task toggle |
| `get_pet_awards_summary` | Aggregate badges and XP per pet |
| `get_pet_stats` | Follower counts, post counts per pet |
| `get_or_create_social_thread` | Upsert DM thread for user pair |
| `ensure_chat_thread_for_match` | Create chat thread when match accepted |
| `approve_vendor_kyc` / `reject_vendor_kyc` | Admin KYC workflow |
| `resolve_reported_post` | Admin content moderation |
| `request_shop_deletion` / `resolve_shop_deletion` | Shop deletion workflow |
| `vendor_update_order` | Vendor updates order status/shipping |
| `cancel_order` | Buyer order cancellation |
| `is_admin` | Admin role check for RLS |
| `set_pet_location_point` | Update pet PostGIS location |
| `mark_story_viewed` | Append viewer to story's `viewed_by_users` array |
| `cleanup_expired_stories` | Purge stories older than 24h |
| `handle_post_like_sync`, `handle_post_comment_sync` | Triggers to sync denormalized counts |
| `handle_comment_like_sync`, `handle_new_chat_message` | Triggers for comment likes and chat |

### 3.3 Migration Health

- **78 migrations applied** — shows heavy iterative development
- Several migration names hint at previous fixes: `pr6_review_fixes`, `pr10_security_fixes_invoker_rpcs`, `fix_confirm_order_expired_reservations`, `fix_process_checkout_duplicate_product_reservation`
- Migration ordering has gaps (some use date-prefixed names that sort out of chronological order)

---

## 4. Feature Implementation Status (Corrected)

### Auth ✅ Fully Live
- Email/password sign-in and registration connected
- `_RouterNotifier` redirects handle unauthenticated access
- Password reset flow via email
- Session persisted via Supabase GoTrue client

### Pet Profile ✅ Fully Live
- 23 pets in DB across 10 users
- Avatar upload to `pets` Supabase Storage bucket
- Pet reordering (drag), archiving, discoverability toggle
- Active pet selection persisted to SharedPreferences
- Multi-step onboarding (5 steps with floating paw animations)

### Care ✅ Fully Live
- 136 care tasks, 115 care logs, 7 streaks, 11 badges, 7 gamification rows
- `get_care_dashboard_snapshot` RPC for atomic load
- Gamification: XP points, badge unlock, daily quest system
- Task frequency support: once/daily/twice_daily/weekly/biweekly/monthly/as_needed
- Medical Vault: vaccines, medications, allergies with expiry reminders
- Health logs with severity tracking
- **Gap:** `health_vitals` table has 5 rows but there is no UI or repository for recording/viewing vitals (weight, temperature, heart rate, blood pressure, glucose)

### Social ✅ Substantially Live
- 13 posts, 42 likes, 31 comments, 3 comment likes, 8 stories, 6 pet follows
- Post creation with image upload (multi-image)
- Real-time like/comment count via Supabase realtime + DB triggers
- Story creation and 24-hour auto-cleanup via `cleanup_expired_stories` RPC
- Follow/unfollow between pets
- Notifications system (4 rows, types: like/comment/follow/kyc/shop_deletion)
- **Gap:** Notification bell in UI not wired to `notifications` table fetch
- **Gap:** Comment replies (`parent_id` column exists on `comments` table, but UI does not support threaded replies)

### Matching ✅ Substantially Live
- 118 swipes, 20 mutual matches, 16 match requests, 17 chat threads, 34 messages
- PostGIS-based geo discovery (`matching_discovery_candidates` RPC)
- Swipe actions: LIKE / PASS / GREET / SUPER_PAW
- Real-time match detection via Supabase realtime on `matches` table
- Match celebration overlay on mutual match
- Chat with real-time messages
- **Gap:** `match_requests` table (16 rows) appears to coexist with `swipes`/`matches` tables — two parallel matching systems. The `match_requests` table (playdate/breeding/adoption workflow) vs `swipes`/`matches` (Tinder-style) serve different use cases but their relationship and UI entry point is unclear
- **Gap:** `chat_threads.mutual_match_id` FK → `matches.id` and `chat_threads.match_request_id` FK → `match_requests.id` — two chat creation pathways not fully reconciled

### Marketplace ✅ Substantially Live
- 7 shops, 11 products, 11 orders, 3 inventory reservations
- Full vendor onboarding: shop creation → KYC (Stripe or manual) → product listing → order fulfillment
- `process_checkout` RPC for atomic checkout with inventory reservation
- COD (Cash on Delivery) and Stripe payment methods
- Vendor ledger schema exists but **0 rows** — `process_checkout` is not populating `vendor_ledgers`
- Stripe Connect onboarding screen present
- Admin KYC review workflow with approve/reject RPCs
- **Gap:** No Stripe webhook handler → payment confirmation is client-side only (no server-side verification that PaymentIntent succeeded)
- **Gap:** `vendor_ledgers` never populated despite 11 orders — financial tracking is broken

### Admin ✅ Partially Live
- Role check via `is_admin` DB function (not a JWT claim — queries DB on every admin page load)
- 6 audit log entries
- KYC approval/rejection workflow
- Content moderation (reported posts)
- Shop deletion request review
- COD order reconciliation UI
- **Security Gap:** Admin role is determined at runtime via `is_admin()` DB function called from `isAdminProvider`. If the RLS on `is_admin` is misconfigured, a non-admin could spoof admin access. Should be enforced by JWT custom claim or at minimum the RLS on admin-only tables should independently enforce this.

---

## 5. UI Screen & Component Map

### 5.1 Navigation Shell

```
StatefulShellRoute (bottom nav / side rail)
├── Tab 0 — Pets (/home)        → PetProfileScreen
├── Tab 1 — Care (/care)        → CareScreen
├── Tab 2 — Social (/social)    → SocialScreen
├── Tab 3 — Match (/match)      → MatchingScreen
└── Tab 4 — Market (/market)    → MarketplaceScreen
```

Adaptive: bottom floating pill nav ≤599dp, NavigationRail ≥600dp.

### 5.2 Full Screen Map

**Auth**
- `/login` — LoginScreen (email/password + reset)
- `/register` — RegistrationScreen

**Pet Profile**
- `/home` — PetProfileScreen (stats, quests, moments, achievements)
- `/onboarding` — OnboardingScreen (5-step flow)
- `/manage-pets` — ManagePetsScreen (reorder, archive)
- `/edit-profile/:petId` — EditProfileScreen

**Care**
- `/care` — CareScreen (task list, streak, XP, gamification)
- `/care/medical-vault` — MedicalVaultScreen
- `/care/nutrition` — NutritionScreen

**Social**
- `/social` — SocialScreen (feed + stories strip)
- `/social/post/:postId` — PostDetailScreen (full post + comments)
- `/social/create-post` — CreatePostScreen
- `/social/create-story` — CreateStoryScreen
- `/social/story/:petId` — StoryViewerScreen
- `/social/profile/:petId` — SocialProfileScreen
- `/social/notifications` — NotificationsScreen

**Matching**
- `/match` — MatchingScreen (swipe deck + matches inbox)
- `/match/inbox` — MatchesInboxScreen
- `/match/chat/:threadId` — ChatScreen

**Marketplace (Buyer)**
- `/market` — MarketplaceScreen (grid + search + fly-to-cart animation)
- `/market/product/:productId` — ProductDetailScreen
- `/market/shop/:shopId` — ShopStorefrontScreen
- `/market/cart` — CartScreen
- `/market/order-confirmation` — OrderConfirmationScreen
- `/market/my-orders` — BuyerOrderListScreen
- `/market/my-orders/:orderId` — BuyerOrderDetailScreen

**Marketplace (Vendor)**
- `/market/seller` — SellerDashboardScreen
- `/market/seller/setup` — ShopSetupScreen
- `/market/seller/edit` — EditShopScreen
- `/market/seller/products` — VendorProductListScreen
- `/market/seller/products/add` — AddEditProductScreen
- `/market/seller/orders` — VendorOrderQueueScreen
- `/market/seller/orders/:orderId` — VendorOrderDetailScreen
- `/market/seller/kyc` — ManualKycScreen
- `/market/seller/stripe-onboarding` — StripeOnboardingScreen

**Admin**
- `/admin` — AdminScreen (auth guard → AdminLayout)
- Admin tabs: Dashboard / KYC Approvals / Moderation / Orders / Shops / Ledger

### 5.3 Core Widget Inventory

| Widget | Purpose | Notes |
|--------|---------|-------|
| `PetAvatar` | Avatar with emoji/image/initials, species ring, glow, online dot | 280 lines, well-built |
| `GlassCard` | Glassmorphism card with blur + shine + solid fallback | 243 lines |
| `PillButton` | Multi-variant pill button (primary/soft/ghost/outline/dark) + animations | 246 lines |
| `PrimaryPillButton` | Scale + shadow press animation, loading state, haptics | 267 lines |
| `WaveHeader` | Wave-clipped gradient section header | 306 lines |
| `PetSwitcherSheet` | Draggable bottom sheet for pet switching with active indicator | 569 lines |
| `AppHeader` | Shell-wide top bar with pet switcher + eyebrow label + actions | 380 lines |
| `SkeletonLoader` | Shimmer placeholder with Reduce Motion support | 175 lines |
| `TailWagLoader` | Custom animated dog tail loading indicator | 171 lines |
| `ReactionBurst` | Animated emoji burst (paw/heart/treat/star) | 111 lines |
| `PfStatTile` | Color-coded stat tile + PfBadgeTile + PfDailyQuestRow | 304 lines |
| `PfAchievementTile` | Achievement badge with locked greyscale state | 95 lines |
| `BoneSlider` | Custom slider with bone-shaped thumb | 197 lines |
| `PawToggle` | Animated toggle with paw emoji thumb | 129 lines |
| `PetfolioEmptyState` | Empty state with icon + title + optional subtitle | 54 lines |

---

## 6. UI/UX Review

### 6.1 Design System

**Strengths:**
- Comprehensive color token system (`AppColors`) with 90+ named tokens across 7 palettes (warm creams, tangerine, poppy, mint, sunny, lilac, sky)
- Full Material 3 ThemeData with `ThemeExtension` (`PetFolioColors`, `PetfolioThemeExtension`) for design tokens in the widget tree
- Glassmorphism card with proper `BackdropFilter` fallback for non-blur environments
- Adaptive typography via Google Fonts (Nunito)
- Consistent border radius scale (4/8/12/16/24/32dp tokens in theme)

**Issues:**

1. **`pc` variable anti-pattern (affects ~20+ locations):** Files extract `Theme.of(context).extension<PetFolioColors>()!` into a local `pc` variable and then immediately suppress the unused warning with `// ignore: unused_local_variable`. The variable is either never used or selectively used. This pattern appears in:
   - `login_screen.dart` (line 46)
   - `care_screen.dart` (lines 47, 108, 144, and more)
   - `social_screen.dart` (lines 108, 267, 390, 457, 491, 673, 888, 917, 944)
   - `matching_screen.dart` (lines 390, 457, 527, 578, 608, 974, 1055, 1105)
   - `seller_dashboard_screen.dart` (multiple)
   Every occurrence where `pc` is unused should be deleted.

2. **Hardcoded colors still present:** Despite the theme system, several screens use raw `Colors.white`, `Colors.black`, `Colors.grey`, `Color(0xFF...)` literals instead of theme tokens. Inconsistent with the design system.

3. **No dark mode testing evidence:** `AppTheme` provides both light and dark instances, but several glassmorphism effects and inline `Color` literals likely don't switch correctly in dark mode.

### 6.2 Layout & Responsiveness

**Strengths:**
- Shell correctly switches bottom pill nav → NavigationRail at 600dp breakpoint
- `LayoutBuilder` used in several screens for adaptive layouts
- `SafeArea` + `SingleChildScrollView` pattern consistently applied

**Issues:**

1. **No tablet / large screen breakpoints beyond 600dp.** At 840dp+ (M3 compact-medium boundary), the NavigationRail shows but screens are often single-column layouts that would benefit from a master-detail split (e.g., MarketplaceScreen, MatchesInboxScreen).

2. **`MarketplaceScreen` grid is hardcoded to 2 columns** (`crossAxisCount: 2`). At wide widths this produces very large cards. Should use `SliverGrid.count` with a dynamic column count based on viewport.

3. **`care_screen.dart` (1923 lines)** is the largest file in the codebase. It contains the main screen, task cards, form sheets, skeletons, and banner widgets all in one file. This makes the file impractical to maintain and violates the stated feature-first structure.

4. **`seller_dashboard_screen.dart` (1217 lines)** has the same problem — screen + multiple tab widgets + modals all in one file.

5. **`matching_screen.dart` (1127 lines)**, **`social_screen.dart` (966 lines)** — same pattern.

### 6.3 Animation & Motion

**Strengths:**
- `flutter_animate` used for staggered entry animations
- Physics-based swipe card with drag offset and rotation — feels natural
- `TailWagLoader` is a delightful branded loading state
- `ReactionBurst` particle effect is polished
- `SkeletonLoader` respects `MediaQuery.disableAnimations` (Reduce Motion)
- Tab color transitions via animated `AnimatedContainer`

**Issues:**

1. **`SkeletonLoader` respects Reduce Motion, but animated transitions on swipe cards and reaction bursts do not.** Any animation longer than ~200ms should check `MediaQuery.disableAnimations`.

2. **Exit animation magic numbers in `matching_screen.dart`:**
   ```dart
   Offset(-size.width * 1.45, size.height * 0.06)
   ```
   These ratios are undocumented. Extract to named constants and document the intent (card exits 1.45× screen width to the left with slight downward drift).

3. **`PetSwitcherSheet` (569 lines)** uses `DraggableScrollableSheet` which works well, but the animation duration for pet switching has no Reduce Motion check.

### 6.4 Typography

**Strengths:**
- Nunito via Google Fonts provides a friendly, pet-appropriate feel
- Local font cache in `google_fonts/` folder (offline-safe)
- Font scales follow M3 type scale

**Issues:**

1. **No explicit `textScaleFactor` / `TextScaler` clamping.** On devices with large accessibility font sizes, some UI elements (stat tiles, care task cards) will likely overflow. Add `MediaQuery.withClampedTextScaling(minScaleFactor: 1.0, maxScaleFactor: 1.3)` at the app root.

2. **`PetSwitcherSheet` pet name truncation** not tested with long names — no `TextOverflow.ellipsis` observed on the pet name label.

### 6.5 Iconography

- Mix of `Icons.*` (Material) and emoji characters (🐾, 🦴, etc.)
- Emoji icons used as feature glyphs in care tasks and product cards — visually inconsistent across platforms (iOS emoji vs Android emoji rendering differs)
- `cupertino_icons` package included but no Cupertino widgets detected in use — can be removed

### 6.6 Empty & Error States

**Strengths:**
- `PetfolioEmptyState` widget exists as a shared component
- `SkeletonLoader` provides loading feedback

**Issues:**

1. **Marketplace silently falls back to demo products on fetch error** — users get no indication that the data failed to load. The fallback hides real errors.

2. **Social feed error state** shows a generic retry button without context.

3. **Matching discovery empty state** (no more candidates) exists but location-denied state shows different messaging per device — not unified.

4. **No offline / no-internet error state** anywhere. Supabase requests will throw `SocketException` which bubbles to `AsyncValue.error` — each screen handles or ignores it differently.

### 6.7 Accessibility

1. **Missing semantic labels on icon-only buttons** — navigation bar icons and action icon buttons lack `Semantics` wrappers or `tooltip` properties.
2. **`PawToggle` and `BoneSlider`** are custom widgets with no `Semantics` role assigned — screen readers won't announce them correctly.
3. **Reaction picker** (emoji tap targets in social feed) has small touch targets — likely below 44×44dp on some reactions.
4. **Color contrast:** The tangerine/cream palette used for stat tiles may not meet WCAG AA at smaller text sizes — untested.

### 6.8 User Flows

**Pet Onboarding (5-step):**
- Flow is well-paced with floating paw animations
- Back navigation from step 1 does not prompt to discard — user may accidentally exit mid-onboarding
- No progress indicator (step dots or progress bar) shown to user

**Care Task Completion:**
- XP burst animation on completion is satisfying
- No confirmation step for destructive task delete (only undo on archive)

**Matching Swipe:**
- Swipe physics feel natural
- "Super Paw" action has no distinct visual differentiation from "Like" at a glance
- No tutorial / first-time overlay for new users (no onboarding for the matching feature)

**Checkout:**
- `process_checkout` RPC is atomic — good
- After checkout, the confirmation screen shows order ID but no ETA or next-steps CTA
- No in-app notification to buyer when vendor ships order (tracking number stored in DB but not surfaced)

**Vendor Onboarding:**
- Clear step-by-step: setup → KYC → products → orders
- KYC rejection reason is stored in DB but vendor sees only "Rejected" status — rejection reason not displayed to vendor in UI

---

## 7. Architecture & Design Pattern Review

### 7.1 State Management (Riverpod)

**Strengths:**
- Consistent use of `StateNotifierProvider` / `NotifierProvider` / `FutureProvider` / `StreamProvider`
- Repository providers injected into notifiers via `ref.watch`
- `AsyncValue.when()` for loading/data/error in UI layer
- `skipLoadingOnReload: true` used in care dashboard to prevent flash-of-loading on refresh

**Issues:**

1. **Mixed Riverpod generations.** Some providers use the legacy `StateNotifierProvider` pattern; others use `@riverpod` annotation with code generation (`my_shop_controller.g.dart`, `care_dashboard_controller.g.dart`). This inconsistency makes the codebase harder to navigate and the two patterns have different capabilities (e.g., `invalidate` behavior differs).

2. **No provider scoping.** All providers are global. For multi-pet scenarios, providers like `careDashboardProvider` are presumably re-fetched when the active pet changes, but if a provider holds state from a previous pet and the key doesn't change, stale data can be shown briefly.

3. **`active_pet_controller.dart` syncs active pet from SharedPreferences on startup but doesn't invalidate downstream providers (care, social, matching) when the active pet changes.** This is a potential source of data belonging to Pet A being shown while Pet B is active.

### 7.2 Navigation (GoRouter)

**Strengths:**
- `StatefulShellRoute` with `StatefulShellBranch` correctly maintains tab state
- Auth redirect in `_RouterNotifier.redirect()` is correct
- Token refresh handling explicitly skips notifying to avoid spinner on 55-min rotation

**Issues:**

1. **Tab colors array is index-coupled to route order:**
   ```dart
   const _tabColors = [AppColors.tangerine, AppColors.sunny, ...];
   ```
   Reordering tabs silently breaks color assignment. Use a map keyed by route name.

2. **`_destinations` array** (nav bar items) has the same fragile index coupling to routes.

3. **Deep link handling** — no Universal Link / App Link configuration detected. External URLs (e.g., `/market/product/:id` from a share link) will not open the app.

4. **Admin routes are not guarded by a separate route guard.** The `AdminScreen` widget itself checks `isAdminProvider`, but the route `/admin` is accessible without any redirect guard. A non-admin user who navigates to `/admin` sees the "Access Denied" widget only after the route resolves. Should add a redirect in `_RouterNotifier`.

### 7.3 Repository Pattern

**Strengths:**
- Clear separation of data access from presentation
- RPC calls used for complex multi-table operations (avoiding N+1 queries)
- `try/catch` with domain exception wrapping in most repositories

**Issues:**

1. **No repository interfaces.** Concrete repository classes are injected directly. This makes mocking for tests impossible without the `mockito` / `mocktail` package + manual setup. Consider adding abstract interfaces if testing becomes a priority.

2. **`care_repository.dart` is a stub** (`export 'pet_care_repository.dart'`) — the actual implementation is in `pet_care_repository.dart` (840 lines). The stub creates a misleading import path.

3. **`social_repository.dart` (449 lines)** has a `_rowToFeedPost` method that silently falls back to empty maps when pet/user joins are missing. This masks DB join misconfigurations.

4. **Demo product fallback in `product_repository.dart`** silently returns hardcoded demo products on any Supabase error. Errors should be surfaced, not hidden.

### 7.4 Code Generation

- Freezed + JsonSerializable for models — correctly applied
- Riverpod Generator for some providers — inconsistently applied (see 7.1)
- Generated `.g.dart` / `.freezed.dart` files committed to repo — correct for Flutter

### 7.5 File Size Violations

Files exceeding 500 lines (should be split):

| File | Lines | Action |
|------|-------|--------|
| `care_screen.dart` | 1923 | Split into screen + task card + form sheet + banners |
| `seller_dashboard_screen.dart` | 1217 | Split into screen + tab widgets |
| `matching_screen.dart` | 1127 | Split into screen + swipe card + preferences + inbox |
| `pet_care_repository.dart` | 840 | Consider splitting into care tasks / health / gamification repos |
| `onboarding_screen.dart` | 842 | Split step widgets into separate files |
| `social_screen.dart` | 966 | Split into screen + post card + story strip |
| `app_theme.dart` | 735 | Acceptable — theme definitions are necessarily verbose |
| `router.dart` | 702 | Split route definitions into feature-specific builders |
| `pet_switcher_sheet.dart` | 569 | Acceptable for a complex bottom sheet |
| `manage_pets_screen.dart` | 781 | Split reorderable list logic from screen scaffold |

---

## 8. Security & Auth Review

### 8.1 Authentication

| Area | Status | Notes |
|------|--------|-------|
| Email/password auth | ✅ Supabase GoTrue | Correct implementation |
| Session persistence | ✅ Supabase handles | JWT auto-refresh |
| Password reset | ✅ Email link | Correct |
| Token refresh optimization | ✅ Skips notify | Good, prevents spinner loop |
| HaveIBeenPwned protection | ❌ Disabled | Enable in Supabase Auth settings |
| Auth on navigation | ✅ GoRouter redirect | Guards all protected routes |

### 8.2 API Keys & Secrets

**HIGH RISK:** Supabase URL and anon key are hardcoded as default values in `main.dart`:
```dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
    defaultValue: 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
    defaultValue: '...');  // Full anon key in source
```
The Supabase anon key in source is acceptable (it is public by design and protected by RLS), but the URL exposes the project ID. More critically:

**CRITICAL:** If a Stripe publishable key default is also hardcoded in `main.dart`, it will be embedded in release APKs and visible via reverse engineering. Publishable keys are less sensitive than secret keys, but should not be in source. Use `--dart-define-from-file=.env` for all builds.

### 8.3 Row Level Security (RLS)

- All 31 tables have RLS enabled — excellent
- `is_admin()` function drives admin-table access — see gap below
- Realtime subscriptions on `matches`, `care_streaks`, `chat_messages` — RLS applies to realtime too (Supabase handles this)

**Gaps:**

1. **Admin role is application-level, not JWT-claim-level.** The `is_admin()` DB function is called at query time. If an attacker obtains a valid session token for a non-admin user, they cannot access admin-gated data (RLS blocks it). However, the admin UI route is not redirect-guarded — it renders an "Access Denied" widget rather than redirecting. This is cosmetic but should be fixed.

2. **`comments.author_id` references `auth.users.id`** (not `public.users.id`). This is inconsistent with how other tables reference users. The RLS policy on `comments` must use `auth.uid()` directly — verify this is intentional and that the policy is correct.

3. **`follows.follower_id` and `follows.following_id` both reference `auth.users.id`** — same inconsistency. The `pet_follows` table correctly uses `public.pets.id`. Two follow systems (`follows` for user-user, `pet_follows` for pet-pet) add complexity and potential RLS surface area.

4. **`stories.viewed_by_users` is a UUID array** — `mark_story_viewed` appends the current user UUID. If not properly RLS-protected for writes, any user could add any UUID to any story's viewer list. Verify the RPC runs with `SECURITY DEFINER` and validates `auth.uid()`.

5. **`bank_account_details` stored as plain JSONB in `shops` table.** This should be encrypted at rest or, preferably, not stored at all (store only a Stripe bank account token). Storing raw bank details in a PostgreSQL column is a PCI-DSS concern.

### 8.4 Payment Security

1. **No Stripe webhook verification.** After `process_checkout` creates a `PaymentIntent`, the client calls `stripe.confirmPayment()` and then optimistically marks the order as paid. There is no server-side webhook that Stripe calls to confirm actual payment capture. An attacker could intercept and modify the client-side confirmation flow.

2. **`vendor_ledgers` has 0 rows** despite 11 orders. If `process_checkout` is supposed to populate ledger entries, it is not doing so. Vendor payouts are therefore untracked.

3. **Inventory reservation expiry (15 minutes)** is correctly configured. `release_order_inventory` RPC handles cleanup. The `fix_confirm_order_expired_reservations` migration name suggests this was buggy previously — verify current behavior.

---

## 9. Data Consistency & Business Logic

### 9.1 Schema Inconsistencies

| Issue | Tables Affected | Severity |
|-------|----------------|----------|
| `author_id` in `comments` refs `auth.users`, all others ref `public.users` | `comments`, `reported_posts`, `follows`, `shop_deletion_requests` | Medium |
| Two follow systems: `follows` (user→user) and `pet_follows` (pet→pet) — social profile shows pet follows but `social_repository` uses both | `follows`, `pet_follows` | Medium |
| Two matching systems: `swipes`/`matches` (Tinder-style) and `match_requests` (playdate/breeding/adoption workflow) — UI conflates them | `swipes`, `matches`, `match_requests` | High |
| `chat_threads` has both `match_request_id` and `mutual_match_id` FKs — two creation pathways not fully reconciled | `chat_threads`, `match_requests`, `matches` | High |
| `post_candles` referenced in CLAUDE.md doesn't exist (removed in migration) | — | Low (doc only) |

### 9.2 Business Logic Gaps

1. **Dual matching systems:** `swipes`/`matches` implement a Tinder-style swipe flow (LIKE/PASS/GREET/SUPER_PAW). `match_requests` implements a request-and-accept flow (playdate/breeding/adoption). These appear to be two separate features, but the discovery UI (`matching_screen.dart`) drives swipes, and accepted swipes create `matches` rows, not `match_requests`. The 16 `match_requests` rows were likely created via a different path. Clarify intended product behavior.

2. **`vendor_ledgers` never populated.** The `process_checkout` RPC creates orders and reserves inventory, but ledger entries are missing. Vendor earnings are untracked. This must be fixed before any real vendor payout.

3. **`notifications` table not wired to UI.** 4 notification rows exist in DB. The `NotificationsScreen` exists. The `notification_repository.dart` and `notification_controller.dart` exist. But the notification bell in `AppHeader` and the count badge are not connected to the live count. Users never see their notifications.

4. **Comment reply threading.** `comments.parent_id` exists in DB (and even has `comment_likes` support). The UI has no reply button or threaded display. This is dead DB schema.

5. **`health_vitals` vs `health_logs`.** Two separate health tracking tables exist: `health_vitals` (numeric vitals: weight, temperature, heart_rate, etc.) and `health_logs` (narrative logs: symptom, vet_visit, medication, etc.). Only `health_logs` has UI (`MedicalVaultScreen`). `health_vitals` has 5 rows but no UI or repository implementation.

6. **Story expiry.** `cleanup_expired_stories` RPC exists but there is no cron job or trigger calling it. Stories will never be cleaned up unless the RPC is called explicitly or via a scheduled Supabase Edge Function.

7. **`inventory_count` on `products` starts at 0** for newly created products (default). A vendor who creates a product without explicitly setting inventory will immediately have out-of-stock behavior. No UI warning for 0-inventory products.

8. **Care task `is_completed` flag** is a column on `care_tasks`, but actual completion tracking uses `care_logs`. The `is_completed` column on the task itself appears redundant and may become stale (e.g., a task completed today will show `is_completed: false` tomorrow). The `get_care_dashboard_snapshot` RPC should be the source of truth.

### 9.3 Active Pet Context Race Condition

`ActivePetController` loads active pet ID from SharedPreferences, then waits for `petListProvider` to resolve. If the previously-active pet was archived or deleted, the controller falls back to the first pet. However, care/social/matching providers that watch `activePetIdProvider` may fire with the stale pet ID before the fallback resolves, causing a brief flash of wrong-pet data.

---

## 10. Duplicate / Deprecated Code

### 10.1 Deprecated / Dead Code

| Location | Issue |
|----------|-------|
| `lib/marionette_debug_gate_io.dart` + `_stub.dart` | Conditional import for Marionette testing framework — only used in `main.dart`. Not a bug, but adds confusion for non-Marionette contributors |
| `care/data/repositories/care_repository.dart` | 2-line stub that only re-exports `pet_care_repository.dart`. The stub adds an indirection layer with no benefit |
| `pet_care_repository.dart` export of `care_repository.dart` | Circular-feeling: `care_repository.dart` exports `pet_care_repository.dart`, and `pet_care_repository.dart` is imported directly in controllers anyway |
| `post_candles` references in CLAUDE.md | Feature removed in migration `remove_memorial_feature`. All CLAUDE.md references are stale |
| `health_vitals` table + model | 5 rows in DB, model exists in `care/data/models/`, no repository or UI. Either implement or drop |
| `auth/data/models/.gitkeep` and `auth/data/repositories/.gitkeep` | Empty placeholder directories — clutter |
| `cupertino_icons` in `pubspec.yaml` | Imported but no `CupertinoIcons` usage detected in the codebase |

### 10.2 Duplicate Implementations

| Pattern | Locations | Recommendation |
|---------|-----------|----------------|
| `pc = Theme.of(context).extension<PetFolioColors>()!` | 20+ locations with `// ignore: unused_local_variable` | Delete all unused extractions; keep only where `pc` is actually used |
| PostgreSQL error code `23505` handling | `social_repository.dart`, likely others | Extract to a `SupabaseErrorCodes` utility class |
| Time-ago string formatting | `social_repository.dart` + `FeedPost.timeAgo` field | Consolidate in one place |
| Pet species → color mapping | `PetAvatar` (species-based ring color) + `social_repository.dart` (accent color palette) | Both map species to colors independently |
| `_friendlyAuthError()` | `login_screen.dart` | Good; keep isolated to auth |

### 10.3 Riverpod Pattern Inconsistency

| Pattern | Files Using It |
|---------|---------------|
| Legacy `StateNotifierProvider` + `StateNotifier<T>` | auth, care, matching (most files) |
| New `@riverpod` annotation + code generation | `theme_notifier.dart`, `care_dashboard_controller.dart`, `my_shop_controller.dart` |

Both patterns work, but mixing them in the same codebase creates inconsistency. Decide on one and migrate.

---

## 11. Critical Findings & Priority Matrix

### P0 — Fix Immediately (Production Risk)

| # | Finding | Impact |
|---|---------|--------|
| 1 | **Stripe webhook missing** — payment confirmation is client-side only | Orders may be created without actual payment capture; revenue loss risk |
| 2 | **`vendor_ledgers` never populated** — 11 orders, 0 ledger entries | Vendor payouts are untracked; financial integrity broken |
| 3 | **`bank_account_details` stored as plain JSONB** in `shops` | PCI-DSS risk — sensitive financial data unencrypted in DB |
| 4 | **`story_cleanup` RPC has no scheduler** — stories never expire | DB bloat + GDPR risk (user content not deleted as advertised) |

### P1 — Fix Before Next Release

| # | Finding | Impact |
|---|---------|--------|
| 5 | **Admin route not redirect-guarded** — non-admins reach `/admin` route before being denied | Minor security UX issue |
| 6 | **`notifications` table not wired to UI** — users never see their notifications | Core feature broken |
| 7 | **Dual matching systems** (`swipes`/`matches` vs `match_requests`) unclear relationship | Product confusion, potential duplicate data |
| 8 | **`chat_threads` dual FK** (`match_request_id` + `mutual_match_id`) not reconciled | Data integrity risk — threads may be created via two paths |
| 9 | **`health_vitals` orphaned** — 5 DB rows, no UI, no repository | DB schema waste; users cannot access health data |
| 10 | **`inventory_count` defaults to 0** — new products immediately out-of-stock | Bad vendor UX, potential lost sales |
| 11 | **CLAUDE.md severely outdated** — describes 12 tables, mock data, missing features that are actually live | Dev team working with false picture of app status |

### P2 — Technical Debt

| # | Finding | Impact |
|---|---------|--------|
| 12 | **`care_screen.dart` (1923 lines)** monolithic | Unmaintainable, causes slow IDE indexing |
| 13 | **`seller_dashboard_screen.dart` (1217 lines)** monolithic | Same |
| 14 | **`pc` unused variable pattern** (20+ files) | Code noise, suppressed analyzer warnings |
| 15 | **Mixed Riverpod generations** | Inconsistency, onboarding friction |
| 16 | **No repository interfaces** | Untestable |
| 17 | **Demo product fallback hides errors** | Silent failures mislead developers |
| 18 | **`care_repository.dart` stub** | Misleading import path |
| 19 | **Router tab colors/destinations index-coupled** | Fragile — reorder = silent bug |
| 20 | **`cupertino_icons` unused** | Unnecessary package dependency |
| 21 | **`auth/data/models/` and `auth/data/repositories/` empty dirs** | Clutter |
| 22 | **Active pet context race condition** | Brief flash of wrong-pet data |

### P3 — UX Polish

| # | Finding | Impact |
|---|---------|--------|
| 23 | **No Reduce Motion checks on swipe/burst animations** | Accessibility compliance |
| 24 | **No `textScaleFactor` clamping** | Large-font users see overflow |
| 25 | **No deep link / Universal Link config** | Share links don't open app |
| 26 | **Tablet >840dp not fully adaptive** | Layout doesn't use available space |
| 27 | **KYC rejection reason not shown to vendor** | Vendor can't understand or appeal rejection |
| 28 | **Marketplace 2-column grid fixed** | Poor on wide screens |
| 29 | **`PawToggle` / `BoneSlider` missing Semantics** | Screen reader inaccessible |
| 30 | **No onboarding tutorial for Matching tab** | New users confused by swipe UI |

---

*Review covers: 193 Dart source files, 31 DB tables, 29 RPC functions, 78 migrations, 40+ routes. Generated 2026-05-26.*
