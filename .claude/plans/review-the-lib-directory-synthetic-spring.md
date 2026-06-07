# Petfolio – Full `lib/` Review, Module Inventory & Improvement Plan

## Context

The user requested a full review of the `lib/` directory to (1) catalogue every module and its functionality, (2) surface improvement opportunities identified via online research, and (3) produce a concrete implementation plan covering architecture, UI/UX, performance, security, and feature additions. This is a comprehensive technical-audit and enhancement exercise — nothing is broken; the goal is to raise code quality and product value across the board.

---

## Current Project Overview

**Stack:** Flutter (cross-platform: iOS, Android, Web) · Riverpod 3 (codegen) · Supabase v2 · Go Router v17 · Stripe · Firebase FCM · Material 3

**Architecture pattern:** Clean, feature-first
```
lib/
├── main.dart                  # Bootstrap: Supabase, Stripe, Firebase, Notifications
├── firebase_options.dart
├── core/                      # Shared infra
│   ├── errors/                # AppException
│   ├── firebase/              # FCM (8 files, full lifecycle)
│   ├── models/                # Core Pet model
│   ├── navigation/            # Route overlay helpers
│   ├── platform/              # Platform abstractions (16 files: IO/Web stubs)
│   ├── router.dart            # GoRouter, 491 lines, auth/onboarding/admin redirects
│   ├── services/              # Location, Notifications, Stripe init
│   ├── theme/                 # AppColors, AppTheme, dark/light toggle
│   ├── utils/                 # time_ago
│   └── widgets/               # 20+ shared components (AppShell, PetAvatar, GlassCard…)
└── features/
    ├── admin/     (20 files)
    ├── auth/       (5 files)
    ├── care/      (27 files)
    ├── marketplace/(44 files)
    ├── matching/  (23 files)
    ├── pet_profile/(15 files)
    └── social/    (22 files)
```

---

## Module & Feature Inventory

### 1. Auth (`features/auth/`)
- Supabase email/password login & registration
- `AuthController` (Riverpod) — auth state machine
- Screens: `LoginScreen`, `RegistrationScreen`
- `AuthWidgets` — shared form components

### 2. Pet Profile (`features/pet_profile/`)
- CRUD for multiple pets per user (species, gender, activity level)
- Active-pet switcher
- Onboarding flow (first pet creation)
- Discovery visibility toggle (opt-in to matching)
- Screens: Profile, Onboarding, ManagePets, EditProfile

### 3. Care (`features/care/`)
- Daily care tasks with scheduling & reminders (FCM)
- Completion logs, streaks, pet XP/level gamification
- Health vault — medical records & documents
- Nutrition tracking
- AI-powered care recommendations (NVIDIA API)
- Screens: CareDashboard, MedicalVault, Nutrition

### 4. Social (`features/social/`)
- Chronological feed (posts with images)
- Ephemeral stories (24 h)
- Likes, reactions, comments with `reaction_burst` animation
- Follow/unfollow pets
- Push notifications for interactions
- Pet social profile with stats
- Screens: Feed, CreatePost, CreateStory, PostDetail, StoryViewer, Notifications, SocialProfile

### 5. Matching (`features/matching/`)
- Tinder-style swipe card discovery
- Geo-filtered candidates
- Mutual match detection (real-time via Supabase)
- Match celebration overlay
- Preference filters (species, distance, age)
- Direct messaging after match
- Screens: Discovery, MatchesInbox, Chat

### 6. Marketplace (`features/marketplace/`)
- Dual-role: buyer browsing + vendor management
- KYC verification workflow for vendors
- Stripe-powered checkout (mobile & web redirect)
- Product CRUD, shop storefront
- Order lifecycle (placed → fulfilled → tracking)
- Subscription toggle on products
- Vendor ledger/financials
- Screens (16): Marketplace, ProductDetail, ShopStorefront, Cart, OrderConfirmation, BuyerOrderList/Detail, SellerDashboard, ShopSetup, EditShop, ManualKYC, VendorProductList, AddEditProduct, VendorOrderQueue/Detail, StripeOnboarding

### 7. Admin (`features/admin/`)
- Separate secured admin portal
- Content moderation (post reports)
- KYC approvals
- Financial ledger
- COD order management
- Shop deletion requests
- Screens: AdminScreen, AdminLayout (with 6 tabs)

### Core Infrastructure
- **AppShell**: 5-tab bottom nav (Pets · Care · Social · Match · Market) with NavRail at ≥600 px
- **Theme**: `AppColors` (tangerine, sunny, poppy, lilac, mint), Material 3, dark/light
- **Platform layer**: 16 files for IO/Web/Stub patterns (media picker, push, checkout redirect)
- **Router**: GoRouter with auth-guard redirects, onboarding gates, admin gate
- **Firebase FCM**: full lifecycle (token sync, background handler, message router)

---

## Identified Improvements (from online research)

