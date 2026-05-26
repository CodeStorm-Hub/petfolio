# Petfolio Flutter + Supabase Review

Review date: 2026-05-13  
Scope: `lib/`, Supabase project `jqyjvhwlcqcsuwcqgcwf`, Android emulator QA via `emulator-5554`

## Executive Summary

Petfolio is a feature-first Flutter/Riverpod app with Supabase Auth, Postgres, Storage, Realtime intent, and Stripe checkout. The working database-backed areas are Auth, pet list/onboarding, care task persistence, product catalog, order creation, and payment-intent plumbing. The biggest gaps are Social and Matching: both present polished UI but primarily use mock data, and Matching writes to tables/columns that do not exist in the active database.

Static verification:

- `flutter analyze`: 8 info-level issues, no compile errors.
- `flutter test`: fails. `test/widget_test.dart` is still Flutter's counter template and pumps `PetfolioApp` without `ProviderScope`.
- `flutter build apk --debug`: passes.
- Android install/launch: passes.
- Android login with supplied credentials: blocked on emulator DNS. Host machine Supabase REST auth succeeds with test account; emulator app shows `SocketException: Failed host lookup: 'jqyjvhwlcqcsuwcqgcwf.supabase.co'`.

## Screens And Features

| Screen | Route | Features | Data Source |
|---|---:|---|---|
| Login | `/login` | Email/password sign-in, validation, password visibility, error banner | Supabase Auth |
| Registration | `/register` | Email/password sign-up, confirm password, validation | Supabase Auth, public `users` trigger |
| Onboarding | `/onboarding` | Multi-step first-pet creation, species/breed/photo flow | `pets`, Storage bucket `pets` for avatar upload |
| Pet Profile/Home | `/home` | Active pet header, switcher, health streak, reminders, feed preview | Pet header from `pets`; summary/reminders/feed preview are static |
| Care | `/care` | Daily feed/walk/med checklist, local week history, streak visualization | `SharedPreferences` plus `care_logs` |
| Social | `/social` | Feed cards, stories, likes, memorial candles | Feed is mock; like/candle writes target `post_likes` and `post_candles` |
| Matching | `/matching` | Swipe deck, action dock, matches/chat preview intent | Deck is mock; writes target nonexistent `swipes`/`matches`; chat model mismatches `chat_threads` |
| Marketplace | `/marketplace` | Product catalog, filters, promo/subscription sections, cart badge | `products`; fallback demo catalog |
| Product Detail | `/marketplace/product/:id` | Product details, quantity, subscription toggle, add to cart | Product route extra or `products`; cart is in-memory |
| Cart | `/marketplace/cart` | Cart line items, quantity changes, checkout | In-memory cart, `marketplace_orders`, Edge Function |
| Order Confirmation | `/marketplace/order/:id` | Confirmation and order summary | `marketplace_orders` |

Shell navigation is adaptive: `NavigationBar` under 600 dp and `NavigationRail` at 600 dp or wider in `lib/core/router.dart`.

## Supabase Mapping

Current public tables from MCP: `users`, `pets`, `care_logs`, `health_vitals`, `posts`, `post_likes`, `post_candles`, `match_requests`, `chat_threads`, `chat_messages`, `products`, `marketplace_orders`. All have RLS enabled.

| Feature | Flutter Entry Points | Expected DB Objects | Status |
|---|---|---|---|
| Auth | `auth_repository.dart`, auth screens | Supabase Auth, `public.users` trigger | Connected |
| Pet profiles | `pet_repository.dart`, onboarding, switcher, home | `pets`, Storage bucket `pets` | Connected, but storage bucket/policies must remain verified |
| Active pet | `active_pet_controller.dart` | `SharedPreferences`, `pets` | Connected locally and to pet list |
| Care checklist | `care_repository.dart` | `care_logs.logged_date`, unique `(pet_id, care_type, logged_date)` | Connected; app relies on DB migration beyond base schema |
| Product catalog | `product_repository.dart` | `products` | Connected with silent demo fallback |
| Checkout | `order_repository.dart`, `checkout_controller.dart` | `marketplace_orders`, `create-payment-intent` | Connected, but confirm/cancel are client-side status updates |
| Social feed | `social_controller.dart`, `social_repository.dart` | `posts`, `post_likes`, `post_candles` | Feed disconnected; reactions partially connected and will fail for mock post IDs unless matching rows exist |
| Matching discovery | `discovery_controller.dart`, `matching_repository.dart` | Code expects `swipes`, `matches`, pet-based `chat_threads` | Disconnected and schema-incompatible |
| Chat threads | `chat_threads_controller.dart`, `chat_thread.dart` | DB has user participant columns, code expects `pet_id_1`, `pet_id_2`, `match_id`, `last_message` | Broken mapping |
| Health vitals | DB table exists | No UI/repository use found | Not implemented |

