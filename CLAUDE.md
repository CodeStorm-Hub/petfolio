# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Petfolio** is a Flutter mobile app combining a social network, pet discovery/matching platform, health tracker, and e-commerce marketplace. It uses **Supabase** for backend authentication and data, **Riverpod** for state management, **Go Router** for navigation, and **Stripe** for payments.

The live database has **31 tables**, **29 RPC functions**, and **78 applied migrations**. All major features are substantially live — the app is well past a prototype stage.

> **Note on docs:** `/docs/flutter_supabase_full_app_review_2026-05-13.md` and `/docs/database_schema_and_erd.md` are outdated and should not be relied upon for current status. The authoritative reference is this file and `REVIEW.md` at the project root.

## Development Setup

### Prerequisites
- Flutter 3.11.5+ SDK installed
- Dart 3.11.5+
- Android/iOS development tools (for emulator/device builds)

### Installation
```bash
flutter pub get
```

### Environment Variables
The app uses `--dart-define` for environment configuration. Default values for Supabase are hardcoded in `main.dart` for dev convenience, but **must** be overridden via `--dart-define` for production builds.

**Recommended: use a `.env` file (requires Dart 2.19+):**
```bash
flutter run --dart-define-from-file=.env
```

**.env file format:**
```
SUPABASE_URL=https://jqyjvhwlcqcsuwcqgcwf.supabase.co
SUPABASE_ANON_KEY=<anon-key>
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

Individual overrides:
```bash
flutter run \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## Common Commands

### Run The App
```bash
flutter run
```

### Code Generation
Run after modifying any `@freezed`, `@JsonSerializable`, or `@riverpod` annotated class:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode:
```bash
flutter pub run build_runner watch
```

### Static Analysis
```bash
flutter analyze
```

### Testing
```bash
flutter test
```

### Build
```bash
flutter build apk --debug    # debug
flutter build apk --release  # release
```

## Architecture Overview

### Feature-First Structure
Code is organized by feature under `/lib/features/`:
- **auth** — Supabase Auth (email/password sign-in, registration, password reset, session management)
- **pet_profile** — Pet onboarding (5-step flow), listing, reorder/archive, active pet switching, discoverability toggle
- **care** — Daily care tasks, streaks, XP/gamification, medical vault, health logs, nutrition
- **social** — Post feed, stories, likes, comments, comment likes, follows, notifications
- **matching** — Geo-based pet discovery (PostGIS swipe deck), mutual matches, real-time chat
- **marketplace** — Buyer: product catalog, cart, checkout, orders. Vendor: shop management, KYC, inventory, order fulfillment. Admin: KYC review, moderation, ledger.

