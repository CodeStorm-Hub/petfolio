## Role & Architecture Rules

You are an expert Flutter and Supabase developer. For the PetFolio project, you must strictly adhere to the following rules:

1. **Feature-First Architecture**: All code must live within `lib/features/<feature_name>/` and be cleanly divided into presentation, domain, and data layers.
2. **State Management**: You are strictly forbidden from using Riverpod. You must exclusively use the Provider package for all state management and dependency injection workflows.
3. **Supabase Performance**:
   - Avoid client-side data joining (N+1 queries). Push complex relational logic and aggregations to Postgres Views or RPCs.
   - When writing Row Level Security (RLS) policies, always wrap authentication checks in a subselect, such as `(select auth.uid())`, to force the Postgres optimizer to cache the result and prevent severe performance degradation.
   - Never generate queries that could result in full table scans; always utilize appropriate indexing.

## Learned User Preferences

- When applying Supabase schema to the hosted project, prefer the Supabase MCP migration path when available; if using the Supabase CLI, prefix commands with `npx` (for example `npx supabase db push`).
- After completing a distinct care or backend phase, keep `progress.md` updated and use `/remember` to persist high-signal context before starting the next phase.
- Avoid importing `router.dart` from screens that `router.dart` already imports; use literal paths or query strings for deep links to prevent circular imports.
- For optimistic UI on task toggles, revert local state and surface failures with `AppSnackBar.showError` when the repository call fails.
- When a subagent result is already visible in the UI, avoid re-summarizing it unless multi-task synthesis is needed; a short third-person completion note is enough, and avoid repeating the same confirmation every turn.
- When asked to save audits, reviews, or comparable findings, write them as Markdown under the repository root unless a different path is specified.

## Learned Workspace Facts

- Care routes: shell `/care`, full-screen `/care/nutrition` and `/care/medical-vault`; successful onboarding navigates to `/care?onboardingComplete=1`, shows a one-shot success snackbar, then normalizes the URL to `/care`.
- `careDashboardProvider` and `healthVaultControllerProvider` are non-family providers that watch `activePetIdProvider`; a null active pet yields empty tasks or an empty medical list and skips remote loads.
- Daily streak completion is driven by the `check_daily_completion` RPC (`target_pet_id`, optional `completion_date` matching `care_logs.logged_date`) against `care_tasks` and `care_logs`, with streak state in `care_streaks` and badges in `pet_badges`; the dashboard also listens to Supabase realtime on `care_streaks` via `careStreakRealtimeProvider` for immediate streak UI sync.
- App-wide snackbars for notifier-triggered errors use `appSnackBarMessengerKey` on `MaterialApp.router` and `AppSnackBar.showError` from `lib/core/widgets/app_snack_bar.dart`.
- `analysis_options.yaml` excludes only `*.g.dart` from the analyzer (not `*.freezed.dart`; Freezed `part` files must be analyzed).
- PostGIS match chat: routes `/matching/inbox` and `/matching/chat/:threadId`; `chat_threads.mutual_match_id` references `matches.id`; lazy thread creation via `ensure_chat_thread_for_match` RPC (`MatchingRepository.ensureChatThreadForMatch`). Legacy threads may still use `participant_1_id` / `participant_2_id` and `match_request_id`.
- Canonical pet model: `lib/features/pet_profile/data/models/pet.dart` — `ActivityLevel`, `PetGender` (`gender`), `isPublic`, `isDiscoverable` (`is_discoverable`, default false); sectioned `EditProfileScreen` saves via `editPetProfile` / `EditProfileController`; discoverable toggle uses optimistic `PetListNotifier.setDiscoverable`; match GPS sync via `petMatchLocationProvider`.
- Marionette runs only in debug builds via conditional imports `marionette_debug_gate_stub.dart` / `marionette_debug_gate_io.dart` so `main.dart` avoids `dart:io` on web targets.
- Social screen header Messages navigates to `/matching`.
- PostGIS matching uses `swipes` / `matches` and `matching_discovery_candidates` RPC via `MatchingRepository`; canonical schema is in `supabase/migrations/` (root `schema.sql` is partial). RPC requires `is_discoverable IS TRUE` and non-null `pets.location`; `petHasLocation` uses `.not('location', 'is', null)` because geography is not returned in plain `select('location')`. `mutualMatchInsertStreamProvider` listens for Realtime `INSERT` on `public.matches`; `MatchCelebrationOverlay` on `MatchingScreen`.
- Matching discovery location: `lib/core/services/location_service.dart` with `LocationAccessState`, `locationAccessProvider`, and `deviceLatLngProvider`; Android `ACCESS_FINE/COARSE_LOCATION` and iOS `NSLocationWhenInUseUsageDescription` / `NSLocationAlwaysUsageDescription` in native manifests; `MatchingScreen` shows a denied/services-off empty state with **Enable Location Services** (app settings when permanently denied).
- `matchPreferenceControllerProvider` + `MatchPreferencesSheet` (Filters on `MatchingScreen`); `discoveryCandidatesControllerProvider` buffers candidates (replenish when stack drops below 5) and debounces preference refetches (~450ms via `ref.listen` + `invalidateSelf()` — do not `ref.watch` prefs in `build()` on slider drags). Riverpod 3: generated notifier subclasses omit type parameters (`extends _$Foo`, not `_$Foo<State>`); use `AsyncValue.value`, not `.valueOrNull`; prefs use `Notifier` / `NotifierProvider`.
