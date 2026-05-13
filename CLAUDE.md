# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Petfolio** is a Flutter mobile app combining a social network, pet discovery/matching platform, health tracker, and e-commerce marketplace. It uses **Supabase** for backend authentication and data, **Riverpod** for state management, **Go Router** for navigation, and **Stripe** for payments.

Architecture documents are in `/docs`:
- `flutter_supabase_full_app_review_2026-05-13.md` — comprehensive QA review covering features, DB mapping, implementation gaps, and phase-by-phase recommendations
- `database_schema_and_erd.md` — Supabase public schema with all tables, columns, constraints, and relationships
- `database_schema_review.md` — schema analysis and notes

Read the full review before starting substantial work; it details which features are connected vs. mock/broken.

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
Create `.env` file (copy from `.env.example`) with:
```
SUPABASE_URL=<your-supabase-project-url>
SUPABASE_ANON_KEY=<your-anonymous-key>
```

Default values are hardcoded in `main.dart` for dev/test but should be injected via `--dart-define` for production.

For Stripe, inject `STRIPE_PUBLISHABLE_KEY` at build time:
```bash
flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

## Common Commands

### Run The App
```bash
flutter run
```

### Code Generation
Run after modifying models (Freezed, JsonSerializable, Riverpod):
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
All tests (currently only one placeholder test exists):
```bash
flutter test
```

Single test file:
```bash
flutter test test/widget_test.dart
```

### Build
Debug APK (Android emulator/device):
```bash
flutter build apk --debug
```

Release APK:
```bash
flutter build apk --release
```

## Architecture Overview

### Feature-First Structure
Code is organized by feature under `/lib/features/`:
- **auth** — Supabase Auth (email/password sign-in, registration, session management)
- **pet_profile** — Pet onboarding, list, active pet switching (mostly connected)
- **care** — Daily checklist for feeding/walks/meds (partially connected, some local state)
- **matching** — Pet discovery swipe deck, match requests (largely mock data, schema mismatches)
- **social** — Post feed, likes, memorial candles (mock feed, partial write support)
- **marketplace** — Product catalog, cart, checkout (mostly connected, fallback demo data)

Shared code is in `/lib/core/`:
- **theme/** — `AppTheme`, `AppColors` (light/dark support)
- **widgets/** — `GlassCard`, `PetAvatar`, `PrimaryPillButton`, `SkeletonLoader`
- **router.dart** — Go Router configuration, route definitions, `_RouterNotifier` for auth redirects

### Data & Presentation Layers
Each feature follows this structure:
```
features/<feature>/
  data/
    models/          # Freezed classes (JSON serializable)
    repositories/    # Supabase queries; interface pattern not enforced
  presentation/
    controllers/     # Riverpod StateNotifiers / notifier providers
    screens/         # Main widgets (route targets)
    widgets/         # Feature-specific reusable widgets
