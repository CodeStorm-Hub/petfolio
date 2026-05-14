## Learned User Preferences

- When applying Supabase schema to the hosted project, prefer the Supabase MCP migration path when available; if using the Supabase CLI, prefix commands with `npx` (for example `npx supabase db push`).
- After completing a distinct care or backend phase, keep `progress.md` updated and use `/remember` to persist high-signal context before starting the next phase.
- Avoid importing `router.dart` from screens that `router.dart` already imports; use literal paths or query strings for deep links to prevent circular imports.
- For optimistic UI on task toggles, revert local state and surface failures with `AppSnackBar.showError` when the repository call fails.
- When a subagent result is already visible in the UI, avoid re-summarizing it unless multi-task synthesis is needed; a short third-person completion note is enough, and avoid repeating the same confirmation every turn.

## Learned Workspace Facts

- Care shell route is `/care`; full-screen care routes include `/care/nutrition` and `/care/medical-vault`.
- Successful pet onboarding navigates to `/care?onboardingComplete=1`; `CareScreen` shows a one-shot success snackbar then normalizes the URL to `/care`.
- `careDashboardProvider` and `healthVaultControllerProvider` are non-family providers that watch `activePetIdProvider`; a null active pet yields empty tasks or an empty medical list and skips remote loads.
- Daily streak completion is driven by the `check_daily_completion` RPC (`target_pet_id`, optional `completion_date` matching `care_logs.logged_date`) against `care_tasks` and `care_logs`, with streak state in `care_streaks` and badges in `pet_badges`; the dashboard also listens to Supabase realtime on `care_streaks` via `careStreakRealtimeProvider` for immediate streak UI sync.
- App-wide snackbars for notifier-triggered errors use `appSnackBarMessengerKey` on `MaterialApp.router` and `AppSnackBar.showError` from `lib/core/widgets/app_snack_bar.dart`.
- `MedicalRecord` exposes `renewalDate` and `isExpiringSoon` (next 30 days, date-only) for vault warning styling.
- `analysis_options.yaml` excludes `*.g.dart` and `*.freezed.dart` from the analyzer to avoid duplicate generated JSON symbol noise.
- Matching chat models and controllers still assume `chat_threads.pet_id_1` / `pet_id_2` while the live database uses user participant columns, so chat remains incompatible until schemas and queries align.
- `pubspec.yaml` lists `riverpod_annotation` and `riverpod_generator`, but `lib/` does not use `@riverpod` generated providers; state is hand-written `Provider` / `NotifierProvider` / `StreamNotifierProvider` style.