### A. Architecture / Code Quality

| # | Issue / Opportunity | Action |
|---|---|---|
| A1 | `core/router.dart` is 491 lines — hard to maintain | Split into per-feature route definitions; barrel-import into main router |
| A2 | Some controllers still use `StateNotifier` pattern | Migrate to `@riverpod` `AsyncNotifier` / `Notifier` code-gen everywhere |
| A3 | `ref.read()` may appear inside `build()` in older widgets | Audit and replace with `ref.watch()` or `ref.listen()` |
| A4 | No domain Use-Case layer in some features | Add lightweight use-case classes for complex business logic (e.g., checkout, match scoring) |
| A5 | Barrel exports inconsistent across features | Add per-feature `index.dart` barrel files |
| A6 | Missing DCM (Dart Code Metrics) linting | Add `dart_code_metrics` to `dev_dependencies`; enforce Riverpod-specific rules |

### B. UI / UX

| # | Improvement | Detail |
|---|---|---|
| B1 | Material 3 Expressive (May 2025) | Adopt new M3 component variants: `CardVariant`, `SegmentedButton`, `SearchBar`, updated `NavigationBar` |
| B2 | Skeleton loaders are present but inconsistent | Standardise shimmer loading across all async lists (feed, marketplace, care dashboard) |
| B3 | Social feed lacks video support | Add `video_player` package; auto-play muted in feed |
| B4 | No hashtag / mention support in posts | Add `flutter_hashtag_text` or `flutter_linkify` for rich post text |
| B5 | Stories bar feels static | Add animated ring indicator for unseen stories (like Instagram) |
| B6 | Matching cards need haptic feedback | `HapticFeedback.lightImpact()` on swipe; spring physics on card throw |
| B7 | Chat screen missing read receipts & typing indicator | Add Supabase realtime `presence` for typing; read-at timestamp |
| B8 | Marketplace product cards lack price badges & ratings | Add star rating widget, discount badges, "sold X" counter |
| B9 | Care gamification UI (`gamified_care_ui.dart`) can be enriched | Add level-up confetti (`confetti` package), animated XP bar |
| B10 | No onboarding tutorial / empty-state guidance | Add `intro_screen` onboarding for first-time users; improve empty states |
| B11 | Accessibility gaps | Add `Semantics` labels to custom widgets (PawToggle, BoneSlider, PetAvatar) |
| B12 | No skeleton on pet profile header | Add shimmer while pet image loads |

### C. Performance

| # | Improvement | Detail |
|---|---|---|
| C1 | Feed images not compressed before upload | Use `flutter_image_compress` before upload to Supabase Storage |
| C2 | `const` constructors missing on stateless widgets | Audit all `StatelessWidget` subclasses and add `const` |
| C3 | Social feed may rebuild entire list on new post | Use `ListView.builder` with `itemCount` delta; Riverpod `select` to watch only list length |
| C4 | No pagination cursor for marketplace listing | Add keyset pagination (cursor-based) instead of offset |
| C5 | Heavy screens (marketplace, social) missing `RepaintBoundary` | Wrap independent subtrees to isolate repaints |
| C6 | Web image cache (`web_image_cache.dart`) needs LRU cap | Set explicit max-size to prevent memory bloat on web |

### D. Security

| # | Improvement | Detail |
|---|---|---|
| D1 | Sensitive local data (tokens) in `shared_preferences` | Migrate to `flutter_secure_storage` for auth tokens & Stripe keys |
| D2 | Supabase RLS policies not validated in code | Add integration tests that assert RLS blocks cross-user reads |
| D3 | Stripe secret key must stay server-side | Audit that only publishable key is in client; all Payment Intents created via Supabase Edge Function |
| D4 | No certificate pinning | Add `http_certificate_pinning` for production API calls |
| D5 | Input validation missing on post/comment creation | Sanitise text, enforce max-length, strip dangerous characters on client + Supabase function |

### E. Feature Additions (high-value, researchable)

| # | Feature | Rationale |
|---|---|---|
| E1 | **Vet appointment booking** | Most-requested pet app feature; add `features/appointments/` with calendar UI (`table_calendar`) |
| E2 | **Pet weight & vitals chart** | Extend health vault with time-series charts (`fl_chart` already present) |
| E3 | **Group chat / pet communities** | High engagement driver; Supabase realtime channels already capable |
| E4 | **Product reviews & ratings** | Marketplace trust signal; add `reviews` table + star rating widget |
| E5 | **Apple Pay / Google Pay** | Stripe already supports; enable `flutter_stripe` `PaymentSheetGooglePay` |
| E6 | **AI breed identification** | Camera → NVIDIA API endpoint; integrate into onboarding |
| E7 | **Walk tracking with map** | Use `geolocator` (already present) + `flutter_map` for live walk route |
| E8 | **Dark mode pet profile covers** | Theme-adaptive banner images |
| E9 | **In-app feedback / rating prompt** | Trigger after 3rd care check-in; use `in_app_review` package |
| E10 | **Story reactions** | Emoji reactions on stories (heart, paw, laugh) |