Supabase advisors:

- Security: leaked password protection is disabled.
- Performance: missing FK indexes on `match_requests.requester_pet_id`, `match_requests.target_pet_id`, `post_likes.pet_id`, `post_likes.user_id`, `post_candles.pet_id`, `post_candles.user_id`.
- Several unused-index warnings appear, likely because the project has very little production query history. Do not drop those before real workload review.

## Mock Or Disconnected Screens

| Screen | Evidence | Impact |
|---|---|---|
| Social | `socialControllerProvider.build()` returns `_demoPosts()` | Feed never reads `posts`; like/candle can only write reactions against mock UUIDs, so UX can silently roll back |
| Matching | `DiscoveryNotifier.build()` returns `_sampleDeck()` | Discovery is entirely mock; demo IDs are intentionally skipped by repository |
| Matching chat | Code filters `chat_threads.pet_id_1/pet_id_2`; DB has `participant_1_id/participant_2_id` | Chat stream cannot map real rows |
| Home | Reminder cards, health streak, feed preview hardcoded | Main dashboard looks live but is not backed by `care_logs`, `health_vitals`, or `posts` |
| Marketplace | `ProductListNotifier` falls back to `_demoCatalog` on any fetch error | Users may see stale/demo products without knowing Supabase failed |

## Non-Functional UI Components

| Screen | Non-functional or placeholder UI |
|---|---|
| Home | Outdoor-mode chip has no state/action; notification bell has no destination; reminder card buttons are static containers; feed preview is static |
| Pet Switcher | `Manage` row has `onTap: () {}` |
| Care | One header/action tap is empty; care labels contain fixed schedule/quantity text rather than user-configured data |
| Social | Create/add button has empty `onPressed`; story tap is empty; feed cards are mock |
| Matching | Header/action button has empty `onPressed`; Boost is disabled placeholder; deck is mock; chat preview is not connected |
| Marketplace | Search field is visual only; filter/tune icon is visual only; promo `Manage` is visual copy |
| Product Detail | Product recommendations/spec sections are mostly static; checkout path depends on Stripe setup |
| Order Confirmation | Shows a completed UX but fetch/error handling is thin |

## UI/UX Review

Strengths:

- Consistent branded theme with light/dark support and shared `AppTheme`.
- Main shell has a proper compact/expanded navigation switch at 600 dp.
- Most full screens use `SafeArea` and scrollable bodies.
- Core buttons and avatars include some semantics support.
- Loading and empty states exist for pet/profile and product flows.

Issues:

- Many screens rely on hardcoded `TextStyle`, `Colors.*`, and pixel dimensions instead of theme tokens, making long-term consistency and contrast auditing harder.
- Several actionable-looking controls are no-ops, which is worse than hiding or disabling them.
- Accessibility labels are incomplete in auth fields and icon-only controls; uiautomator marks password visibility controls as NAF.
- Large screens only switch shell navigation; individual screens remain phone-width compositions stretched inside the available area.
- Text scaling and very small screens need focused testing; large custom cards, gradients, and stacked layouts risk clipping.
- Header/footer consistency is mixed: the shell footer/nav is consistent, but each top header is custom and lacks a common app-bar/header contract.
- Product/search UI implies functionality that is not implemented.

## Code Review Findings

High priority:

- `lib/features/matching/data/repositories/matching_repository.dart` writes to `swipes`, `matches`, `chat_threads.match_id`, `pet_id_1`, and `pet_id_2`, none of which match the current DB schema.
- `lib/features/matching/data/models/chat_thread.dart` and `chat_threads_controller.dart` assume pet-based chat columns, but Supabase stores user participants and `match_request_id`.
- `lib/features/social/presentation/controllers/social_controller.dart` does not fetch `posts`, so Social is not a real feed.
- `lib/main.dart` has default Supabase URL/anon key and Stripe publishable key in source. The anon and publishable keys are not secret, but environment-specific config should not be hardcoded as defaults in production builds.
- `test/widget_test.dart` is invalid for the app and fails immediately.

Medium priority:

- `ProductListNotifier` swallows catalog fetch failures and displays demo products, hiding backend outages.
- `CareRepository.refreshFromRemote` catches and only `debugPrint`s errors, so UI cannot show remote sync failure.
- Checkout status updates are client-side. Confirming orders should be backed by Stripe webhook verification, not just client success.
- Error handling often displays raw exception strings, including long network exceptions.
- Auth registration does not pass username/display metadata, relying on DB trigger email split.

Low priority:

- Analyzer info issues: unnecessary underscores, unnecessary import, non-final private field, deprecated `Matrix4.translate`, null-aware collection suggestion.
- Some comments are more verbose than the code needs.

## Android QA Results

Commands run:

