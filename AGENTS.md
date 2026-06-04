## Role & Architecture Rules

You are an expert Flutter and Supabase developer. For the PetFolio project, you must strictly adhere to the following rules:

1. **Feature-First Architecture**: All code must live within `lib/features/<feature_name>/` and be cleanly divided into presentation, domain, and data layers.
2. **State Management**: Use Riverpod (`flutter_riverpod`, `riverpod_annotation`, generated notifiers) for all state management and dependency injection. Do not introduce the `provider` package for new code.
3. **Supabase Performance**:
   - Avoid client-side data joining (N+1 queries). Push complex relational logic and aggregations to Postgres Views or RPCs.
   - When writing Row Level Security (RLS) policies, always wrap authentication checks in a subselect, such as `(select auth.uid())`, to force the Postgres optimizer to cache the result and prevent severe performance degradation.
   - Never generate queries that could result in full table scans; always utilize appropriate indexing.

## Learned User Preferences

- When applying Supabase schema to the hosted project, prefer the Supabase MCP migration path when available; if using the Supabase CLI, prefix commands with `npx` (for example `npx supabase db push`).
- After completing a distinct care, marketplace, backend, or PWA/web phase, keep `progress.md` updated and use `/remember` to persist high-signal context before starting the next phase.
- Web/PWA work follows phased rollout in `PWA_WEB_AUDIT.md`; do not change Android APK behavior—gate web-only paths with `kIsWeb` and `lib/core/platform/`.
- Avoid importing `router.dart` from screens that `router.dart` already imports; use literal paths or query strings for deep links to prevent circular imports.
- For optimistic UI and one-off actions (care task toggles, Stripe seller onboarding), surface failures with `AppSnackBar.showError`; do not set long-lived providers (e.g. `myShopProvider`) to `AsyncValue.error` for transient failures.
- When a subagent result is already visible in the UI, avoid re-summarizing it unless multi-task synthesis is needed; a short third-person completion note is enough, and avoid repeating the same confirmation every turn.
- When asked to save audits, reviews, or comparable findings, write them as Markdown under the repository root unless a different path is specified.

## Learned Workspace Facts

- Care routes: shell `/care`, full-screen `/care/nutrition` and `/care/medical-vault`; successful onboarding navigates to `/care?onboardingComplete=1`, shows a one-shot success snackbar, then normalizes the URL to `/care`.
- `careDashboardProvider` and `healthVaultControllerProvider` are non-family providers that watch `activePetIdProvider`; a null active pet yields empty tasks or an empty medical list and skips remote loads.
- Daily streak completion is driven by the `check_daily_completion` RPC (`target_pet_id`, optional `completion_date` matching `care_logs.logged_date`) against `care_tasks` and `care_logs`, with streak state in `care_streaks` and badges in `pet_badges`; the dashboard also listens to Supabase realtime on `care_streaks` via `careStreakRealtimeProvider` for immediate streak UI sync.
- App-wide snackbars for notifier-triggered errors use `appSnackBarMessengerKey` on `MaterialApp.router` and `AppSnackBar.showError` from `lib/core/widgets/app_snack_bar.dart`.
- `analysis_options.yaml` excludes only `*.g.dart` from the analyzer (not `*.freezed.dart`; Freezed `part` files must be analyzed).
- Canonical pet model: `lib/features/pet_profile/data/models/pet.dart` — `ActivityLevel`, `PetGender` (`gender`), `isPublic`, `isDiscoverable` (`is_discoverable`, default false); sectioned `EditProfileScreen` saves via `editPetProfile` / `EditProfileController`; discoverable toggle uses optimistic `PetListNotifier.setDiscoverable`; match GPS sync via `petMatchLocationProvider`.
- Marionette runs only in debug builds via conditional imports `marionette_debug_gate_stub.dart` / `marionette_debug_gate_io.dart` so `main.dart` avoids `dart:io` on web targets.
- Social screen header Messages navigates to `/matching`.
- PostGIS matching: `/matching/inbox`, `/matching/chat/:threadId`; `swipes`/`matches` and `matching_discovery_candidates` RPC (`MatchingRepository`); `chat_threads.mutual_match_id` + `ensure_chat_thread_for_match` (legacy `participant_*`/`match_request_id` possible). RPC needs `is_discoverable IS TRUE` and non-null `pets.location`; `petHasLocation` uses `.not('location', 'is', null)`. `mutualMatchInsertStreamProvider` + `MatchCelebrationOverlay`; `matchPreferenceControllerProvider` + `discoveryCandidatesControllerProvider` (replenish when stack drops below 5, ~450ms debounced `invalidateSelf()` — do not `ref.watch` prefs in `build()` on slider drags). Location: `location_service.dart`; denied/services-off empty state on `MatchingScreen`. Riverpod 3: generated notifiers omit type params (`extends _$Foo`); use `AsyncValue.value`, not `.valueOrNull`.
- Multi-vendor marketplace (`docs/claude-handoff.md`): cart `itemsByShop` + per-shop `startCheckoutForShop`; **Discover Shops** via `shopListProvider` → `/shop/:id`; seller routes `/seller`, `/seller/setup`, `/seller/onboarding`, products/orders. `ShopRepository.startOnboarding` calls Edge Function `stripe-onboard-vendor` with `functions.invoke(..., body: {'shopId'})` (not `.rpc()`), reads `accountLinkUrl`; platform Stripe account needs **Connect** enabled.
- PWA/web (`PWA_WEB_AUDIT.md`, Vercel deploy): Phases 1–2 done—`web/index.html` shell fixes; `lib/core/platform/` (`PlatformNotifications` IO local vs web `care_web_reminders`, `useStripeHostedCheckout` + hosted `create-payment-intent` session on web, `pickGalleryImage`, web push via `WEB_PUSH_VAPID_PUBLIC_KEY` + `register-web-push-subscription` + `web/push_register.js`). Matching on web uses pet profile location (`petMatchLocationProvider`), not device GPS.