```

### State Management (Riverpod)
- Repository providers expose Supabase clients via constructor injection
- Notifier providers wrap repositories and expose derived/computed state
- Controllers use `StateNotifier` for async operations (loading/data/error)
- Use `ref.watch()` in widgets to subscribe; `ref.read()` for one-off access

Example pattern:
```dart
final myNotifierProvider = StateNotifierProvider((ref) {
  final repo = ref.watch(myRepositoryProvider);
  return MyNotifier(repo);
});
```

### Code Generation
- **Freezed** — immutable model classes with copy/equality
- **JsonSerializable** — `fromJson`/`toJson` methods (run `build_runner` after edits)
- **Riverpod Generator** (not yet adopted; legacy pattern used)

After modifying `@freezed` or `@JsonSerializable` classes, regenerate:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Navigation (Go Router)
- Routes defined in `/lib/core/router.dart`
- Shell navigation (`ShellRoute`) wraps main tabs with bottom nav (phone) or nav rail (600 dp+)
- Auth redirect via `_RouterNotifier.redirect()` watches `isLoggedInProvider`
- Initial route is `/home`; unauthenticated users redirect to `/login`

## Known Gaps & Implementation Status

### Fully Connected & Working
- **Auth** — email/password sign-in/sign-up, session management ✓
- **Pet Profile** — onboarding, listing, avatar upload (pets bucket), active pet switching ✓
- **Care Checklist** — daily logging to `care_logs` table with `logged_date` uniqueness constraint ✓
- **Marketplace** — 8 products in DB, product catalog, cart, order creation with Stripe payment intent ✓

### Partially Implemented
- **Care Reminders & Health Streak** — hardcoded in UI; `care_logs` table exists but UI doesn't compute from it; `health_vitals` table exists but unused
- **Product Fallback** — silent fallback to demo catalog on fetch errors; should show visible error states
- **Checkout** — order creation works; confirmation status is client-side only (no Stripe webhook verification)
- **Social Reactions** — `post_likes` and `post_candles` tables exist; code has partial write support but no feed fetch

### Mock / Disconnected (Do Not Rely On)
- **Social Feed** — entirely mock data; app doesn't fetch `posts` table (0 rows)
- **Matching Discovery** — entirely mock swipe deck with sample data (0 match_requests in practice)
- **Matching Chat** — critical schema mismatch: code expects `chat_threads.pet_id_1` and `chat_threads.pet_id_2`, but DB has `participant_1_id` and `participant_2_id` (user-based)
- **Health Vitals** — table exists in DB with proper schema but no UI or repository implementation

### Critical Schema Mismatches
1. **Chat Threads (Broken)**:
   - ❌ Code expects: `chat_threads.pet_id_1`, `chat_threads.pet_id_2`
   - ✓ DB has: `chat_threads.participant_1_id`, `participant_2_id` (user participants)
   - DB also has: `match_request_id` (foreign key to accepted requests)

2. **Matching Swipe Logic**:
   - ❌ Code writes to nonexistent `swipes` and `matches` tables
   - ✓ DB has: `match_requests` table with proper requester/target pet/user logic
   - Approach: Refactor discovery to build queries from `match_requests` status and visibility

3. **Post Reactions**:
   - ✓ `post_likes` and `post_candles` tables exist
   - ⚠️ Code can write reactions but feed doesn't fetch posts, so reactions won't display

See `/docs/flutter_supabase_full_app_review_2026-05-13.md` **High Priority** and **Phase 2/3** sections for detailed implementation roadmap.

## Supabase Integration

### Project Details
- **URL**: https://jqyjvhwlcqcsuwcqgcwf.supabase.co
- **Region**: ap-northeast-1 (Japan)
- **Database**: PostgreSQL 17.6.1
- **Status**: Active & Healthy
- **All tables have RLS (Row Level Security) enabled**

### Connection & Auth
- Supabase client initialized in `main.dart` with URL and anon key
- Auth state streamed via `authStateProvider` (Riverpod)
- Repositories inject `SupabaseClient` via constructor or `ref.watch(supabaseProvider)`

### Database Schema (12 Tables, RLS Enabled)
| Table | Rows | Purpose | Status |
|-------|------|---------|--------|
| `users` | 3 | User profiles (username, avatar, bio) | Connected |
| `pets` | 2 | Pet profiles per owner | Connected |
| `care_logs` | 0 | Daily checklist (care_type, logged_date unique constraint) | Connected |
| `health_vitals` | 0 | Health tracking (weight, temp, heart rate, etc.) | Schema exists, UI not implemented |
| `products` | 8 | Marketplace catalog (food, gear, toys, treats, health, grooming) | Connected |
| `marketplace_orders` | 1 | Order history with Stripe payment intent tracking | Connected |
| `posts` | 0 | Social feed (author, pet, content, images, visibility) | Exists but not queried by app |
| `post_likes` | 0 | Social reactions (user/pet can like posts) | Exists, code partially connected |
| `post_candles` | 0 | Memorial candles on posts (user/pet can light candles) | Exists, code partially connected |
| `match_requests` | 1 | Pet matching requests (playdate/breeding/adoption) | Schema exists; code schema-incompatible |
| `chat_threads` | 0 | Conversations between users (user participants, match_request_id) | Schema mismatch: code expects pet_id_1/pet_id_2 |
| `chat_messages` | 0 | Messages in chat threads | Not implemented in app |

### Storage
- `pets` bucket — pet avatar uploads during onboarding

### Security Advisors (From Supabase Linter)
- ⚠️ **Leaked Password Protection Disabled** — Enable HaveIBeenPwned.org integration in Auth settings to prevent compromised passwords
  - Reference: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### Performance Advisors (From Supabase Linter)
- 6 unindexed foreign keys (INFO level):
  - `match_requests.requester_pet_id` and `match_requests.target_pet_id`
  - `post_likes.pet_id` and `post_likes.user_id`
  - `post_candles.pet_id` and `post_candles.user_id`
  - Reference: https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys

- 16+ unused indexes (INFO level) — Not critical; database is new with minimal production usage. Do not drop before real workload analysis.
  - Reference: https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index

### Migrations
- **20260512000000_marketplace** — Only migration applied; schema initialized via Supabase dashboard or other tooling

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
- Repositories are created per feature and injected into notifiers
- Use `try/catch` for network errors; expose via controller state
- Repository pattern is not yet strict (interface abstraction optional)

Example:
```dart
class MyRepository {
  final SupabaseClient _supabase;

