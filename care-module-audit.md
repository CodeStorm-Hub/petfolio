# Care Module Audit — Petfolio
> Branch: `accessibility-fix-salman-2` · Date: 2026-06-27

## Table of Contents
1. [Module Overview](#1-module-overview)
2. [Feature Coverage Gaps](#2-feature-coverage-gaps)
3. [UI/UX Issues by Screen](#3-uiux-issues-by-screen)
4. [Accessibility Deficiencies](#4-accessibility-deficiencies)
5. [Architecture & Code Quality](#5-architecture--code-quality)
6. [State Management](#6-state-management)
7. [Data & Repository Layer](#7-data--repository-layer)
8. [Gamification System](#8-gamification-system)
9. [AI Routine System](#9-ai-routine-system)
10. [Performance Concerns](#10-performance-concerns)
11. [Prioritised Fix List](#11-prioritised-fix-list)

---

## 1. Module Overview

The care module spans 6 screens, 10 widgets, 9 controllers/providers, 4 repositories, and 8 data models. It covers daily task scheduling, gamification (XP/levels/badges/streaks), AI-generated routines, medical vault, medication adherence, weight tracking, symptom logging, and GPS walk tracking.

### Feature Map

| Feature | Screen | Controller | Repository | Status |
|---|---|---|---|---|
| Daily task dashboard | `care_screen.dart` | `CareDashboard` | `PetCareRepository` | Complete |
| Medical vault | `medical_vault_screen.dart` | `HealthVaultController` | `MedicalVaultRepository` | Complete |
| Medication adherence | `medications_screen.dart` | `MedicationsController` | `MedicationLogRepository` | Complete |
| Weight/nutrition | `nutrition_screen.dart` | `NutritionNotifier` | `VitalsRepository` | Partial |
| Symptom checker | `symptom_checker_screen.dart` | — | `HealthRepository` | Partial |
| Walk tracking | `walk_tracking_screen.dart` | — | — | **Not routed** |
| AI routine | `routine_recommendation_sheet.dart` | `AiRoutineNotifier` | `CareRecommendationRepository` | Complete |
| Gamification | `gamified_care_ui.dart` | `PetAwardsSummary` | — | Complete |

---

## 2. Feature Coverage Gaps

### P0 — Walk Tracking Route Is Dead

`walk_tracking_screen.dart` exists and is implemented (GPS + flutter_map) but **has no route registered in `care_routes.dart`**. The `CareExploreRow` banner in `care_banners.dart` presumably links to it, but navigation will fail at runtime.

**Fix:** Add `/care/walk` route to `care_routes.dart`.

```dart
GoRoute(
  path: '/care/walk',
  pageBuilder: (context, state) =>
      pfSharedAxisPage(state, const WalkTrackingScreen()),
),
```

### P0 — Medical Vault Has No Route Entry

`MedicalVaultScreen` is exported from `index.dart` but no GoRoute exists in `care_routes.dart`. The screen can only be reached if some other feature hard-codes a navigation push — unacceptable for a deep-linkable screen.

**Fix:** Register `/care/medical-vault` route.

### P1 — Nutrition Screen Route Missing

`NutritionScreen` is exported from `index.dart` but no GoRoute in `care_routes.dart`. Same issue as medical vault.

**Fix:** Register `/care/nutrition` route.

### P1 — Symptom Checker Not Surfaced in Care Dashboard

`/care/symptoms` is routed but there's no entry point visible from the main care screen. Users must know the route exists. There is no button, banner, or shortcut in `care_screen.dart`.

**Fix:** Add a "Log Symptom" shortcut in `CareExploreRow` or as a FAB option menu.

### P2 — Medications Not Accessible From Care Screen

The care dashboard has tasks of type `medication`, but tapping them does not navigate to the dedicated `MedicationsScreen` (adherence view). Users who want to log a dose must know to navigate to the separate medications screen.

**Fix:** Add a "View Medications" tile in `CareExploreRow` or navigate to `MedicationsScreen` when the user taps a medication-type task and it already has a medical record associated.

### P2 — No Direct Weight Log From Nutrition Task

Completing a `feeding`/nutrition task does not offer weight logging. The weight log is entirely separate and invisible from the daily task flow.

---

## 3. UI/UX Issues by Screen

### 3.1 `care_screen.dart` — Main Dashboard

| # | Issue | Severity |
|---|---|---|
| 1 | Filter chip state is reset on every route change (no persistence, not even session-scoped) | Medium |
| 2 | DatePicker range: 7 days back only — cannot view tasks older than a week without a workaround | Medium |
| 3 | AI banner is always visible even after generating a routine; should hide or change label to "Regenerate" | Medium |
| 4 | FAB is always visible even when filtered view is empty, with no contextual message about what the FAB does | Low |
| 5 | "No tasks" empty state only shows text; no illustration or CTA to add first task | Low |
| 6 | `CareExploreRow` renders "Communities" tile whose destination may not be implemented | High |
| 7 | Onboarding snackbar shown on every cold launch if extra param persists in GoRouter state | Medium |

**Detail — Issue 2:** Users with chronic pets need to review or back-fill tasks for dates more than a week ago (vet visits, medication tracking). The 14-day window (7 back, 6 forward) is hardcoded. There is no date range picker to jump to an arbitrary date.

**Recommendation:** Extend to 30 days back minimum or add a calendar jump button beside the date strip.

**Detail — Issue 6:** `CareExploreRow` has a "Communities" tile. If the social/communities feature is incomplete or the route does not exist, this is a P0 crash risk. Verify before release.

---

### 3.2 `medical_vault_screen.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Records are split into three sections (Vaccines, Medications, Vet Visits) but the sort is by date — not alphabetical within section | Low |
| 2 | Signed URL for document download expires in 1 hour; no re-generation on tap if URL expired | Medium |
| 3 | `deactivateRecord` is labelled "Delete" in code comments but is a soft-delete; UI wording may confuse users who expect hard delete | Low |
| 4 | No search/filter for medical records — with many records the list becomes hard to scan | Medium |
| 5 | No confirmation dialog before deactivating a record | High |
| 6 | Expiry warning badge (isExpiringSoon) exists in model but unclear if displayed in list tiles | Medium |
| 7 | No bulk-select for records (e.g. bulk deactivate old vaccines) | Low |
| 8 | Document upload uses storage path (not URL) but the URL is not generated until user taps — creates a loading moment that is not indicated | Low |

**Recommendation for Issue 5:** Show a confirmation `AlertDialog` ("Remove this record? It will be hidden from your Medical Vault.") before calling `deactivateRecord`. Hard-delete option should be a separate action (edit → delete permanently).

---

### 3.3 `medications_screen.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | 30-minute double-dose window is hardcoded and not configurable per-medication | Medium |
| 2 | No feedback when a dose is blocked (double-dose prevention throws `ValidationException`); the snackbar copy is not confirmed | Medium |
| 3 | Medication card shows "doses given today" but does not show prescribed doses per day (e.g. "1 of 2 doses") | High |
| 4 | No missed-dose indicator — if a medication was due at 8 AM and not given by noon, no visual alert | High |
| 5 | Past dose log is not shown per medication (only today's count) — users cannot verify yesterday's adherence | Medium |

**Detail — Issue 3:** The `MedicalRecord` model has a `frequency` field (e.g. "twice daily") and `dosage`. The `MedicationAdherence` state has `dosesToday` but not a `targetDoses` computed from frequency. Without this, "1 dose given" is meaningless — is the target 1 or 3?

---

### 3.4 `nutrition_screen.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Calorie estimate is based on weight + activity level but formula/source is not disclosed | Low |
| 2 | Weight history limited to last 90 entries with no load-more | Low |
3 | No unit toggle (kg ↔ lbs) — problematic for users in US/UK contexts | High |
| 4 | Weight trend card likely shows percentage change but no reference to ideal weight range for the breed | Medium |
| 5 | No goal weight feature — users cannot set a target and see progress toward it | Low |

---

### 3.5 `symptom_checker_screen.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Multi-step wizard has no progress indicator (no step X of Y) | Medium |
| 2 | Emergency detection is binary (critical vs not); "moderate" severity with multiple symptoms could also warrant vet contact | Medium |
| 3 | Symptom list is static/hardcoded — no ability to describe a custom symptom | High |
| 4 | After logging, user is returned to same screen with no confirmation summary | Low |
| 5 | No integration with health log history (cannot see previously logged symptoms from this screen) | Medium |

---

### 3.6 `walk_tracking_screen.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | **Unreachable** — no route registered | P0 |
| 2 | Walk logs are not stored persistently (no repository, no Supabase insert) | High |
| 3 | No history of past walks (distance, duration, route map) | High |
| 4 | Background location tracking not implemented — app must stay foregrounded during walk | Medium |
| 5 | No pause/resume — only start/stop | Low |

---

### 3.7 `care_task_form_sheet.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Auto-title generation: if user edits title then changes task type, title is NOT reset (tracked flag). But the flag is per-session, so editing an existing task and switching type may unexpectedly overwrite a custom title | Medium |
| 2 | Time picker: `parseCareScheduledTimeOfDay` clamps invalid ranges silently — user gets wrong time with no error message | Low |
| 3 | No validation on title length — empty title can be submitted | High |
| 4 | No way to add/edit notes from the form sheet (notes field exists in model but may not be in form) | Medium |
| 5 | Frequency `asNeeded` has no UX explanation — new users won't know what it means | Low |

---

### 3.8 `care_coverflow_carousel.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Coverflow effect may be visually jarring on smaller screens; no fallback for accessibility preference `reduceMotion` | Medium |
| 2 | Edit/delete on tap — no long-press fallback; two-finger users or those with motor impairments may struggle | Medium |
| 3 | Sublabel "Activity log" for synthetic log-derived tasks gives no context to new users | Low |

---

### 3.9 `vitals_chart_widget.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Chart has no Y-axis baseline reference (healthy weight range for breed) | Medium |
| 2 | Tap to add log is non-discoverable — no affordance visible until user knows to tap | Low |
| 3 | No zoom/pan for dense date ranges | Low |

---

### 3.10 `gamified_care_ui.dart` — Header

| # | Issue | Severity |
|---|---|---|
| 1 | XP progress bar has no text label for current/target XP (purely visual) | Medium |
| 2 | Badge grid displays unlocked badges but no tooltip/label on tap | Medium |
| 3 | "Freeze streak" affordance visibility — freeze count visible but the action button may not be prominent enough | Medium |
| 4 | Level-up confetti fires on every cold load if level was gained while app was closed | High |
| 5 | Pet avatar not tappable — missed opportunity to navigate to pet profile | Low |

**Detail — Issue 4:** `_applyBadgeDelta` batches badges on first load, but there is no equivalent logic for level-up celebrations. If the XP threshold was crossed while offline, confetti fires every time the dashboard loads until state is cleared. Needs a "has_seen_levelup" persistence flag (SharedPreferences or DB).

---

### 3.11 `routine_recommendation_sheet.dart`

| # | Issue | Severity |
|---|---|---|
| 1 | Duplicates are grayed out but still shown — advanced users are confused by why they cannot select them | Low |
| 2 | No explanation of AI's reasoning for each suggestion | Low |
| 3 | No way to edit a suggestion before adding (e.g. change frequency from daily to weekly) | Medium |
| 4 | Confirmation dialog only appears if sheet is dismissed with selected items — easy to miss if user just navigates back | Medium |
| 5 | "Select All" includes non-duplicate tasks only, but button label does not say "Select All New" | Low |

---

## 4. Accessibility Deficiencies

### 4.1 Missing Semantic Labels

| Widget | Element | Issue |
|---|---|---|
| `gamified_care_ui.dart` | XP progress bar | No `Semantics(label: 'XP progress, 340 of 500')` |
| `gamified_care_ui.dart` | Badge icons | No semantic label for each badge emoji/icon |
| `gamified_care_ui.dart` | Level-up confetti | Animation has no `liveRegion` announcement |
| `care_task_card.dart` | XP burst animation | No announcement when XP gained |
| `care_task_card.dart` | Completion checkbox | Checkbox role may not be surfaced correctly if using `InkWell` + custom icon |
| `care_coverflow_carousel.dart` | Swipe gesture | No `Semantics` on swipe area; screen readers cannot navigate carousel |
| `care_date_picker.dart` | Date chips | No `Semantics(selected: true/false)` for active date |
| `vitals_chart_widget.dart` | fl_chart | Chart is entirely visual; no data table alternative for screen readers |
| `routine_recommendation_sheet.dart` | Duplicate badge | Duplicate indicator has no spoken label |

### 4.2 Focus Management

- After `CareTaskFormSheet` is dismissed (bottom sheet close), focus returns to the triggering FAB — but only if `FocusScope.of(context).requestFocus()` is explicitly called, which is not confirmed in the widget.
- After completing a task and seeing the XP snackbar, focus is not managed back to the task list.
- The AI routine sheet (`routine_recommendation_sheet.dart`) — on open, focus should move to the sheet header; on close with selected tasks, focus should announce "X tasks added".

### 4.3 Touch Target Size

- Date picker chips are 52px wide × unknown height. WCAG 2.5.5 requires 44×44px minimum. If height is under 44px this is a failure.
- Filter chips in `care_screen.dart` may have insufficient padding.
- Streak freeze button — if rendered as a small icon, touch target is likely under 44px.

### 4.4 Color & Contrast

- Task type color coding is the only differentiator between task categories (no icon shape difference). This fails WCAG 1.4.1 (use of color alone).
- XP progress bar — ensure bar color + background meets 3:1 contrast ratio.
- Gamification header gradient + white text — verify contrast on mid-gradient position.
- Severity badges in `medical_vault_screen.dart` use color alone (red = expired, yellow = expiring soon).

### 4.5 Motion / Reduce Motion

- Coverflow animation in `care_coverflow_carousel.dart` has no check for `MediaQuery.disableAnimations`.
- Rotating coin icon and pulsing glow in `gamified_care_ui.dart` — these are decorative but users with vestibular disorders may be affected.
- Level-up confetti — no opt-out.

**Fix pattern for all motion issues:**
```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
if (!reduceMotion) { /* animate */ }
```

---

## 5. Architecture & Code Quality

### 5.1 Route Registration Missing — Architectural Gap

Three screens (`WalkTrackingScreen`, `MedicalVaultScreen`, `NutritionScreen`) are implemented but not registered in `care_routes.dart`. This is not a discovery issue — the `index.dart` exports them, implying they are meant to be reachable. The routes must be added.

### 5.2 Duplicated Weight Log Logic

Both `VitalsRepository` (for `VitalsNotifier`) and `HealthRepository.fetchWeightHistory()` fetch weight data independently. Two separate repositories → two separate state providers → potential inconsistency if one updates and the other doesn't.

**Recommendation:** Route all weight log operations through `VitalsRepository` only. Remove `fetchWeightHistory` from `HealthRepository` or delegate it to `VitalsRepository`. `NutritionNotifier` and `VitalsNotifier` can share a single repository.

### 5.3 `WeightLog` Not Freezed

All other models are Freezed (`CareTask`, `HealthLog`, `MedicalRecord`, etc.) but `WeightLog` is a plain class with hand-written `fromJson`/`copyWith`. This is inconsistent and means no `==`/`hashCode` equivalence, making list diffing unreliable.

**Fix:** Migrate `WeightLog` to Freezed + `@JsonSerializable`.

### 5.4 `VitalsRepository` Missing Error Wrapping

`HealthRepository` and `MedicalVaultRepository` wrap `PostgrestException` into `DatabaseException`/`NetworkException`. `VitalsRepository` does not — raw `PostgrestException` bubbles to the controller, breaking the error abstraction layer.

**Fix:** Add try-catch in `VitalsRepository` matching the pattern in `HealthRepository`.

### 5.5 `care_recommendation_service.dart` — Fragile JSON Extraction

The service extracts JSON from the LLM response using string manipulation and a regex to find the `[...]` array. If the model returns unexpected structure (e.g. nested object, markdown table), parsing silently fails or returns empty suggestions with no user feedback.

**Fix:** Enforce JSON mode on the edge function side if supported by the model. Alternatively, catch parse exceptions and surface them as `CareRecommendationException(isConfigError: false)` with a retry prompt.

### 5.6 `_normalizeTime` Does Not Handle 12-Hour Format

`CareRecommendationService._normalizeTime()` parses `HH:MM` only. If the LLM returns `"8:00 AM"` or `"08:00:00 AM"` the function returns `null`, silently dropping the scheduled time.

**Fix:** Add 12-hour AM/PM parsing:
```dart
// Parse "8:00 AM", "2:30 PM" etc before HH:MM split
```

### 5.7 `aiRoutineProvider` Uses Manual `NotifierProvider` Not Generator

`AiRoutineNotifier` is declared with `NotifierProvider<AiRoutineNotifier, AiRoutineState>` (manual), while all other controllers use `@Riverpod` generator annotations. This inconsistency means it won't appear in the generated dependency graph and skips lint rules.

**Fix:** Migrate to `@Riverpod class AiRoutineNotifier extends _$AiRoutineNotifier`.

### 5.8 `CareDashboard` `keepAlive: true` Without Lifecycle Guards

`CareDashboard` is kept alive across route changes. If the user switches pets rapidly (e.g. they have 3 pets), old dashboard states remain in memory. The controller handles pet changes via `activePetIdProvider` watch but does not `dispose` the old snapshot data.

**Recommendation:** Add a maximum of 2 kept-alive instances or use `ref.keepAlive()` with manual release on app lifecycle pause.

### 5.9 Hardcoded Pagination Limits

| Location | Limit | Issue |
|---|---|---|
| `healthRepositoryProvider.fetchLogsForPet` | 100 | No load-more |
| `medicalVaultRepository.fetchRecordsForPet` | 100 | No load-more |
| `vitalsRepository.fetchWeightLogs` | 30 default | Inconsistent with `NutritionNotifier`'s 90 |
| `careRecommendationRepository.fetchExistingTasks` | 50 | Could miss tasks for prolific users |

**Fix:** Implement cursor-based or offset pagination for health logs and medical records.

---

## 6. State Management

### 6.1 `vitalsNotifierProvider` vs `nutritionProvider` — Redundant Providers

Both `VitalsNotifier` and `NutritionNotifier` manage `WeightLog` lists for the active pet. They use different repositories (`VitalsRepository` vs direct Supabase calls in `HealthRepository`) and different limits (30 vs 90). Having two providers for the same data risks stale state.

**Recommendation:** Consolidate into a single `weightLogProvider` used by both the chart and the vitals list.

### 6.2 No Pessimistic Path for Streak Toggle

`useFreeze()` in `CareDashboard` calls the repo and updates state only if the call succeeds — which is correct. But the UI may show the freeze button as tappable again immediately after success (if state is not reset in the same frame). Verify the freeze count is decremented in `CareStreak` state before the user can tap again.

### 6.3 `petAwardsSummaryProvider` Auto-dispose Race

After `toggleTaskCompletion` unlocks a badge, the controller calls `ref.invalidate(petAwardsSummaryProvider(petId))`. If the gamified header is not currently visible (e.g. scrolled out of view), the `FutureProvider.autoDispose.family` may already be disposed — the invalidation does nothing. When the header scrolls back into view, it re-fetches, which is correct, but the snackbar has already fired. No race condition, but worth documenting.

---

## 7. Data & Repository Layer

### 7.1 Double-Dose Window Not Per-Medication

`MedicationLogRepository.logDose()` blocks doses logged within 30 minutes (hardcoded). Some medications are given every 4 hours; the 30-minute lock is fine. Others are monthly injections — the window should be much longer. The `MedicalRecord` has a `frequency` field that could drive this logic.

**Recommendation:** Calculate the minimum safe re-dose window from `frequency` (`monthly` → 28-day lock, `daily` → 4-hour lock, `twice_daily` → 2-hour lock, etc.) and pass it to `logDose()`.

### 7.2 `uploadDocument` Returns Storage Path, Not URL

`MedicalVaultRepository.uploadDocument()` returns the Supabase storage path. The caller must separately call `createDocumentUrl()` to get a usable signed URL. This two-step pattern is not documented in the method signature (no comment, no return type hint). A developer reading the code will assume they have a URL, not a path.

**Fix:** Either rename the method to `uploadDocumentGetPath` or make it return a `({String path, String signedUrl})` record directly.

### 7.3 Bulk Create Race Condition

`bulkCreateTasks()` fetches existing tasks, filters duplicates client-side, then upserts with `ignoreDuplicates: true`. Two concurrent calls from different devices could both pass the client-side dedup and both reach the DB — the DB unique index is the final guard. This is noted in a comment but the exception thrown by the unique index constraint is not caught specifically — it will surface as a `DatabaseException` rather than a user-friendly "task already exists" message.

### 7.4 `_fmtYmd` Uses Local Date for RPC Params

`_fmtYmd(DateTime)` formats dates as `YYYY-MM-DD` using local time. The RPC `get_care_dashboard_snapshot` receives `p_client_today` which must match the user's local date. This is correct and intentional. However, `p_occurred_at` in `toggleCompletion` is sent as UTC (`DateTime.now().toUtc().toIso8601String()`). This inconsistency (some params local, some UTC) is a latent bug risk — any future developer adding a date param may not know which convention to follow.

**Recommendation:** Add a clear comment at the top of `pet_care_repository.dart` documenting the date convention: `// p_selected_date, p_week_start, p_week_end, p_client_today: YYYY-MM-DD local. p_occurred_at: ISO 8601 UTC.`

---

## 8. Gamification System

### 8.1 Level-Up Confetti Bug

There is no "has seen level-up" flag. If the app is closed mid-animation or between sessions, the confetti will replay. The `_applyBadgeDelta()` method tracks badge baseline but there is no equivalent for level thresholds.

**Fix:** Store `last_seen_level` in SharedPreferences. Compare `PetLevel.fromXp(totalXp).level` to `last_seen_level` on each dashboard load. Only trigger confetti if level increased. Update stored value immediately on first fire.

### 8.2 Streak Freeze UX Not Prominent

`freezesAvailable` defaults to 2 and is rendered in `CareGamifiedHeader`. But if a user misses a day, will they know they have freezes? The freeze mechanic is likely too buried in the header. Most users will lose their streak without knowing freezes exist.

**Recommendation:** When a user loads the care dashboard and their last completion date was yesterday-or-earlier (i.e. streak at risk), show a bottom sheet or prominent banner: "Your streak is at risk! You have 2 freezes available. Use one to protect it."

### 8.3 XP Points Not Shown on Task Cards

`CareTaskCard` shows an XP burst animation on completion but the task card itself does not show how many points the task is worth before completing it. This reduces the motivational pull of the gamification system.

**Fix:** Show `+${task.gamificationPoints} XP` in a small chip or trailing label on each task card.

### 8.4 Badge Descriptions Not Shown at Unlock

When a badge is unlocked, the snackbar shows the badge name but not the description from `BadgeInfo`. Missing the "why" reduces the sense of achievement.

**Fix:** Include `BadgeInfo.description` in the badge unlock snackbar body.

### 8.5 No XP History or Leaderboard Hooks

Currently XP is only used for local level calculation. There's no way for users to compare progress with others or see what contributed to their XP. This limits long-term engagement.

---

## 9. AI Routine System

### 9.1 Silent Failure on Empty Suggestions

If the AI returns 0 parseable tasks (empty array or malformed JSON), `generateRecommendations()` returns an empty list and `AiRoutineNotifier` moves to `success` state with 0 suggestions. The sheet then opens showing "No suggestions". Users see no indication of whether this is intentional, an API error, or a misconfiguration.

**Fix:** Treat 0 suggestions as a soft error: set state to `error` with message "No suggestions generated. Try again or add tasks manually."

### 9.2 24-Hour Cache Not Invalidated on Pet Data Changes

The AI cache (`isCacheValid`) is time-based (24 hours) and pet-scoped. If the user adds a medical record or health log that should influence recommendations, the cache remains stale for up to 24 hours. `invalidateCache()` is public but never called from `HealthVaultController` or `HealthRepository` after creating records.

**Fix:** Call `ref.read(aiRoutineProvider.notifier).invalidateCache()` from `HealthVaultController.addRecord()` and `HealthRepository.createLog()`.

### 9.3 AI Suggestion Editing Before Adding

Users cannot adjust a suggested task's frequency or time before adding it. If the AI suggests "daily bath" but the user wants "weekly bath", they must add it and then edit it — two extra taps.

**Recommendation:** Long-tap an AI suggestion to inline-edit before saving.

### 9.4 `_similarity()` Algorithm Is O(n²)

The fuzzy match in `_isDuplicate()` uses a character-level coverage loop that is O(n²) in title length. For a user with 50 tasks and an AI suggesting 8 tasks, this runs 50 × 8 = 400 pairs × O(n²) char comparisons. At typical title lengths this is fast enough, but a note is warranted.

---

## 10. Performance Concerns

### 10.1 `CareDashboard` `keepAlive: true` Memory Footprint

`keepAlive: true` means all snapshot data (tasks, logs, badges, streak) stays in memory even when the user navigates away. For users with many tasks and a long session, this accumulates. The `_load()` function replaces state on each load, but the Riverpod node itself never disposes.

### 10.2 `HealthVaultController` Stream Unlimited

`MedicalVaultRepository.fetchRecordsForPet()` uses a Supabase realtime stream limited to 100 active records. As records grow beyond 100, older records silently disappear from the stream. The realtime subscription does not paginate — this is a hard ceiling for power users.

### 10.3 `careStreakRealtimeProvider` Always Active

`careStreakRealtimeProvider` is `autoDispose.family` but `CareDashboard.build()` calls `ref.watch(careStreakRealtimeProvider(petId))` which keeps it alive as long as the dashboard is alive. Since the dashboard is `keepAlive: true`, the streak stream never disposes in practice. This doubles the realtime subscriptions (one from the dashboard, potentially one from a page that also reads streak). Verify there is only ever one active subscription per pet.

### 10.4 Dashboard RPC Called on Every Date Change

`selectDate()` calls `_load()` which calls the full `get_care_dashboard_snapshot` RPC even for dates already visited in the session. There is no client-side cache for snapshot results per date.

**Recommendation:** Cache snapshots by `(petId, date)` key in the controller for the current session (LRU, max 14 entries). Invalidate on task create/update/delete.

---

## 11. Prioritised Fix List

### P0 — Crash / Unreachable

| ID | Issue | File |
|---|---|---|
| P0-1 | Register `/care/walk` route for `WalkTrackingScreen` | `care_routes.dart` |
| P0-2 | Register `/care/medical-vault` route for `MedicalVaultScreen` | `care_routes.dart` |
| P0-3 | Register `/care/nutrition` route for `NutritionScreen` | `care_routes.dart` |
| P0-4 | Verify `CareExploreRow` "Communities" tile route exists or remove tile | `care_banners.dart` |
| P0-5 | Add title validation — empty title must block form submission | `care_task_form_sheet.dart` |

### P1 — High-Impact UX / Data Integrity

| ID | Issue | File |
|---|---|---|
| P1-1 | Show prescribed dose count vs given today in medication card | `medications_screen.dart` |
| P1-2 | Add missed-dose indicator to medication card | `medications_screen.dart` |
| P1-3 | Add confirmation before deactivating medical record | `medical_vault_screen.dart` |
| P1-4 | Add unit toggle kg/lbs for weight input | `nutrition_screen.dart` |
| P1-5 | Surface symptom checker in care screen UI | `care_screen.dart`, `care_banners.dart` |
| P1-6 | Persist walk data to Supabase (walks table) | `walk_tracking_screen.dart` |
| P1-7 | Fix confetti replay bug — store `last_seen_level` flag | `gamified_care_ui.dart` |
| P1-8 | Add semantic labels to XP bar, badges, chart | across widgets |

### P2 — Accessibility

| ID | Issue | Files |
|---|---|---|
| P2-1 | Add `Semantics(selected:)` to date picker chips | `care_date_picker.dart` |
| P2-2 | Add semantic label to care task checkbox (role + state) | `care_task_card.dart` |
| P2-3 | Add screen reader navigation to coverflow carousel | `care_coverflow_carousel.dart` |
| P2-4 | Provide data table alternative for weight chart | `vitals_chart_widget.dart` |
| P2-5 | Wrap all motion in `MediaQuery.disableAnimations` guard | `care_coverflow_carousel.dart`, `gamified_care_ui.dart` |
| P2-6 | Ensure all touch targets ≥ 44×44px | `care_date_picker.dart`, filter chips |
| P2-7 | Add focus management on sheet open/close | `care_task_form_sheet.dart`, `routine_recommendation_sheet.dart` |
| P2-8 | Add color + shape differentiation for task categories (not color alone) | `care_task_card.dart` |

### P3 — Polish / Enhancement

| ID | Issue | File |
|---|---|---|
| P3-1 | Show XP value on task card before completion | `care_task_card.dart` |
| P3-2 | Show badge description in unlock snackbar | `care_dashboard_controller.dart` |
| P3-3 | AI cache invalidation on medical/health record creation | `health_vault_controller.dart`, `health_repository.dart` |
| P3-4 | Inline edit AI suggestion before adding | `routine_recommendation_sheet.dart` |
| P3-5 | Session-persist filter chip selection | `care_screen.dart` |
| P3-6 | Extend date picker to 30 days back or add date jump button | `care_date_picker.dart` |
| P3-7 | Hide AI banner after routine generated (show "Regenerate" instead) | `care_screen.dart` |
| P3-8 | Migrate `WeightLog` to Freezed | `weight_log.dart` |
| P3-9 | Add error wrapping to `VitalsRepository` | `vitals_repository.dart` |
| P3-10 | Consolidate `VitalsNotifier` + `NutritionNotifier` into single weight provider | controllers |
| P3-11 | Streak-at-risk banner when streak in danger and freezes available | `care_screen.dart` |
| P3-12 | Add per-medication dose window (not hardcoded 30 min) | `medications_controller.dart`, `health_repository.dart` |
| P3-13 | Document date convention (local vs UTC) at top of `pet_care_repository.dart` | `pet_care_repository.dart` |
| P3-14 | Migrate `aiRoutineProvider` to Riverpod generator | `ai_routine_controller.dart` |

---

*Generated by Claude Code — care module audit pass on `accessibility-fix-salman-2`.*
