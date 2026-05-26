# Petfolio — Comprehensive Codebase & UX Review
> Generated: 2026-05-27 | Reviewed against live DB: `jqyjvhwlcqcsuwcqgcwf` (ap-northeast-1)

---

## Table of Contents
1. [Modules, Features & Live DB Status](#1-modules-features--live-db-status)
2. [UI Screens & Component Map](#2-ui-screens--component-map)
3. [UI/UX Review](#3-uiux-review)
4. [Architecture & Design Pattern Review](#4-architecture--design-pattern-review)
5. [Security & Auth Review](#5-security--auth-review)
6. [Data Consistency & Business Logic](#6-data-consistency--business-logic)
7. [Duplicate / Deprecated Code](#7-duplicate--deprecated-code)
8. [Prioritised Fix List](#8-prioritised-fix-list)

---

## 1. Modules, Features & Live DB Status

### 1.1 Feature Inventory

| Feature | Path | Screens | Controllers | Repositories | DB Tables Used |
|---------|------|---------|-------------|--------------|----------------|
| **Auth** | `features/auth` | login, register | auth_controller | auth_repository | auth.users |
| **Pet Profile** | `features/pet_profile` | pet_profile, manage_pets, onboarding, edit_profile | active_pet, discovery_visibility, edit_profile, pet_list | pet_repository | pets, users |
| **Care** | `features/care` | care, medical_vault, nutrition | care_controller, care_dashboard, care_streak_stream, health_vault, nutrition, pet_awards | care_repository _(stub)_, pet_care_repository, checklist_repository, health_repository | care_tasks, care_logs, care_streaks, pet_badges, pet_care_gamification, health_logs, medical_vault, health_vitals _(orphaned)_ |
| **Social** | `features/social` | social, create_post, create_story, notifications, post_detail, social_profile, story_viewer | comment, create_post, follow, notification, social, social_profile, story | social_repository, comment_repository, notification_repository, story_repository | posts, post_likes, comments, comment_likes, stories, pet_follows, follows, notifications |
| **Matching** | `features/matching` | matching, matches_inbox, chat | chat_conversation, chat_threads, discovery_candidates, discovery, match_preference, matches_inbox, mutual_match_realtime | matching_repository | swipes, matches, match_requests, chat_threads, chat_messages |
| **Marketplace** | `features/marketplace` | marketplace, cart, product_detail, order_confirmation, buyer_order_list, buyer_order_detail, shop_storefront, seller_dashboard, shop_setup, stripe_onboarding, edit_shop, manual_kyc, vendor_order_queue, vendor_order_detail, vendor_product_list, add_edit_product | buyer_orders, cart, checkout, deletion_request, edit_shop, manual_kyc, my_shop, product_list, shop_list, shop_products, vendor_orders, vendor_products | kyc_repository, order_repository, product_repository, shop_repository, vendor_product_repository | products, shops, marketplace_orders, vendor_ledgers _(empty)_, inventory_reservations, shop_deletion_requests |
| **Admin** | `features/admin` | admin_screen, admin_layout | admin_auth, admin_dashboard, cod_orders, kyc_review, ledger, moderation, shop_deletion | admin_repository | audit_logs, reported_posts, marketplace_orders, shops |

### 1.2 Live DB Summary (confirmed via Supabase MCP)

| Table | Rows | UI Status | Notes |
|-------|------|-----------|-------|
| users | 10 | ✅ Connected | `public_key` column exists — unused in app |
| pets | 23 | ✅ Connected | `accent_color` default `#FF6B9D` — used for theming |
| care_tasks | 136 | ✅ Connected | — |
| care_logs | 115 | ✅ Connected | — |
| care_streaks | 7 | ✅ Connected | — |
| pet_badges | 11 | ✅ Connected | — |
| pet_care_gamification | 7 | ✅ Connected | — |
| health_logs | 15 | ✅ Connected | — |
| medical_vault | 2 | ✅ Connected | — |
| **health_vitals** | **5** | ❌ **No UI** | Orphaned — weight/temperature/heart_rate data inaccessible |
| posts | 13 | ✅ Connected | — |
| post_likes | 42 | ✅ Connected | — |
| comments | 31 | ✅ Connected | `parent_id` exists for threading — no reply UI |
| comment_likes | 3 | ✅ Connected | — |
| stories | 8 | ✅ Connected | No cleanup scheduler |
| pet_follows | 6 | ✅ Connected | `follower_pet_id`/`following_pet_id` NULLABLE — schema bug |
| follows | 4 | ✅ Connected | `follower_id`/`following_id` NULLABLE — schema bug; uses `auth.users` FK |
| **notifications** | **4** | ⚠️ **DB live, bell not wired** | Repository and controller exist but bell count not connected |
| reported_posts | 0 | ✅ Admin UI | — |
| swipes | 118 | ✅ Connected | — |
| matches | 20 | ✅ Connected | — |
| match_requests | 16 | ✅ Connected | Separate system from swipes — not surfaced in discovery flow |
| chat_threads | 17 | ✅ Connected | Dual FK: mutual_match_id OR match_request_id |
| chat_messages | 34 | ✅ Connected | — |
| products | 11 | ✅ Connected | `inventory_count` defaults to 0 |
| shops | 7 | ✅ Connected | `bank_account_details` plain JSONB — security risk |
| marketplace_orders | 11 | ✅ Connected | No Stripe webhook verification |
| **vendor_ledgers** | **0** | ❌ **Never populated** | `process_checkout` RPC missing ledger insert |
| inventory_reservations | 3 | ✅ Connected | 15-min expiry |
| shop_deletion_requests | 2 | ✅ Connected | — |
| audit_logs | 6 | ✅ Connected | — |

### 1.3 RPC Functions (29 confirmed)
All 29 functions confirmed live. Key gap: `cleanup_expired_stories` has no caller (no Edge Function cron).

---

## 2. UI Screens & Component Map

### 2.1 Screen Inventory

#### Auth Flow
- `LoginScreen` — email/password form, forgot-password bottom sheet, link to register
- `RegistrationScreen` — username, email, password, display name

#### Shell (Tab Navigation)
- `AppShell` — floating pill nav (mobile ≤599dp) / NavigationRail (tablet ≥600dp)
  - Tab 1: **Pets** (tangerine) → `/home`
  - Tab 2: **Care** (sunny/yellow) → `/care`
  - Tab 3: **Social** (poppy/red) → `/social`
  - Tab 4: **Match** (lilac/purple) → `/matching`
  - Tab 5: **Market** (mint/green) → `/marketplace`

#### Pet Profile Feature (`/home`)
- `PetProfileScreen` — hero gamified banner, quick stats trio, today's quests preview, awards section, pet switcher
- `ManagePetsScreen` — drag-to-reorder, archive, add new pet
- `OnboardingScreen` — 5-step pet creation flow with animations
- `EditProfileScreen` — avatar upload, bio, species, breed, DOB, weight, discoverability toggle

#### Care Feature (`/care`)
- `CareScreen` — task checklist, streak display, gamification, routine generator, pet switcher (1923 lines — needs splitting)
- `MedicalVaultScreen` — vaccines, medications, allergies, surgeries with expiry
- `NutritionScreen` — nutrition tracking

#### Social Feature (`/social`)
- `SocialScreen` — paginated feed, stories rail, reaction bursts, pet avatar
- `CreatePostScreen` — multi-image post creation
- `CreateStoryScreen` — story image creation
- `PostDetailScreen` — post with comments (flat, no threading)
- `SocialProfileScreen` — pet profile with followers/posts
- `NotificationsScreen` — exists but not connected to live bell count
- `StoryViewerScreen` — full-screen story viewer with 24h filter

#### Matching Feature (`/matching`)
- `MatchingScreen` — PostGIS geo-based swipe deck, location permission gate, preferences sheet, match celebration overlay
- `MatchesInboxScreen` — list of matched chats
- `ChatScreen` — real-time DM with Supabase realtime

#### Marketplace Feature (`/marketplace`)
- `MarketplaceScreen` — category chips, product grid, fly-to-cart animation, cart drawer
- `ProductDetailScreen` — product images, description, add to cart
- `CartScreen` — cart items, checkout button
- `OrderConfirmationScreen` — post-checkout success
- `BuyerOrderListScreen` → `BuyerOrderDetailScreen` — order history
- `ShopStorefrontScreen` — public shop page
- `SellerDashboardScreen` — vendor hub (1217 lines — needs splitting)
- `ShopSetupScreen` / `EditShopScreen` — shop creation/editing
- `StripeOnboardingScreen` — Stripe Connect WebView flow
- `ManualKycScreen` — document upload for manual KYC
- `VendorProductListScreen` → `AddEditProductScreen` — vendor product CRUD
- `VendorOrderQueueScreen` → `VendorOrderDetailScreen` — vendor order fulfillment

#### Admin Feature (`/admin`)
- `AdminScreen` → `AdminLayout` — tabbed: Dashboard, KYC Approvals, Moderation, Financial Ledger, Orders, Shops

### 2.2 Core Widget Library (19 widgets)

| Widget | Quality | Notes |
|--------|---------|-------|
| `PetAvatar` | ✅ Good | CachedNetworkImage with fallback initials |
| `GlassCard` | ✅ Good | BackdropFilter + ThemeExtension glass tokens |
| `PfCard` | ✅ Good | Themed card with border |
| `PrimaryPillButton` | ✅ Good | Stadium-border button with accent color |
| `SkeletonLoader` | ✅ Good | Shimmer placeholders |
| `TailWagLoader` | ✅ Good | Branded loading animation |
| `WaveHeader` | ✅ Good | Custom painter wave decoration |
| `PetfolioEmptyState` | ✅ Good | Icon + title + subtitle |
| `PfStatTile` | ✅ Good | Stat display with label |
| `PfAchievementTile` | ✅ Good | Badge/achievement display |
| `ResponsiveLayout` | ✅ Good | Mobile/tablet/desktop breakpoints |
| `BoneSlider` | ✅ Good | Themed slider |
| `PawToggle` | ✅ Good | Paw-themed toggle |
| `AppBottomSheet` | ✅ Good | Consistent bottom sheet |
| `AppHeader` | ✅ Good | Screen header |
| `AppSnackBar` | ✅ Good | Global snackbar key |
| `DashedCirclePainter` | ✅ Good | Custom painter |
| `DashedRectPainter` | ✅ Good | Custom painter |
| `ReactionBurst` | ✅ Good | (in social) Particle animation |

---

## 3. UI/UX Review

### 3.1 Design System

**Strengths:**
- Comprehensive token system: 90+ color constants in `AppColors`, full light/dark variants for every token
- `PetfolioThemeExtension` properly implements `ThemeExtension<T>` with `lerp()` and `copyWith()` — smooth theme transitions
- Material 3 `ColorScheme.fromSeed` base with manual overrides — correct approach
- Dual typeface: **Sora** (headings — character, warmth) + **Inter** (body — legibility) — well-chosen pairing
- Typography scale covers all 15 M3 slots with appropriate size/weight/color per role
- Radius tokens: xs(6) → pill(999); Duration tokens: xs(80ms) → xl(500ms) — design system completeness
- Button height tokens (36/44/52/60/64) for consistent touch targets
- Glassmorphism tokens (fill, top border, rim, shine, blur sigma) — enables consistent glass effect

**Issues:**
1. **`pillarHealth` and `pillarMarket` both resolve to `mint`** in `PetfolioThemeExtension`. Health and Marketplace are distinct pillars but share a color token name — the distinction isn't encoded in the token, which will confuse future work.
2. **Backward-compat color aliases** (`blue50`, `blue100`…`blue700`, `sunset500`, `coral500`, etc.) still in `AppColors` — 20+ stale aliases bloat the file and create confusion about which token to use. Should be removed once all callers are migrated.
3. **NavigationRail inconsistency**: `AppTheme._build()` sets `indicatorColor: tangerineSoft` for the nav rail, but `_WideNavRail` in `router.dart` explicitly passes `indicatorColor: Colors.transparent` — this overrides the theme and makes the rail look flat on tablet.
4. **`AppThemeSpacing`** defines xs=4, sm=8, md=12, lg=16, xl=24 — but `xl` skips 20 (there's no `2xl`). Inconsistent with the radius scale which has xs/sm/md/lg/xl/2xl/3xl. Gap in spacing vocabulary.

### 3.2 Navigation & Shell

**Strengths:**
- Floating pill nav is visually distinctive, fits the warm/playful brand
- Per-tab accent colors (tangerine/sunny/poppy/lilac/mint) give strong spatial identity
- `AnimatedContainer` on tab pill chip (200ms) — smooth selection indicator
- `NoTransitionPage` on shell tabs — correct, prevents cross-fade flicker on tab switch
- Auth redirect properly handles: unauthenticated → /login, no pets → /onboarding, admin guard
- `skipLoadingOnReload: true` on pet list — prevents spinner on token refresh

**Issues:**
1. **`_tabColors` and `_destinations` arrays are positionally coupled** — if a tab is reordered, the color assignment silently breaks. Should be `Map<String, Color>` keyed by path.
2. **Shell content overlaps floating nav**: The `Stack` layout with `Positioned.fill` means screen content can scroll under the nav bar. Screen implementations must manually add `MediaQuery.paddingOf(context).bottom + 80` bottom padding to their scroll content — this is not enforced anywhere and screens will have content cut off.
3. **No haptic feedback** on tab selection — standard mobile UX expectation, especially for a pet/lifestyle app.
4. **`_NavTab` uses `GestureDetector`** not `InkWell`/`FilledButton` — no ripple feedback on tap.
5. **`/matching/inbox`** requires navigating away from the Match tab — there's no inbox counter badge on the tab icon to indicate unread matches.

### 3.3 Auth Screens

**Strengths:**
- Password reset via bottom sheet is clean UX (no full screen navigation)
- Form validation with regex before submission
- `_ForgotPasswordSheet` disposes controller and resets provider on close — correct

**Issues:**
1. **No input type hinting**: Email field should use `TextInputType.emailAddress`, password field `TextInputType.visiblePassword`. These affect mobile keyboard type.
2. **No "show/hide password" toggle** — standard UX for password fields.
3. **Error display** relies on SnackBar — error messages for wrong credentials may disappear before user reads them. Inline field error messages would be better.
4. **No biometric/passkey auth** — missed opportunity for return users.

### 3.4 Pet Profile Screen

**Strengths:**
- `_HeroGamifiedBanner` with pet avatar, accent color, streak + XP display — cohesive hero
- `_QuickStatsTrio` — compact at-a-glance stats
- Today's quests preview in /home — good cross-feature surface

**Issues:**
1. **Content clips under floating nav** — `CustomScrollView` in `PetProfileScreen` doesn't add bottom padding. Last quest item is hidden behind the nav bar.
2. **No pull-to-refresh** on pet profile — user must navigate away and return to see updates.
3. **`_PetEditMissingScreen`** is a bare-bones fallback with no navigation back to the pet list — it only offers "Back to Pets" via `/home`. If the pet was deleted mid-session, the UX dead-ends.

### 3.5 Care Screen

**Issues:**
1. **1923 lines** — largest file in the codebase. Should be split into: `_CareTaskList`, `_CareStreakHeader`, `_GamificationSection`, `_RoutineGeneratorButton`.
2. **`_init()` is empty** (just a comment). The `Future.microtask` + `_init()` setup adds indirection for no purpose.
3. **Onboarding snackbar** shows then immediately calls `context.go('/care')` — on slow devices there's a race condition where the snackbar appears on the care screen but the navigation clears it.
4. **`_isGeneratingRoutine` state is local to `_CareScreenState`** but should be in the controller so it survives rebuilds.
5. **No empty state for nutrition screen** — `NutritionScreen` has no documented DB backing (no nutrition table in schema) — may be placeholder.

### 3.6 Social Screen

**Issues:**
1. **No notification badge on the bell icon** — `notifications` table has rows, repository exists, controller exists, but the badge count is not surfaced anywhere.
2. **Story expiry**: The screen queries stories but may not filter `created_at > now() - interval '24 hours'` if `story_repository.dart` doesn't apply the filter — expired stories may appear.
3. **Comment threading not implemented** — `comments.parent_id` is in DB (31 rows, no replies used), but the UI renders all comments flat. The reply button is missing.
4. **Post visibility selector** (`public`/`followers`/`private`) — schema has three values but it's unclear if the create-post UI exposes all three.
5. **`dart:math` imported** but `Random()` usage is only for story ring color variation — minor but imports should be justified.

### 3.7 Matching Screen

**Issues:**
1. **`_isLocationBlocked()` is a module-level function**, not a private method or extension. This is an unusual Dart pattern; it should be an extension or method on the widget.
2. **Location error parsing uses string matching** (`message.contains('blocked')`) — brittle. Should use typed `PermissionStatus` values.
3. **`GREET` and `SUPER_PAW` swipe actions** are in DB (`swipes.action` enum) but there's no indication in the UI that these are different from `LIKE` — the visual distinction (if any) is not documented.
4. **Match inbox is behind an extra navigation step** (`/matching/inbox`) — users can miss new matches. Should surface inbox count on the Match tab icon.
5. **No empty state for exhausted candidate deck** — when all nearby pets have been swiped, what does the user see?

### 3.8 Marketplace Screen

**Strengths:**
- Fly-to-cart animation using `Rect` tracking — delightful UX detail
- Cart drawer via `showModalBottomSheet` with `useRootNavigator: true` — correct for shell route
- Category chip filtering — clean
- `constraints: BoxConstraints(maxWidth: 560)` on cart drawer — prevents full-width stretching on tablet

**Issues:**
1. **Offset-based pagination** for products: `product_repository.dart` documents the risk of duplicates/skips on live data — this should use cursor-based (created_at + id) pagination.
2. **`inventory_count` defaults to 0** — products with zero inventory are still displayed to buyers (query only filters `active = true`). Buyers can add OOS items to cart.
3. **Cart persisted to `SharedPreferences`** — cart survives app restarts but is not server-side. If a product is deleted, the cart will have a dangling reference.
4. **No vendor badge/verified indicator** on product cards or shop storefront.
5. **`SellerDashboardScreen` is 1217 lines** — needs splitting into tab widgets.

### 3.9 Admin Screen

**Issues:**
1. **Admin route now has GoRouter redirect guard** (✅ fixed — `_RouterNotifier.redirect()` returns `/home` for non-admins). Previously documented as a gap — confirmed fixed.
2. **`vendor_ledgers` has 0 rows** — Financial Ledger tab will always show empty state. This is a backend bug not a UI bug, but the tab should show a meaningful message rather than appearing broken.
3. **KYC rejection reason** stored in `shops.rejection_reason` column but not displayed to the vendor in the seller dashboard UI.

### 3.10 Responsiveness

| Breakpoint | Behavior | Issues |
|-----------|---------|--------|
| < 600dp (mobile) | Floating pill nav, single-column layouts | Content clips under nav in most screens |
| ≥ 600dp (tablet) | NavigationRail, some 2-column layouts | `indicatorColor: Colors.transparent` on rail looks flat |
| ≥ 840dp (desktop) | ResponsiveLayout used in some screens | Not all screens adapt — marketplace/care use simple column |

### 3.11 Animation & Motion

**Strengths:**
- Duration token system (80/140/220/320/500ms) — appropriately scaled
- `AnimatedContainer` on nav pill — 200ms
- `TailWagLoader` branded animation
- `ReactionBurst` particle system for post likes
- Fly-to-cart animation in marketplace
- Match celebration overlay

**Issues:**
1. **No page transition animations** on full-screen routes — `MaterialPageRoute` default slide-up exists but no custom transitions for thematic coherence.
2. **No shared element transitions** (Hero widgets) for pet avatar → detail screens — lost opportunity for perceived performance.

### 3.12 Accessibility

**Issues:**
1. **`GestureDetector` on nav tabs** has no `Semantics` wrapper — screen readers cannot identify tab names.
2. **`PetAvatar`** should include `semanticLabel` from the pet name.
3. **Color contrast**: `ink500` (#957762) on `cream` (#FFF4E6) is approximately 2.8:1 — **fails WCAG AA** (requires 4.5:1 for normal text, 3:1 for large text). Muted text color used widely.
4. **Touch targets**: Nav tabs are ~60dp wide × 68dp tall — acceptable, but icon+label stack may be too small on small phones.
5. **No keyboard navigation** support (relevant for tablets with physical keyboards).

---

## 4. Architecture & Design Pattern Review

### 4.1 State Management

**Riverpod Pattern Mixing:**

```
StateNotifierProvider (legacy) — used in: auth, social, matching, marketplace, pet_profile
@riverpod generator — used in: theme_notifier, care_dashboard_controller, my_shop_controller
```

This is a maintenance hazard. `StateNotifierProvider` is deprecated in Riverpod 3.x. The migration to `@riverpod` annotation pattern is partially done but stalled.

**Provider Invalidation:**
- `petListProvider` and `isAdminProvider` are correctly invalidated on auth state change
- `careDashboardProvider` uses `skipLoadingOnReload: true` — correct
- `socialController` uses `AsyncValue.guard` — correct pattern

**Issues:**
1. **`care_streak_stream_provider.dart` duplicates streak data** already loaded by `get_care_dashboard_snapshot` RPC. Two network paths for the same data.
2. **`pet_awards_provider.dart` calls `get_pet_awards_summary` RPC separately** when awards are already in the dashboard snapshot — redundant fetch.
3. **`social_profile_controller.dart` and `social_controller.dart`** both load post data — ensure they don't issue duplicate queries for the same pet.

### 4.2 Repository Layer

**Strengths:**
- Repository-per-feature pattern is consistent
- RPC functions used for multi-table operations (correct)
- No raw SQL in repositories — all via Supabase client

**Issues:**
1. **`care_repository.dart` is a stub** — it only re-exports `pet_care_repository.dart`. Dead indirection that confuses the import graph.
2. **`product_repository.dart` uses offset pagination** — documented risk of gaps/duplicates (see comment in file). Should switch to cursor pagination.
3. **`matching_repository.dart`** wraps `matching_supabase_data_source.dart` — an extra indirection layer that adds no value; these could be merged.
4. **No repository interfaces** — all repositories are concrete classes, making unit testing without real Supabase impossible. No `mocktail` usage.
5. **`vendor_product_repository.dart` and `product_repository.dart`** overlap in responsibility — both fetch products, just with different filters.

### 4.3 Navigation Architecture

**Strengths:**
- GoRouter with `StatefulShellRoute` — maintains tab state correctly
- Proper use of `parentNavigatorKey: _rootNavigatorKey` for full-screen routes (no bottom nav)
- Auth redirect centralized in `_RouterNotifier`

**Issues:**
1. **`_tabColors` and `_destinations` are positionally coupled** — a tab reorder silently breaks color assignments. Use a `Map<String, Color>` or a data class with a `color` field.
2. **`/pet/:petId/edit` route** reads from `ref.read(petListProvider)` directly in the route builder — this is synchronous and will return an empty list if the provider hasn't loaded. The `_PetEditMissingScreen` fallback fires incorrectly on cold start.
3. **No deep link configuration** in `AndroidManifest.xml`/`Info.plist` — GoRouter routes won't resolve from external URIs.
4. **Two similar routes**: `/marketplace/orders/:id` and `/profile/orders/:id` both map to `BuyerOrderDetailScreen` — consolidate to one canonical path.

### 4.4 Data Models

**Strengths:**
- Freezed + JsonSerializable for all models — correct immutability pattern
- Models named consistently (`FeedPost`, `DiscoveryCandidate`, `MarketplaceOrder`)

**Issues:**
1. **`lib/core/models/pet.dart`** duplicates `lib/features/pet_profile/data/models/pet.dart` — two `Pet` models. `care_screen.dart` imports from `core/models/pet.dart` while most other files use `features/pet_profile/data/models/pet.dart`. This will cause type mismatch errors.
2. **`CareTaskLog` model** is imported in `care_screen.dart` but `care_task_log.dart` doesn't appear in the feature inventory — may be a generated file or a missing file.
3. **`VendorLedger` model exists** but the table is always empty — dead code until the backend bug is fixed.

### 4.5 Code Quality

| File | Lines | Issue |
|------|-------|-------|
| `care_screen.dart` | 1923 | God widget — split immediately |
| `seller_dashboard_screen.dart` | 1217 | Tab content inline — extract tab widgets |
| `matching_screen.dart` | 1127 | Discovery view, preference sheet, overlay all inline |
| `social_screen.dart` | 966 | Story rail, feed list, post card all inline |
| `onboarding_screen.dart` | 842 | 5 steps inline — extract step widgets |
| `manage_pets_screen.dart` | 781 | List + reorder + archive logic inline |

---

## 5. Security & Auth Review

### 5.1 Critical Security Issues

| Severity | Issue | Location | Fix |
|----------|-------|----------|-----|
| 🔴 P0 | **`bank_account_details` stored as plain JSONB** | `shops` table | Replace with Stripe bank account tokens; never store raw account details |
| 🔴 P0 | **No Stripe webhook** — payment confirmation is client-side only | `CheckoutController` | Implement Supabase Edge Function for `payment_intent.succeeded` |
| 🔴 P0 | **Leaked password protection disabled** | Supabase Auth settings | Enable HaveIBeenPwned check in Supabase dashboard |
| 🟠 P1 | **`vendor_ledgers` never populated** | `process_checkout` RPC | Add ledger INSERT to RPC; vendor earnings untracked |
| 🟠 P1 | **Stories never expire** | `cleanup_expired_stories` RPC | Create Supabase Edge Function on hourly cron |

### 5.2 Auth Architecture

**Strengths:**
- Supabase Auth with JWT — stateless, secure
- RLS enabled on all 31 tables — verified via MCP
- `is_admin()` DB function for admin role check — not a JWT claim, prevents escalation via token manipulation
- Token refresh does NOT re-trigger navigation (intentional, prevents spinner on 55-min rotation)

**Issues:**
1. **`isAdminProvider` reads from `appMetadata`** — app metadata is only set server-side but if the check is only client-side, a compromised JWT could pass. Verify `is_admin()` is also called server-side in RLS for admin tables.
2. **Session persistence**: Supabase's `SharedPreferences`-based session storage is cleared on app uninstall. Consider keychain/keystore for production.
3. **No email verification gate** — users can sign up and immediately access all features without verifying their email.

### 5.3 Data Access Control

**Strengths:**
- All queries run as authenticated user (RLS enforced at DB level)
- Vendor KYC status checked before allowing product listing

**Issues:**
1. **`follows` table uses `auth.users` FK** directly (not `public.users`) — inconsistent with every other table, and means `follows` rows are not joined to public user profiles automatically.
2. **`reported_posts.reporter_id`** uses `auth.users` FK — same inconsistency.
3. **`chat_messages.is_read`** has no RLS check for the reader — any participant could mark another's messages as read.

---

## 6. Data Consistency & Business Logic

### 6.1 Schema Bugs

| Issue | Table | Column | Impact |
|-------|-------|--------|--------|
| **Nullable FK on follows** | `pet_follows` | `follower_pet_id`, `following_pet_id` | A follow record can exist with no follower — orphan rows possible |
| **Nullable FK on follows** | `follows` | `follower_id`, `following_id` | Same issue for user-follows |
| **inventory_count defaults to 0** | `products` | `inventory_count` | Products can be created with zero inventory without a UI warning |
| **`vendor_ledgers` never populated** | `vendor_ledgers` | — | 11 orders, 0 ledger entries — vendor earnings untracked |
| **`users.public_key`** | `users` | `public_key` | Column exists (nullable), not used anywhere in app code |

### 6.2 Two Matching Systems

The app has two overlapping match flows that share `chat_threads`:

```
Flow A: swipes → matches (mutual LIKE) → chat_threads.mutual_match_id
Flow B: match_requests (playdate/breeding/adoption) → chat_threads.match_request_id
```

Both flows create chat threads, but only Flow A is surfaced in the discovery UI. Flow B (16 rows in DB) has no clear entry point in the current UI beyond what's visible in `match_requests`. This creates dead data and confusion when a thread has `match_request_id` but no `mutual_match_id`.

### 6.3 Business Logic Gaps

1. **Checkout race condition**: `process_checkout` RPC atomically reserves inventory, but if the Stripe payment fails after reservation, `release_order_inventory` must be called client-side. If the app crashes post-reservation but pre-release, inventory is stuck reserved for 15 minutes — acceptable but should be documented.

2. **Cart dangling references**: Cart is persisted to `SharedPreferences` as product IDs. If a product is deactivated (`active = false`) or deleted between sessions, the cart silently holds a stale item. No validation on cart load.

3. **Story viewed tracking**: `stories.viewed_by_users` is a UUID array. On high-traffic accounts this array grows unbounded — no cap or archival strategy.

4. **Notification types mismatch**: `notifications.type` check constraint includes `kyc_approved`, `kyc_rejected`, `shop_deletion_approved`, `shop_deletion_rejected` — but the `notifications` table uses `recipient_user_id` for these (not `recipient_pet_id`). The bell UI (when wired) must handle both recipient ID types.

5. **`products.inventory_count` check**: `inventory_count >= 0` allows listing products with zero stock. The `fetchProducts` query filters `active = true` but not `inventory_count > 0` — buyers see and can attempt to purchase OOS items.

---

## 7. Duplicate / Deprecated Code

### 7.1 Duplicate Files/Models

| Issue | Files | Action |
|-------|-------|--------|
| **Duplicate Pet model** | `lib/core/models/pet.dart` + `lib/features/pet_profile/data/models/pet.dart` | Delete `core/models/pet.dart`, fix all 2 imports in `care_screen.dart` |
| **`care_repository.dart` stub** | `lib/features/care/data/repositories/care_repository.dart` | File only re-exports `pet_care_repository.dart` — delete stub, update all imports |
| **Duplicate order routes** | `/marketplace/orders/:id` + `/profile/orders/:id` | Both map to `BuyerOrderDetailScreen` — remove duplicate, pick one canonical path |
| **`matching_repository.dart` over `matching_supabase_data_source.dart`** | Both in matching/data | The data source is essentially the repository — merge into one layer |

### 7.2 Deprecated Patterns

| Issue | Location | Action |
|-------|----------|--------|
| **`StateNotifier` (Riverpod deprecated)** | auth, social, marketplace, pet_profile, matching controllers | Migrate to `@riverpod` + `Notifier`/`AsyncNotifier` |
| **20+ `AppColors.blue*` aliases** | `lib/core/theme/app_colors.dart:115-148` | Remove after confirming no remaining callers |
| **`cupertino_icons` package** | `pubspec.yaml:34` | Verify no `CupertinoIcons.*` usage; remove if unused |
| **`// ignore: unused_local_variable` on `pc`** | Multiple screen files | Delete the unused `pc = Theme.of(context).extension...` extractions |
| **`sunset500`, `coral500`, `meadow500`, etc.** | `app_colors.dart:133-147` | Semantic alias tier also stale — remove after migration |

### 7.3 Orphaned Code

| Item | Status |
|------|--------|
| `VendorLedger` model | Dead — table has 0 rows |
| `NutritionScreen` | No backing DB table — may be placeholder |
| `health_vitals` table (5 rows) | No repository, no UI |
| `users.public_key` column | Unused in entire codebase |
| `cleanup_expired_stories` RPC | No caller — needs Edge Function cron |
| `marionette_flutter` dependency | Debug-gate pattern present — confirm it's excluded from release builds |

---

## 8. Prioritised Fix List

### P0 — Production Blockers

| # | Issue | File/Location | Effort |
|---|-------|---------------|--------|
| 1 | Add Stripe webhook Edge Function for `payment_intent.succeeded` | New `supabase/functions/stripe-webhook/` | L |
| 2 | Fix `process_checkout` RPC to INSERT into `vendor_ledgers` | `supabase/migrations/` | S |
| 3 | Move `bank_account_details` to Stripe bank account tokens | `shops` table + `kyc_repository.dart` | L |
| 4 | Enable HaveIBeenPwned in Supabase Auth settings | Supabase dashboard | XS |
| 5 | Create Edge Function cron for `cleanup_expired_stories` | New `supabase/functions/cleanup-stories/` | S |

### P1 — Feature & UX Gaps

| # | Issue | File/Location | Effort |
|---|-------|---------------|--------|
| 6 | Wire notifications bell count to live `notifications` table | `social_screen.dart` + `notification_controller.dart` | S |
| 7 | Add bottom padding to all `CustomScrollView`/`ListView` screens to clear floating nav | All tab screens | M |
| 8 | Show `shops.rejection_reason` in seller dashboard when `kyc_status = 'rejected'` | `seller_dashboard_screen.dart` | S |
| 9 | Add `inventory_count > 0` filter to `fetchProducts` query | `product_repository.dart:39` | XS |
| 10 | Warn vendor when `inventory_count = 0` in add-product form | `add_edit_product_screen.dart` | XS |
| 11 | Fix `pet_follows.follower_pet_id` + `following_pet_id` NOT NULL constraint | New migration | XS |
| 12 | Build `health_vitals` repository + UI widget (or drop the table) | New files | M |
| 13 | Add unread match count badge to Match tab icon | `router.dart` `_NavTab` | S |

### P2 — Code Quality & Tech Debt

| # | Issue | File/Location | Effort |
|---|-------|---------------|--------|
| 14 | Delete `lib/core/models/pet.dart` duplicate | `core/models/pet.dart` | XS |
| 15 | Delete `care_repository.dart` stub | `care/data/repositories/care_repository.dart` | XS |
| 16 | Convert `_tabColors`/`_destinations` coupling to map | `router.dart:401-511` | S |
| 17 | Fix `NavigationRail` indicator color: remove `Colors.transparent` override in `_WideNavRail` | `router.dart:634` | XS |
| 18 | Split `care_screen.dart` (1923 lines) into sub-widgets | `care/presentation/screens/` | L |
| 19 | Split `seller_dashboard_screen.dart` (1217 lines) into tab widgets | `marketplace/presentation/screens/vendor/` | L |
| 20 | Remove `AppColors.blue*` backward-compat aliases after migration | `app_colors.dart:114-148` | M |
| 21 | Migrate `StateNotifier` controllers to `@riverpod` `Notifier`/`AsyncNotifier` | All legacy controllers | L |
| 22 | Fix `_PetEditMissingScreen` to offer navigation to pet list | `router.dart:464-488` | XS |
| 23 | Add `Semantics` to nav tabs for accessibility | `router.dart:_NavTab` | S |
| 24 | Fix `ink500` contrast ratio (~2.8:1) — use `ink700` for body text minimum | Theme-wide | M |
| 25 | Add cursor-based pagination to `fetchProducts` | `product_repository.dart:29` | S |
| 26 | Validate cart items on load (check `active` + `inventory_count`) | `cart_controller.dart` | S |
| 27 | Add email verification gate after registration | `auth_controller.dart` + GoRouter redirect | M |
| 28 | Remove `cupertino_icons` from `pubspec.yaml` if unused | `pubspec.yaml:34` | XS |
| 29 | Consolidate duplicate `/marketplace/orders/:id` + `/profile/orders/:id` routes | `router.dart` | XS |
| 30 | Add `GestureDetector` → `InkWell` on nav tabs for ripple feedback | `router.dart:_NavTab` | XS |

---

*Effort scale: XS < 1h | S = 1-4h | M = 4-8h | L = 1-3d*
