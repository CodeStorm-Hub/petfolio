# Handoff

## State
Executing approved 6-phase refactor plan (`/home/syed/.claude/plans/read-the-whole-petfolio-product-specific-unified-lynx.md`). DB migrations go **directly to dev project `jqyjvhwlcqcsuwcqgcwf`** (user-approved; branch-first skipped). **Phase 1 (Matching breeding/playdate) COMPLETE**: migration `phase1_matching_breeding_playdate_modes` applied; mode toggle + mode-aware discovery/swipes/matches; breeding setup (`breeding_setup_screen.dart`), playdate scheduler (`playdate_scheduler_sheet.dart` from chat header), verification center (`/matching/verification`). New models: match_mode, match_profile, pet_pedigree, pet_health_cert, playdate, verification. analyze clean except 1 spurious info; matching tests pass.

## Next
1. Phase 2 — Health depth: tables `medications`/`medication_logs`, `vaccinations`, generalized `reminders` (or extend `care_web_reminders`), streak-freeze on `care_streaks`; symptom checker (non-diagnostic), shareable health summary (PDF via `share_plus`). Repos: `lib/features/care/data/repositories/{health_repository,pet_care_repository}.dart`.
2. Then Phase 3 (Social hashtags/DMs), 4 (Commerce variants/Rx), 5 (bKash/Nagad), 6 (security hardening).

## Context
- `main.dart:101` `Supabase.initialize(... anonKey:)` shows a deprecation info lint, but supabase_flutter 2.12.4 has NO `publishableKey` param — leave anonKey, it's required. (Was a hard error at session start.)
- Riverpod 3 family: `extends AsyncNotifier<T>` + `Ctor(this.arg); final arg;` + `build()` (NOT `FamilyAsyncNotifier`). Copy `chat_conversation_controller.dart`.
- Theme: no typography tokens on `PetfolioThemeExtension` — use `textTheme`; accents are `success`/`warning`/`pillar*`/`*Soft`. `PetfolioEmptyState` requires `icon` or `lottieAsset`.
- Cert/verification approval is admin-side (Phase 6 RPC); owners insert pending rows only. Run `build_runner` after any @freezed change. Per-phase: update `progress.md` → prompt `/remember`. No inline comments.