### F. Testing

| # | Improvement |
|---|---|
| F1 | Zero test files currently visible — add unit tests for all repositories |
| F2 | Widget tests for core shared widgets (PetAvatar, GlassCard, AppShell) |
| F3 | Integration test for auth → onboarding → care flow |
| F4 | Golden tests for AppTheme light/dark variants |
| F5 | Stripe test-mode integration test for checkout |

---

## Implementation Plan (Phased)

### Phase 1 — Architecture Cleanup (foundation)
1. Split `core/router.dart` into `features/<name>/<name>_routes.dart` files; compose in `core/router.dart`
2. Migrate any remaining `StateNotifier` to `@riverpod AsyncNotifier`
3. Add DCM to `pubspec.yaml` `dev_dependencies`; run audit; fix critical violations
4. Add `flutter_secure_storage`; replace `shared_preferences` for tokens/keys
5. Add per-feature `index.dart` barrel exports

**Verify:** `dart analyze` clean; `flutter test` passes; no `ref.read()` in `build()`

### Phase 2 — UI / UX Polish
1. Update `AppTheme` to use Material 3 Expressive component tokens (NavigationBar, SearchBar, CardVariant)
2. Standardise `SkeletonLoader` usage across all async lists
3. Add `Semantics` labels to all custom widgets in `core/widgets/`
4. Add animated story-ring indicator in social feed
5. Add `HapticFeedback` + spring physics to matching swipe cards (`matching_screen.dart`)
6. Enrich `gamified_care_ui.dart` with confetti and animated XP bar

**Verify:** Visual regression check; `flutter analyze` clean

### Phase 3 — Performance
1. Add `flutter_image_compress` to `media_picker.dart` pipeline before Supabase Storage upload
2. Audit and add `const` constructors (automated via DCM rule)
3. Wrap heavy subtrees in `RepaintBoundary` in `social_screen.dart` and `marketplace_screen.dart`
4. Implement cursor-based pagination in `product_list_controller.dart`

**Verify:** Profile with Flutter DevTools; 60 fps on mid-range device

### Phase 4 — Feature Additions (prioritised)
1. **Pet vitals chart** — extend `health_vault_controller.dart` + new `VitalsChartWidget` using `fl_chart`
2. **Product ratings** — new `reviews` table + star widget in `product_detail_screen.dart`
3. **Apple Pay / Google Pay** — enable in `checkout_controller.dart` via `flutter_stripe` PaymentSheet options
4. **Vet appointment booking** — new `features/appointments/` module (table_calendar + Supabase `appointments` table)
5. **Walk tracking** — extend `care/` with `WalkTrackingScreen` using `geolocator` + `flutter_map`

### Phase 5 — Security & Testing
1. Audit Stripe flow: confirm Payment Intent is created server-side (Supabase Edge Function)
2. Add RLS integration tests
3. Write unit tests for all repositories (auth, care, social, marketplace, matching)
4. Add widget golden tests for shared widgets

---

## Critical Files to Modify

| File | Change |
|---|---|
| `lib/core/router.dart` | Decompose into per-feature route files |
| `lib/core/theme/app_theme.dart` | Add M3 Expressive tokens |
| `lib/core/widgets/skeleton_loader.dart` | Standardise API; add named constructors for feed/list/card |
| `lib/core/platform/media_picker.dart` | Add compression step |
| `lib/features/care/presentation/widgets/gamified_care_ui.dart` | Add confetti + XP bar animation |
| `lib/features/matching/presentation/screens/matching_screen.dart` | Add haptic + spring physics |
| `lib/features/social/presentation/screens/social_screen.dart` | Add RepaintBoundary, story ring indicator |
| `lib/features/marketplace/presentation/controllers/product_list_controller.dart` | Cursor pagination |
| `lib/features/marketplace/presentation/screens/product_detail_screen.dart` | Add ratings widget |
| `pubspec.yaml` | Add: `flutter_secure_storage`, `flutter_image_compress`, `dart_code_metrics`, `confetti`, `in_app_review`, `table_calendar`, `flutter_map` |

## Existing Utilities to Reuse

- `lib/core/widgets/skeleton_loader.dart` — extend, don't replace
- `lib/core/widgets/glass_card.dart` — use for new vitals and ratings cards
- `lib/core/widgets/pf_stat_tile.dart` — reuse in vitals chart header
- `lib/core/services/location_service.dart` — reuse in walk tracking
- `fl_chart` (already in pubspec) — use for vitals time-series chart

---

## Verification Steps

```bash
# After each phase:
flutter analyze          # zero errors/warnings
flutter test             # all tests green
flutter build apk --debug  # successful build
# DevTools profiling on matching swipe & social feed scroll
```
