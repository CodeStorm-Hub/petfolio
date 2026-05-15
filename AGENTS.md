## Learned User Preferences

- When applying Supabase schema to the hosted project, prefer the Supabase MCP migration path when available; if using the Supabase CLI, prefix commands with `npx` (for example `npx supabase db push`).
- After completing a distinct care or backend phase, keep `progress.md` updated and use `/remember` to persist high-signal context before starting the next phase.
- Avoid importing `router.dart` from screens that `router.dart` already imports; use literal paths or query strings for deep links to prevent circular imports.
- For optimistic UI on task toggles, revert local state and surface failures with `AppSnackBar.showError` when the repository call fails.
- When a subagent result is already visible in the UI, avoid re-summarizing it unless multi-task synthesis is needed; a short third-person completion note is enough, and avoid repeating the same confirmation every turn.
- When asked to save audits, reviews, or comparable findings, write them as Markdown under the repository root unless a different path is specified.

## Learned Workspace Facts

- Care shell route is `/care`; full-screen care routes include `/care/nutrition` and `/care/medical-vault`.
- Successful pet onboarding navigates to `/care?onboardingComplete=1`; `CareScreen` shows a one-shot success snackbar then normalizes the URL to `/care`.
- `careDashboardProvider` and `healthVaultControllerProvider` are non-family providers that watch `activePetIdProvider`; a null active pet yields empty tasks or an empty medical list and skips remote loads.
- Daily streak completion is driven by the `check_daily_completion` RPC (`target_pet_id`, optional `completion_date` matching `care_logs.logged_date`) against `care_tasks` and `care_logs`, with streak state in `care_streaks` and badges in `pet_badges`; the dashboard also listens to Supabase realtime on `care_streaks` via `careStreakRealtimeProvider` for immediate streak UI sync.
- App-wide snackbars for notifier-triggered errors use `appSnackBarMessengerKey` on `MaterialApp.router` and `AppSnackBar.showError` from `lib/core/widgets/app_snack_bar.dart`.
- `MedicalRecord` exposes `renewalDate` and `isExpiringSoon` (next 30 days, date-only) for vault warning styling.
- `analysis_options.yaml` excludes `*.g.dart` and `*.freezed.dart` from the analyzer to avoid duplicate generated JSON symbol noise.
- `chat_threads` uses `participant_1_id` / `participant_2_id` (user ids) and `match_request_id`; the app maps rows after filtering by auth user and `match_requests` pet involvement (`chat_thread.dart`, `chat_threads_controller.dart`).
- Canonical pet records use `lib/features/pet_profile/data/models/pet.dart` (`ActivityLevel` maps to snake_case `activity_level` strings such as `very_high`; nutrition maps use `activityLevelSnakeCase`).
- Marionette runs only in debug builds via conditional imports `marionette_debug_gate_stub.dart` / `marionette_debug_gate_io.dart` so `main.dart` avoids `dart:io` on web targets.
- Social screen header Messages navigates to `/matching`.
- `.gitignore` excludes `.cursor/hooks/state/`, `tmp_window_dump.xml`, and `.claude/worktrees/`.