  MyRepository(this._supabase);

  Future<List<MyModel>> fetchItems() async {
    final response = await _supabase
        .from('my_table')
        .select()
        .then((data) => (data as List).map(MyModel.fromJson).toList());
    return response;
  }
}
```

### Controllers (StateNotifier)
```dart
final myControllerProvider = StateNotifierProvider((ref) {
  final repo = ref.watch(myRepositoryProvider);
  return MyController(repo);
});

class MyController extends StateNotifier<AsyncValue<List<MyModel>>> {
  final MyRepository _repo;

  MyController(this._repo) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.fetchItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

### UI Patterns
- Use `AppTheme` tokens for colors/typography (not hardcoded `Colors.blue`)
- `SafeArea` + `SingleChildScrollView` for most screens
- `AsyncValue.when()` for loading/data/error states
- Shared widgets: `PetAvatar`, `GlassCard`, `PrimaryPillButton`, `SkeletonLoader`

## Testing

### Current Status
- `test/widget_test.dart` is a placeholder (fails immediately; needs `ProviderScope` wrapper)
- No integration or unit tests currently

### To Add Tests
1. Wrap `PetfolioApp` in `ProviderScope` and mock Supabase dependencies
2. Add focused tests for repositories (mock `SupabaseClient`)
3. Add controller state transition tests (via `StateNotifierProvider` instantiation)

## Building & Deployment

### Lint & Analyze Before Commit
```bash
flutter analyze
```

Resolve analyzer issues (currently 8 info-level; no errors).

### Build Steps
1. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
2. Analyze: `flutter analyze`
3. Test: `flutter test`
4. Build: `flutter build apk --release` (or appropriate platform)

## Supabase Development Workflow

### Testing Database Changes Locally
If making schema changes:
1. Use Supabase CLI for local development: `supabase start` / `supabase stop`
2. Write migrations in `supabase/migrations/`
3. Test locally before applying to production project (`jqyjvhwlcqcsuwcqgcwf`)
4. RLS policies are enforced on all tables — test with appropriate user context

### Current Database State
- 3 users, 2 pets, 1 match_request, 1 marketplace_order, 8 products (test data)
- 0 posts, 0 care_logs, 0 health_vitals (empty feature tables)
- All tables RLS-enabled; queries require proper auth context

### Querying Tips
- **Care logs**: Use `logged_date` for efficient daily grouping (has CURRENT_DATE default)
- **Products**: 8 catalog items ready; category field supports (food, gear, toys, treats, health, grooming)
- **Match requests**: Check `status` (pending/accepted/rejected/cancelled) and `match_type` (playdate/breeding/adoption)
- **Chat threads**: Filter by `participant_1_id` or `participant_2_id` (user IDs, not pet IDs)

## Common Pitfalls & Tips

1. **Forget to regenerate code** — After changing `@freezed` or `@JsonSerializable` classes, run `build_runner`. Hot reload won't pick up generated code changes.

2. **Mock data in controllers** — Matching and Social features return mock data from notifiers. Check the QA review to see which features have real DB backing.

3. **Hardcoded theme tokens** — Many screens use hardcoded `Colors.*` and `TextStyle` instead of `AppTheme`. Prefer theme references for consistency.

4. **No-op UI controls** — Several button/header taps are empty (`onTap: () {}`). These are placeholders; see the QA review for a full list.

5. **Fallback demo data hides errors** — Marketplace silently shows demo products on fetch failure. Consider visible error states instead.

6. **Auth redirect logic** — `_RouterNotifier.redirect()` watches `isLoggedInProvider` and blocks unauthenticated routes. If adding protected routes, ensure the redirect includes them.

7. **Environment variables** — Supabase/Stripe keys are hardcoded in `main.dart` defaults; use `--dart-define` for production builds.

8. **Chat schema mismatch** — Flutter code uses `pet_id_1`/`pet_id_2` but DB uses `participant_1_id`/`participant_2_id` (user participants). This is a blocking issue for chat features.

9. **RLS policies** — All queries run as the logged-in user. Public reads may require explicit policy configuration. Check Supabase dashboard if getting 0 rows on expected queries.

## Reference Documents

- **Comprehensive QA & Implementation Plan**: `/docs/flutter_supabase_full_app_review_2026-05-13.md`
- **Database Schema**: `/docs/database_schema_and_erd.md`
- **Theme & Design**: `/lib/core/theme/`
- **Router & Navigation**: `/lib/core/router.dart`
