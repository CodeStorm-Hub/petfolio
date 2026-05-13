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

### Mostly Connected (Ready for Use)
- **Auth** — email/password sign-in/sign-up, session management
- **Pet Profile** — onboarding, listing, avatar upload, active pet switching
- **Care** — daily checklist persistence (care_logs table)
- **Marketplace** — product catalog, cart, order creation

### Partially Connected (Needs Work)
- **Care Reminders & Health Streak** — hardcoded in UI; should query `care_logs` and `health_vitals`
- **Product Fallback** — silent fallback to demo catalog on fetch errors; should show visible error states
- **Checkout** — order creation works; confirmation status is client-side only (no Stripe webhook verification)

### Mock / Disconnected (Do Not Rely On)
- **Social Feed** — entirely mock data; does not fetch `posts` table
- **Matching Discovery** — entirely mock swipe deck; code expects `swipes`/`matches` tables that do not exist
- **Matching Chat** — chat thread model mismatch (code expects `pet_id_1/pet_id_2`, DB has `participant_1_id/participant_2_id`)

### Database Schema Mismatches
- Matching feature writes to nonexistent `swipes` and `matches` tables
- Chat threads in code assume pet-based participants; actual schema uses user participants + `match_request_id`
- See `/docs/flutter_supabase_full_app_review_2026-05-13.md` **High Priority** section for full list

## Supabase Integration

### Connection & Auth
- Supabase client initialized in `main.dart` with URL and anon key
- Auth state streamed via `authStateProvider` (Riverpod)
- Repositories inject `SupabaseClient` via constructor or `ref.watch(supabaseProvider)`

### Key Tables
| Table | Purpose | Status |
|-------|---------|--------|
| `users` | User profiles (username, avatar, bio) | Connected |
| `pets` | Pet profiles per owner | Connected |
| `care_logs` | Daily checklist entries (feed/walk/med) | Connected |
| `products` | Marketplace catalog | Connected |
| `marketplace_orders` | Order history | Connected |
| `posts` | Social feed (author, content, images) | Exists but not queried |
| `match_requests` | Breeding/playdate/adoption requests | Schema exists; code doesn't match |
| `chat_threads` | Conversations between users | Schema mismatch in code |

### Storage
- `pets` bucket — pet avatar uploads during onboarding

### Advisors (From Review)
- Missing FK indexes on match/post reactions (performance optimization)
- Leaked password protection disabled (security setting)

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

## Common Pitfalls & Tips

1. **Forget to regenerate code** — After changing `@freezed` or `@JsonSerializable` classes, run `build_runner`. Hot reload won't pick up generated code changes.

2. **Mock data in controllers** — Matching and Social features return mock data from notifiers. Check the QA review to see which features have real DB backing.

3. **Hardcoded theme tokens** — Many screens use hardcoded `Colors.*` and `TextStyle` instead of `AppTheme`. Prefer theme references for consistency.

4. **No-op UI controls** — Several button/header taps are empty (`onTap: () {}`). These are placeholders; see the QA review for a full list.

5. **Fallback demo data hides errors** — Marketplace silently shows demo products on fetch failure. Consider visible error states instead.

6. **Auth redirect logic** — `_RouterNotifier.redirect()` watches `isLoggedInProvider` and blocks unauthenticated routes. If adding protected routes, ensure the redirect includes them.

7. **Environment variables** — Supabase/Stripe keys are hardcoded in `main.dart` defaults; use `--dart-define` for production builds.

## Reference Documents

- **Comprehensive QA & Implementation Plan**: `/docs/flutter_supabase_full_app_review_2026-05-13.md`
- **Database Schema**: `/docs/database_schema_and_erd.md`
- **Theme & Design**: `/lib/core/theme/`
- **Router & Navigation**: `/lib/core/router.dart`
