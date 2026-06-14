# Handoff

## State
Executing approved 6-phase refactor plan (`/home/syed/.claude/plans/read-the-whole-petfolio-product-specific-unified-lynx.md`). DB migrations go **directly to dev project `jqyjvhwlcqcsuwcqgcwf`** (user-approved; branch-first skipped). Phase 1 (Matching breeding/playdate) mostly done: migration `phase1_matching_breeding_playdate_modes` applied; mode threaded end-to-end + `_MatchModeToggle`; **breeding setup screen done** (`breeding_setup_screen.dart` + `breeding_setup_controller.dart`, route `/matching/breeding-setup`, models `pet_pedigree.dart`/`pet_health_cert.dart`). `flutter analyze` clean, matching tests pass.

## Next
1. Phase 1 finish: playdate scheduler from `chat_screen.dart` → `playdates` table (reuse `flutter_map`); verification center screen → `verifications` table.
2. Phase 2: Health meds/vaccines/reminders/summaries.

## Context
- Breeding deck stays empty for a pet until it has active breeding `match_profiles` row + admin-verified non-expired vaccination `pet_health_certs`. Owners upload certs but cannot set `verified` (RLS: insert/delete only) — admin verify RPC is Phase 6.
- Riverpod 3 family pattern here: `extends AsyncNotifier<T>` + `Ctor(this.arg); final arg;` + `build()` (NOT `FamilyAsyncNotifier`). Copy `chat_conversation_controller.dart`.
- Theme: no typography tokens on `PetfolioThemeExtension` — use `textTheme`; accents are `success`/`warning`/`pillar*`/`*Soft` (no bare `mint`/`sunny`). `PetfolioEmptyState` requires `icon` or `lottieAsset`.
- Per-phase cadence: update `progress.md` → prompt `/remember`. No inline comments/dartdocs.