- `adb devices`: `emulator-5554 device`
- `flutter build apk --debug`: passed
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`: passed
- `adb shell am start -n com.example.petfolio/.MainActivity`: passed
- Login UI was driven with test credentials.

Observed:

- Login screen renders.
- Credential entry works after using escaped `@`.
- Host machine Supabase REST auth succeeds for the supplied credentials.
- Emulator app login fails with failed DNS lookup for `jqyjvhwlcqcsuwcqgcwf.supabase.co`, so authenticated screen traversal could not be completed in this emulator session.
- Accessibility tree exposed unlabeled icon buttons for password visibility.

## Implementation Plan

### Phase 1: Stabilize And Verify The Foundation

1. Fix `test/widget_test.dart` by wrapping `PetfolioApp` in `ProviderScope`, mocking Supabase/Router dependencies, or replacing it with focused widget tests for Login/Navigation.
2. Resolve all analyzer issues and add stricter analyzer settings over time.
3. Remove hardcoded production defaults from `main.dart`; require `--dart-define` or generated flavor config for Supabase and Stripe.
4. Add user-friendly network error mapping and retry actions for auth, pet list, products, care sync, and checkout.
5. Fix emulator DNS/networking, then rerun full Android QA.

### Phase 2: Align Supabase Schema With Feature-First Architecture

Recommended approach: keep feature-first folders, but add `domain`, `data`, and `presentation` boundaries per feature:

- `features/<feature>/domain/entities`
- `features/<feature>/domain/repositories`
- `features/<feature>/data/models`
- `features/<feature>/data/repositories`
- `features/<feature>/presentation/controllers`
- `features/<feature>/presentation/screens/widgets`

For Supabase:

1. Add migrations for missing feature tables or refactor Flutter to use existing tables. Prefer refactoring Matching to current DB objects: `match_requests`, `chat_threads`, `chat_messages`.
2. Implement repository interfaces so widgets/controllers do not depend directly on concrete Supabase clients.
3. Add missing FK indexes reported by advisors.
4. Enable leaked password protection in Supabase Auth.
5. Add Storage policies for the `pets` bucket if not already present in dashboard-only config.
6. Move payment confirmation to a Stripe webhook-backed order status transition.

### Phase 3: Connect Real Features

1. Social:
   - Fetch `posts` joined to `users`, `pets`, and aggregate reaction state.
   - Add create-post flow and media upload.
   - Replace mock `FeedPost` construction with DTO mapping.
   - Add comments or remove comment affordance until implemented.
2. Matching:
   - Build discovery query from public pets excluding owner pets and already requested/swiped candidates.
   - Use `match_requests` for greet/playdate requests.
   - Let accepted requests create `chat_threads` via the existing trigger.
   - Map chat by user participants, not pet IDs, or change DB intentionally with a migration.
3. Home:
   - Compute health streak from `care_logs`.
   - Source reminders from a real reminders table or care schedule model.
   - Replace feed preview with latest `posts`.
4. Care:
   - Add care schedule config per pet.
   - Surface offline/remote sync status.
   - Consider a sync queue for offline writes.
5. Marketplace:
   - Replace silent demo fallback with visible error/empty state.
   - Implement search/filter from local product list or Supabase query.
   - Persist cart if needed across sessions.

### Phase 4: UI/UX Fixes

1. Replace no-op controls with working actions, disabled states, or remove them.
2. Introduce shared screen header components for primary shell screens.
3. Add semantics labels/tooltips to icon-only controls and text fields.
4. Audit contrast and text scaling at 1.3x, 1.6x, and 2.0x.
5. Add per-screen adaptive layouts, not only adaptive shell navigation:
   - Compact: current stacked mobile flow.
   - Medium: constrained content width and side-by-side secondary panels.
   - Expanded: rail plus max-width content or master-detail layouts.
6. Add widget/golden tests for key states: loading, empty, error, authenticated data, no-op removal.

### Phase 5: QA Matrix

1. Android emulator: login, onboarding, pet switcher, care toggle sync, social reaction, matching request/chat, product cart, checkout cancellation.
2. Supabase verification: query row creation after each write flow and assert RLS isolation with a second user.
3. Responsive checks: <600 dp, 600-839 dp, >=840 dp.
4. Accessibility checks: TalkBack labels, focus order, minimum 48 dp tap targets.
5. Failure checks: offline, invalid credentials, expired JWT, Supabase 5xx, Stripe function failure.

## Research References

- Flutter architecture guide: https://docs.flutter.dev/app-architecture/guide
- Flutter adaptive approach: https://docs.flutter.dev/ui/adaptive-responsive/general
- Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility
- Supabase Flutter quickstart: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Supabase Auth: https://supabase.com/docs/guides/auth
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase secure data: https://supabase.com/docs/guides/database/secure-data
