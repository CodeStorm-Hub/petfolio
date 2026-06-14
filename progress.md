# Petfolio — Progress Log

## 2026-06-15 — Phase 1: Matching Breeding + Playdate Modes (core) ✅

Full plan: `/home/syed/.claude/plans/read-the-whole-petfolio-product-specific-unified-lynx.md`
Phases: 1 Matching modes → 2 Health depth → 3 Social hashtags/DMs → 4 Commerce variants/Rx → 5 bKash/Nagad payments → 6 Security hardening.
DB migrations applied **directly to dev project** `jqyjvhwlcqcsuwcqgcwf` (user-approved; branch-first skipped to avoid paid add-on).

`flutter analyze` (full project) — **No issues found.** Matching tests pass.

Migration `phase1_matching_breeding_playdate_modes`:
- `swipes.mode` + `matches.mode` (text, default 'playdate'; existing 191 swipes / 37 matches backfilled). Unique indexes repointed to include `mode`. `private.swipes_after_insert_mutual_match()` now mode-aware.
- New tables (all RLS'd): `match_profiles`, `pet_pedigree`, `pet_health_certs`, `playdates`, `verifications`.
- `matching_discovery_candidates` RPC: new `p_mode` param + `gender` output; breeding mode gates on same-species/same-breed, opposite gender, active breeding `match_profiles`, verified non-expired vaccination cert.
- Private storage bucket `health-certs` (owner-scoped policy).

Dart:
- New: `lib/features/matching/data/models/match_mode.dart`, `match_profile.dart`.
- `MatchPreferencesState.mode` + persisted `setMode`.
- `mode` threaded through datasource → repo → discovery controllers + `discovery_controller.swipe`; added repo `fetchMatchProfile`/`saveMatchProfile`.
- UI: `_MatchModeToggle` (SegmentedButton) on `matching_screen.dart`.
- Incidental fix: `main.dart` `Supabase.initialize(... anonKey:)` (was `publishableKey:`, broke compile — dependency drift).

### Phase 1 — Breeding setup screen ✅ (this session)
- New models: `pet_pedigree.dart`, `pet_health_cert.dart` (HealthCertType enum).
- Datasource/repo: pedigree get/upsert, health-cert list/upload(→`health-certs` bucket)/insert/delete, `signedCertUrl`.
- `breeding_setup_controller.dart` (AsyncNotifier.family by petId): loads profile+pedigree+certs, `isReady` = active profile + verified non-expired vaccination cert.
- `breeding_setup_screen.dart`: listing toggle, pedigree form, cert upload (image_picker→compress), status banner. Route `/matching/breeding-setup`; "Breeding setup" CTA shows on `matching_screen` when breeding mode selected.
- analyze clean, matching tests pass. Breeding deck now fillable once a pet has active breeding profile + an admin-verified vaccination cert.

### Phase 1 — Playdate scheduler + Verification center ✅ (this session)
- Models: `playdate.dart` (PlaydateStatus), `verification.dart` (VerificationType/Status).
- Datasource/repo: fetch/propose/updateStatus playdates; fetch/request verifications.
- Playdate: `playdate_scheduler_sheet.dart` opened from chat header `AppHeaderAction` (only when `matchId != null`); date/time pickers + location chips → inserts `playdates` row + posts a "📅 Playdate proposed…" chat message via `chatConversationController.send`.
- Verification: `verification_controller.dart` + `verification_center_screen.dart`, route `/matching/verification`, reached via CTA in breeding setup. Owner requests phone/id/photo → inserts `verifications` (status pending; admin approval = Phase 6).

### Phase 1 — COMPLETE
analyze: only 1 spurious info lint (`main.dart` `anonKey` deprecation — package 2.12.4 has no `publishableKey`; was an outright error at session start, now compiles). Matching tests pass.

### Immediate next step
Phase 2: Health — medications/medication_logs, vaccinations, reminders, symptom checker, shareable summary, streak-freeze. Repos: `health_repository.dart`, `pet_care_repository.dart`.

---

## 2026-06-11 — Vet Hub Screen Revamp ✅

`flutter analyze` (full project) — **No issues found.**