Shared code is in `/lib/core/`:
- **domain/** — Shared models (`Pet`, `CareTask`), `ActivePetController`, `PetListController`, `PetRepository`
- **errors/** — `AppException` domain exception hierarchy
- **theme/** — `AppColors` (90+ tokens), `AppTheme` (full Material 3 + `ThemeExtension`), `ThemeNotifier`
- **widgets/** — Design system: `PetAvatar`, `GlassCard`, `PillButton`, `PrimaryPillButton`, `WaveHeader`, `PetSwitcherSheet`, `SkeletonLoader`, `TailWagLoader`, `ReactionBurst`, `PfStatTile`, etc.
- **router.dart** — GoRouter with `StatefulShellRoute`, 40+ routes, auth redirect via `_RouterNotifier`
- **services/** — `NotificationService`, `LocationService`, `LocationProviders`

### Data & Presentation Layers
Each feature follows this structure:
```
features/<feature>/
  data/
    models/          # Freezed + JsonSerializable classes
    repositories/    # Supabase queries and RPC calls
    datasources/     # (matching only) low-level Supabase layer
  presentation/
    controllers/     # Riverpod StateNotifiers / @riverpod notifiers
    screens/         # Route-target widgets
    widgets/         # Feature-specific reusable widgets
```

### State Management (Riverpod)
The codebase uses **two Riverpod patterns** — both are valid; be consistent within a file:

**Legacy pattern (most files):**
```dart
final myControllerProvider = StateNotifierProvider<MyController, AsyncValue<List<MyModel>>>((ref) {
  final repo = ref.watch(myRepositoryProvider);
  return MyController(repo);
});

class MyController extends StateNotifier<AsyncValue<List<MyModel>>> {
  MyController(this._repo) : super(const AsyncValue.loading()) { _load(); }
  Future<void> _load() async {
    state = await AsyncValue.guard(() => _repo.fetchItems());
  }
}
```

**New annotation pattern** (`@riverpod` — used in `theme_notifier`, `care_dashboard_controller`, `my_shop_controller`):
```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  Future<List<MyModel>> build() => ref.watch(myRepositoryProvider).fetchItems();
}
```

After adding/modifying a `@riverpod` class, run `build_runner` to regenerate the `.g.dart` file.

- Use `ref.watch()` in widgets to subscribe; `ref.read()` for one-off mutations
- Use `AsyncValue.when()` in UI for loading/data/error states
- Use `skipLoadingOnReload: true` on providers that should not flash a loading spinner on refresh

### Code Generation
- **Freezed** — immutable model classes with `copyWith` / equality
- **JsonSerializable** — `fromJson` / `toJson` methods
- **Riverpod Generator** — partially adopted; `@riverpod` annotation used in some controllers

After modifying any annotated class, regenerate:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Navigation (Go Router)
- Routes defined in `/lib/core/router.dart`
- `StatefulShellRoute` with 5 branches: Pets (`/home`), Care (`/care`), Social (`/social`), Match (`/match`), Market (`/market`)
- Adaptive nav: floating pill bottom bar ≤599dp; `NavigationRail` ≥600dp
- Auth redirect via `_RouterNotifier.redirect()` — watches `isLoggedInProvider`
- Admin route `/admin` is gated by `isAdminProvider` (widget-level check; route-level redirect not yet added)
- Initial route `/home`; unauthenticated → `/login`; no pets → `/onboarding`

## Feature Implementation Status

### Auth ✅ Fully Live
- Email/password sign-in, sign-up, password reset (email link)
- Session auto-refreshed by Supabase; token refresh does NOT re-trigger navigation (intentional — prevents spinner on 55-min rotation)

### Pet Profile ✅ Fully Live
- 23 pets across 10 users in DB
- Multi-step onboarding (5 steps with animations)
- Avatar upload to `pets` Supabase Storage bucket
- Reorder (drag-to-sort), archive, active pet persisted to SharedPreferences
- Per-pet discoverability toggle (controls visibility in Matching discovery)

### Care ✅ Fully Live
- 136 care tasks, 115 care logs, 7 streak records, 11 badges, 7 gamification rows
- `get_care_dashboard_snapshot` RPC loads all care data atomically
- Task frequencies: `once / daily / twice_daily / weekly / biweekly / monthly / as_needed`
- Gamification: XP points, badge unlocks, daily quest system
- Medical Vault: vaccines, medications, allergies, surgeries with expiry tracking
- Health logs: symptom, vet visit, medication, weight with severity field
- **Gap:** `health_vitals` table (5 rows) has no UI or repository — weight/temperature/heart-rate data is inaccessible

### Social ✅ Substantially Live
- 13 posts, 42 likes, 31 comments, 3 comment likes, 8 stories, 6 pet follows, 4 notifications
- `social_repository.dart` fetches real posts with pagination (15 per page)
- Post creation with multi-image upload to `post-images` bucket
- Real-time like/comment count sync via Supabase triggers (`handle_post_like_sync`, `handle_post_comment_sync`)
- Stories: 24h ephemeral content; `cleanup_expired_stories` RPC exists but **has no scheduler** — stories never auto-expire
- Pet follows, user follows (two separate systems: `pet_follows` for pet↔pet, `follows` for user↔user)
- Notifications table populated but **not wired to the UI bell/count**
- **Gap:** Comment reply threading — `comments.parent_id` exists in DB but UI has no reply button or threaded display

### Matching ✅ Substantially Live
- 118 swipes, 20 mutual matches, 16 match requests, 17 chat threads, 34 messages
- PostGIS geo-based discovery via `matching_discovery_candidates` RPC
- Swipe actions: `LIKE / PASS / GREET / SUPER_PAW` — all written to `swipes` table
- Mutual match created in `matches` table when both pets LIKE each other
- Real-time match detection via Supabase realtime on `matches` table → celebration overlay
- Chat with real-time messages via Supabase realtime on `chat_messages`
- **Important — Two matching systems coexist:**
  - `swipes` + `matches` — Tinder-style swipe flow; driven by the discovery UI
  - `match_requests` — Request/accept workflow (playdate/breeding/adoption); 16 rows, separate from swipe flow
  - `chat_threads` has both `mutual_match_id` (→ `matches`) and `match_request_id` (→ `match_requests`) FKs — threads can be created via either pathway

### Marketplace ✅ Substantially Live
- 7 shops, 11 products, 11 orders, 3 inventory reservations
- `process_checkout` RPC: atomic inventory reservation → order creation
- Inventory reservations expire in 15 minutes; `release_order_inventory` cleans up
- Buyer flow: browse → cart (SharedPreferences-persisted) → Stripe or COD checkout → order history
- Vendor flow: shop creation → KYC (Stripe Connect or manual document upload) → product CRUD → order fulfillment with tracking
- Admin: KYC approve/reject, content moderation, COD reconciliation, shop deletion review
- **Gap:** No Stripe webhook — payment confirmation is client-side only; PaymentIntent success is not server-verified
- **Gap:** `vendor_ledgers` has 0 rows despite 11 orders — `process_checkout` is not writing ledger entries; vendor earnings are untracked
- **Gap:** KYC rejection reason stored in DB but not displayed to vendor in UI

## Supabase Integration

### Project Details
- **URL**: https://jqyjvhwlcqcsuwcqgcwf.supabase.co
- **Region**: ap-northeast-1 (Japan)
- **Database**: PostgreSQL 17.6.1
- **Status**: Active & Healthy
- **All tables have RLS enabled**
- **78 migrations applied**

### Connection & Auth
- Supabase client initialized in `main.dart`
- Auth state streamed via `authStateProvider` (Riverpod)
- Repositories inject `SupabaseClient` via `ref.watch(supabaseProvider)`
- Admin access determined at runtime by `is_admin()` DB function (not a JWT claim)

### Database Schema (31 Tables, RLS Enabled)

| Table | Rows | Purpose | App Status |
|-------|------|---------|-----------|
| `users` | 10 | User profiles (username, display_name, avatar, bio, location) | Connected |
| `pets` | 23 | Pet profiles per owner (species, breed, DOB, gender, weight, handle, location, discoverability) | Connected |
| `care_tasks` | 136 | Scheduled care tasks per pet (type, frequency, gamification points, AI-suggested flag) | Connected |
| `care_logs` | 115 | Daily care completion log (care_type, logged_date, duration) | Connected |
| `care_streaks` | 7 | Current + best streak per pet | Connected |
| `pet_badges` | 11 | Unlocked achievement badges per pet | Connected |
| `pet_care_gamification` | 7 | Total XP and daily award tracking per pet | Connected |
| `health_logs` | 15 | Narrative health records (symptom, vet visit, medication, weight) | Connected — Medical Vault UI |
| `medical_vault` | 2 | Structured medical records (vaccines, medications, allergies, surgeries) | Connected — Medical Vault UI |
| `health_vitals` | 5 | Numeric vitals (weight, temperature, heart_rate, blood_pressure, glucose) | **No UI — orphaned data** |
| `posts` | 13 | Social feed posts (content, image_urls, visibility, like/comment counts) | Connected |
| `post_likes` | 42 | Post likes (user + pet attribution) | Connected |
| `comments` | 31 | Post comments (content, like_count, parent_id for replies) | Connected |
| `comment_likes` | 3 | Comment likes | Connected |
| `stories` | 8 | 24h ephemeral pet stories (viewed_by_users array) | Connected — **no auto-cleanup scheduler** |
| `pet_follows` | 6 | Pet-to-pet follows | Connected |
| `follows` | 4 | User-to-user follows | Connected |
| `notifications` | 4 | In-app notifications (like, comment, follow, kyc, shop_deletion) | **DB live, UI bell not wired** |
| `reported_posts` | 0 | User-submitted content reports | Admin UI connected |
| `swipes` | 118 | Pet swipe actions (LIKE / PASS / GREET / SUPER_PAW) | Connected |
| `matches` | 20 | Mutual matches between pets (from swipes) | Connected |
| `match_requests` | 16 | Formal match requests (playdate/breeding/adoption workflow) | Separate system from swipes |
| `chat_threads` | 17 | DM threads between users (links to mutual_match or match_request) | Connected |
| `chat_messages` | 34 | Messages within chat threads | Connected |
| `products` | 11 | Marketplace product catalog (shop-owned, with inventory count) | Connected |
| `shops` | 7 | Vendor shops (KYC status, Stripe Connect, payout method, policies) | Connected |
| `marketplace_orders` | 11 | Buyer orders (Stripe or COD, shipping tracking, line_items JSONB) | Connected |
| `vendor_ledgers` | 0 | Vendor earnings per order | **Schema ready — never populated** |
| `inventory_reservations` | 3 | 15-min hold on inventory during checkout | Connected |
| `shop_deletion_requests` | 2 | Admin-reviewed shop deletion workflow | Connected |
| `audit_logs` | 6 | Admin action audit trail | Connected |

### RPC Functions (29 total)

| Function | Called By | Notes |
|----------|-----------|-------|
| `get_care_dashboard_snapshot` | `PetCareRepository` | Atomic care data load |
| `check_daily_completion` | DB trigger on `care_logs` | Updates streak after log insert |
| `get_pet_awards_summary` | Care presentation | Badges + XP aggregate |
| `matching_discovery_candidates` | `MatchingSupabaseDataSource` | PostGIS geo-filtered candidates |
| `get_match_inbox` | `MatchingSupabaseDataSource` | Thread + last-message snapshot |
| `ensure_chat_thread_for_match` | `MatchingSupabaseDataSource` | Upsert thread on match accept |
| `get_or_create_social_thread` | Social repo | Upsert DM thread for user pair |
| `process_checkout` | `CheckoutController` | Atomic: reserve inventory → create order |
| `confirm_order_inventory` | `CheckoutController` | Confirm reservation after payment |
| `release_order_inventory` | `CheckoutController` | Release expired/cancelled reservation |
| `cancel_order` | `OrderRepository` | Buyer cancellation |
| `vendor_update_order` | `VendorOrderRepository` | Vendor ships / marks delivered |
| `approve_vendor_kyc` | `AdminRepository` | Admin approves KYC |
| `reject_vendor_kyc` | `AdminRepository` | Admin rejects KYC with reason |
| `resolve_reported_post` | `AdminRepository` | Dismiss or hide reported post |
| `request_shop_deletion` | `DeletionRequestController` | Vendor requests shop deletion |
| `resolve_shop_deletion` | `AdminRepository` | Admin approves/rejects deletion |
| `set_pet_location_point` | `LocationService` | Update pet PostGIS geography column |
| `get_pet_stats` | `SocialRepository` | Follower/post count per pet |
| `mark_story_viewed` | `StoryRepository` | Append viewer UUID to story array |
| `cleanup_expired_stories` | **No caller — needs Edge Function** | Purge stories >24h old |
| `is_admin` | RLS policies + `isAdminProvider` | Runtime admin role check |
| `handle_post_like_sync` | DB trigger | Sync `posts.like_count` |
| `handle_post_comment_sync` | DB trigger | Sync `posts.comment_count` |
| `handle_comment_like_sync` | DB trigger | Sync `comments.like_count` |
| `handle_new_chat_message` | DB trigger | Update `chat_threads.last_message_at` |
| `handle_updated_at` / `set_updated_at` | DB triggers | Maintain `updated_at` timestamps |
| `rls_auto_enable` | Migration tooling | Enable RLS on new tables |

### Storage Buckets
- `pets` — pet avatar images (onboarding + edit profile)
- `post-images` — post images (multi-image social posts)
- `marketplace-images` — product images (vendor product listing)
- `shops` — shop logo and banner images
- `medical-documents` — Medical Vault document attachments

### Security Notes
- ⚠️ **Leaked Password Protection disabled** — enable HaveIBeenPwned in Supabase Auth settings
- ⚠️ **`bank_account_details` stored as plain JSONB** in `shops` — move to encrypted storage or use Stripe bank account tokens
- All tables have RLS enabled; `is_admin()` function enforces admin-table access at the DB level
- Admin route `/admin` lacks a GoRouter redirect guard (widget shows "Access Denied" instead of redirecting)

### Migrations
78 migrations applied. The migration history in `supabase/migrations/` is the authoritative schema source. Run `supabase db pull` to sync if local files drift.

### Current Database State (as of 2026-05-27)
- 10 users, 23 pets, 7 shops, 11 products, 11 orders
- 136 care tasks, 115 care logs, 7 streaks, 11 badges
- 13 posts, 42 likes, 31 comments, 8 stories
- 118 swipes, 20 matches, 16 match requests, 17 chat threads, 34 messages
- `vendor_ledgers`: 0 rows (bug — not populated by `process_checkout`)

### Querying Tips
- **Care dashboard:** Always use `get_care_dashboard_snapshot` RPC — do not query tasks/logs/streaks individually
- **Discovery:** Use `matching_discovery_candidates` RPC with PostGIS; requires pet `location` column to be set via `set_pet_location_point`
- **Chat threads:** Filter by `participant_1_id` OR `participant_2_id` (both are user IDs, not pet IDs)
- **Match inbox:** Use `get_match_inbox` RPC — do not join chat_threads + messages manually
- **Products:** Query `products` joined to `shops`; filter `active = true` and `inventory_count > 0` for available items
- **Stories:** Filter `created_at > now() - interval '24 hours'` — cleanup RPC has no scheduler so expired rows may exist

## Code Patterns & Conventions

### Models (Freezed)
```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

### Repositories
- Created per feature; injected into controllers via `ref.watch`
- Use `try/catch` for network errors; throw domain exceptions (`AppException` subclasses)
- Use RPC functions for any operation touching more than one table
- Do not use fallback/demo data — surface errors explicitly

```dart
class MyRepository {
  final SupabaseClient _supabase;
  const MyRepository(this._supabase);

  Future<List<MyModel>> fetchItems() async {
    final data = await _supabase.from('my_table').select();
    return data.map(MyModel.fromJson).toList();
  }
}
```

### UI Patterns
- Use `Theme.of(context).extension<PetFolioColors>()!` only where the variable is actually used — do not extract it and then ignore it
- Use `AppColors.*` tokens, not raw `Color(0xFF...)` or `Colors.*` literals
- `SafeArea` + `SingleChildScrollView` for most screens
- `AsyncValue.when()` for loading/data/error states
- Shared widgets: `PetAvatar`, `GlassCard`, `PillButton`, `PrimaryPillButton`, `SkeletonLoader`, `TailWagLoader`

## Known Gaps (Prioritised)

### P0 — Production Risk
1. **No Stripe webhook** — Stripe payment success is not server-verified; use a Supabase Edge Function to receive `payment_intent.succeeded` events and confirm the order
2. **`vendor_ledgers` never populated** — fix `process_checkout` RPC to insert a ledger entry per order
3. **`bank_account_details` as plain JSONB** — replace with Stripe bank account tokens
4. **`cleanup_expired_stories` has no scheduler** — create a Supabase Edge Function on a cron schedule (e.g., every hour)

### P1 — Feature Gaps
5. **Notifications UI not wired** — `NotificationsScreen`, `notification_repository.dart`, and `notification_controller.dart` all exist; connect bell count to live `notifications` table query
6. **`health_vitals` orphaned** — 5 rows in DB; implement repository + UI or drop the table
7. **KYC rejection reason not shown to vendor** — read `shops.rejection_reason` and display it on the seller dashboard when `kyc_status = 'rejected'`
8. **Admin route not redirect-guarded** — add a redirect in `_RouterNotifier` for `/admin` when `!isAdmin`
9. **`inventory_count` defaults to 0** — warn vendor in the add-product form when inventory is 0 before saving

### P2 — Tech Debt
10. **Monolithic screen files** — split files over ~600 lines: `care_screen.dart` (1923), `seller_dashboard_screen.dart` (1217), `matching_screen.dart` (1127), `social_screen.dart` (966), `onboarding_screen.dart` (842), `manage_pets_screen.dart` (781)
11. **Unused `pc` extractions** — delete all `// ignore: unused_local_variable` for `pc` where the variable is never read
12. **`care_repository.dart` stub** — the file only re-exports `pet_care_repository.dart`; remove the indirection
13. **Router index-coupling** — `_tabColors` and `_destinations` arrays are positionally coupled to route order; convert to a named map
14. **Mixed Riverpod patterns** — pick one (`StateNotifier` vs `@riverpod`) and migrate consistently
15. **`cupertino_icons` unused** — remove from `pubspec.yaml`

## Testing

### Current Status
- `test/widget_test.dart` is a placeholder — wrapping `PetfolioApp` in `ProviderScope` with mocked Supabase is required before it can pass
- No integration or unit tests

### To Add Tests
1. Add `mocktail` to dev dependencies
2. Create abstract repository interfaces for mocking
3. Wrap test app in `ProviderScope` with `overrides` that inject mock repos
4. Test controller state transitions (`AsyncLoading` → `AsyncData` / `AsyncError`)

## Building & Deployment

### Pre-commit Checklist
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

### Build
```bash
flutter build apk --release --dart-define-from-file=.env
flutter build ios --release --dart-define-from-file=.env
```

## Supabase Development Workflow

### Schema Changes
1. Write a new migration file in `supabase/migrations/`
2. Test locally: `supabase start && supabase db reset`
3. Apply to production: `supabase db push --project-id jqyjvhwlcqcsuwcqgcwf`
4. Update the Database Schema table in this file

### Pulling Live Schema
```bash
supabase db pull --project-id jqyjvhwlcqcsuwcqgcwf
```

### RLS Reminder
All queries run as the authenticated user. Test with a real session token. If getting 0 rows on a table that should have data, check RLS policies in the Supabase dashboard before assuming a code bug.

## Common Pitfalls

1. **Forget to run `build_runner`** — After changing any `@freezed`, `@JsonSerializable`, or `@riverpod` class, generated `.g.dart` / `.freezed.dart` files must be regenerated. Hot reload will not pick up generated code changes.

2. **Active pet context** — Most feature providers scope data to the current active pet via `activePetIdProvider`. Always test switching pets to ensure providers invalidate and reload correctly.

3. **Two matching systems** — `swipes`/`matches` (Tinder-style, driven by discovery UI) and `match_requests` (playdate/breeding/adoption, separate request flow) are distinct systems that share the `chat_threads` table. Do not conflate them.

4. **`chat_threads` dual FK** — A thread can be linked via `mutual_match_id` (from a swipe match) OR `match_request_id` (from a formal request). Both FKs are nullable. Ensure any new thread-creation code sets the correct one.

5. **`vendor_ledgers` always empty** — Do not build any payout or earnings UI that reads from this table until the `process_checkout` bug is fixed (see P0 gap #2 above).

6. **Marketplace demo fallback** — `product_repository.dart` silently returns hardcoded demo products on any Supabase error. This hides real failures. Remove the fallback before shipping.

7. **Auth redirect logic** — `_RouterNotifier.redirect()` runs on every navigation. If adding a new protected route, ensure it is covered by the redirect conditions.

8. **Environment variables in release builds** — Never rely on `main.dart` default values for production. Always pass `--dart-define-from-file=.env`.

9. **Story expiry** — `cleanup_expired_stories` RPC must be called explicitly (e.g., from a scheduled Edge Function). Until a scheduler exists, filter stories by `created_at > now() - interval '24 hours'` in every query.

10. **Hardcoded colors** — Use `AppColors.*` tokens and `Theme.of(context).extension<PetFolioColors>()!` — not raw `Colors.white`, `Colors.grey`, or `Color(0xFF...)` literals. The app supports both light and dark themes.

## Reference Documents

- **Comprehensive codebase & UX review (current)**: `/REVIEW.md`
- **Theme & Design tokens**: `/lib/core/theme/`
- **Router & all routes**: `/lib/core/router.dart`
- **Shared widgets**: `/lib/core/widgets/`
- **Supabase migrations**: `/supabase/migrations/`

## Project Rules & Token Optimization Strategy

### 1. Strict No-Documentation Rule (Implementation Only)
* **Code Only:** Do not write any inline comments, dartdocs (`///`), explanations of code, or standalone documentation files. Focus 100% of your output on functional task implementations.
* **Explicit Override:** You may only write documentation if I explicitly command you with a prompt like "write a documentation file for this." Otherwise, output clean, uncommented code.

### 2. State Management & Session Resets (The `progress.md` Pattern)
* **Maintain State:** You must actively maintain a `progress.md` file at the root of the project.
* **Log & Wipe:** After completing a distinct phase of a feature, update `progress.md` with a concise bulleted summary of what was implemented, any new data contracts/models created, and the immediate next step.
* **Prompt to Clear:** After updating `progress.md`, you MUST explicitly advise the user: "Phase complete — please run (/remember) to save tokens before proceeding to the next phase."

### 3. Aggressive Context Scoping
* **Blind by Default:** Do not scan, grep, or read the entire codebase to "understand the app".
* **Targeted Reads:** Only read files in directories explicitly related to the current task. If working on Pet Care UI, only read `lib/features/care/` and shared widgets in `lib/core/widgets/`.
* **Respect Ignores:** Strictly adhere to the `.claudeignore` file. Never attempt to read UI design dumps, `.g.dart` generated files, or native Android/iOS folders unless explicitly commanded.

### 4. Output Formatting & Boilerplate Reduction
* **Targeted Diffs:** When updating an existing file, do not rewrite the entire file if you only changed one method. Output only the specific class, widget, or method that changed, along with instructions on where to place it.
* **No Unnecessary Explanations:** Do not explain standard Flutter/Dart concepts or write essays about how the code works unless asked.

### 5. Strict Sequential Execution
When given a full feature to implement, execute strictly in this order, waiting for user confirmation or session clears between steps:
1. Supabase SQL Schema & RLS (migration file)
2. Dart Models (Freezed/JsonSerializable)
3. Repositories (Supabase DB / RPC calls)
4. State Management (Controllers)
5. UI/UX Implementation
