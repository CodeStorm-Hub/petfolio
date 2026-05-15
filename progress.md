# Petfolio — Progress Log

---

## 2026-05-15 — Unified `AppHeader` + Add another pet + Manage pets (reorder/archive)

**Header redesign — shared component across all shell screens**
- **`lib/core/widgets/app_header.dart`** — new `AppHeader` consumer widget. Slot-based layout: optional `onBack` chevron, `PetAvatar` (active pet) opening the switcher via injected `onOpenSwitcher` callback (avoids circular import with `router.dart` and `pet_switcher_sheet.dart`), `eyebrow` label (e.g. `Active pet`, `Care · Montu`, `Pack`, `Match · Nearby`, `Market · Shop`) + bold pet/screen title with chevron, then a row of `AppHeaderAction` icon buttons (tooltip, optional `badge` count, `filled` variant, optional `iconKey` for marionette/widget tests). `showDivider` and `dense` flags toggle bottom hairline and tighter vertical padding. Exported from `lib/core/widgets/widgets.dart`.
- **`AppHeaderAction`** — value type: `{ icon, onTap, tooltip, badge?, filled, iconKey? }`. Badges render as coral pill over the icon (re-used by cart count in Market header).
- **Adopted in** `pet_profile_screen.dart` (eyebrow `Active pet`, actions: outdoor toggle + notifications), `care_screen.dart` (eyebrow `Care · ${activePet.name}`, action: outdoor toggle, `onBack` pops to home), `social_screen.dart` (eyebrow `Pack`, action: messages), `matching_screen.dart` (eyebrow `Match · Nearby`, action: filters, `dense: true`), `marketplace_screen.dart` (eyebrow `Market · Shop`, action: cart with live `cart.itemCount` badge). All old `_ActivePetHeader` / `_Header` / `_SocialHeader` / `_DiscoveryHeader` / `_ShopHeader` private classes removed.

**Add another pet flow**
- **`lib/core/router.dart`** — `/onboarding` now reads `state.uri.queryParameters['mode']`. When `mode=add` for an authenticated user with existing pets, the redirect guard allows the route through (instead of bouncing to `/care`). Added `/pets/manage` route → `ManagePetsScreen`.
- **`lib/features/pet_profile/presentation/screens/onboarding_screen.dart`** — constructor takes `bool addAnotherPet`. When true, `_step` starts at `1` (species + breed) skipping the welcome step, and `_back()` at step 1 calls `context.pop()` instead of stepping back to welcome — preserves the rest of the existing flow incl. DOB / weight / activity / photo capture and `createPet` write path.
- **`pet_switcher_sheet.dart`** — `_AddPetButton.onTap` → `context.push('/onboarding?mode=add')`; `_ManageRow.onTap` → `context.push('/pets/manage')` (added `ValueKey('pet_switcher_manage')` for tests).

**Manage pets (reorder + archive + undo)**
- **`lib/features/pet_profile/data/models/pet.dart`** — added `displayOrder` (`int`, default 0) + `archivedAt` (`DateTime?`); `copyWith` uses a `_sentinel` so callers can pass `archivedAt: null` to clear it; added `isArchived` getter; JSON snake-case round-trip for both fields.
- **`pet_repository.dart`** — `fetchPets({bool includeArchived = false})` filters `archived_at IS NULL` by default and orders by `display_order, created_at`; added `reorderPets(List<String> orderedPetIds)` (single batched update), `archivePet(id)` (sets `archived_at = now()`), `unarchivePet(id)` (clears it).
- **`pet_list_controller.dart`** — `reorder(reordered)` optimistically updates the local list, persists via repository, rolls back on failure. `archive(id)` returns the archived `Pet` (for undo) and removes it from local state; `unarchive(id)` re-inserts at the saved `displayOrder`.
- **`lib/features/pet_profile/presentation/screens/manage_pets_screen.dart`** — new screen. Reorderable list (`ReorderableListView.builder` with `ReorderableDragStartListener` handles), per-row `PopupMenuButton` with **Share access** (placeholder snackbar; intentionally non-functional until backend support) and **Archive pet** (confirm dialog → repo call → `SnackBar` with `Undo` action that calls `unarchive`). Active pet row gets the coral outline + `Active` chip to match the switcher sheet. Empty + error states. `AppHeader` with eyebrow `Manage · Pets`. `_AddPetCallout` row at the bottom routes to `/onboarding?mode=add` for parity with the switcher.
- **`supabase/migrations/20260516200000_pets_display_order_archive.sql`** — adds `display_order INTEGER NOT NULL DEFAULT 0` and `archived_at TIMESTAMPTZ NULL` to `public.pets`, partial index `pets_owner_active_order_idx ON (owner_id, archived_at, display_order, created_at) WHERE archived_at IS NULL`, and a one-shot backfill via `ROW_NUMBER() OVER (PARTITION BY owner_id ORDER BY created_at)` for existing rows where `display_order = 0`. Existing RLS policies on `pets` cover the new columns (owner-only SELECT/UPDATE).

**Verification**
- `flutter analyze` — clean (only resolved: removed an unused `pet.dart` import in `care_screen.dart` after the header refactor).
- `flutter test` — `care_scheduled_time_test.dart` (3) + `care_task_model_crud_test.dart` (1) pass. The pre-existing `test/widget_test.dart` placeholder still fails (missing `ProviderScope`) — known issue documented in `CLAUDE.md`, unchanged by this phase.
- **Deferred**: live emulator + Marionette walkthrough of (a) each shell screen header, (b) end-to-end add-another-pet onboarding write, (c) reorder/archive/undo in Manage pets. The migration also still needs to be applied to the remote project via `apply_migration` before the Manage screen can persist `display_order` / `archived_at` in production.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Care task edit / delete + CRUD checks

- **`care_screen.dart`** — `_CareTaskFormSheet` (add + edit): optional `existing` task; **PopupMenu** on each non–log-derived row (`care_task_menu_<id>`) for **Edit** / **Delete**; delete confirm dialog; edit reopens same bottom sheet with fields prefilled; save path calls `updateTask` or `createTask`.
- **`care_screen.dart` (follow-up)** — Rows from **orphan `care_logs`** (`Activity log | This day`, id `log:…`) now get the same **⋮** menu with **Add to plan** (prefilled new `care_tasks` row via `createSeed`) and **Remove from day** (deletes that log); plan rows keep **Edit** / **Delete**.
- **`care_dashboard_controller.dart`** — `updateTask`, `deleteTask` after repository calls reload the selected day (and week badges).
- **`pet_care_repository.dart`** — `updateTask` PATCH payload drops `id`, `pet_id`, `created_at`, `updated_at`, `category_icon` so Postgres applies `set_updated_at` and RLS stays valid.
- **`lib/features/care/presentation/utils/care_scheduled_time.dart`** — `parseCareScheduledTimeOfDay` for `scheduled_time` strings.
- **Tests** — `test/care_scheduled_time_test.dart`, `test/care_task_model_crud_test.dart` (edit `copyWith` invariants).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Seven calendar days (May 9–15) Care automation

- **`pet_care_repository.dart`** — `_appliesOnDay`: `daily` / `twice_daily` / `as_needed` tasks are shown for every calendar day on the strip (no longer hidden before `task.created_at`), matching `check_daily_completion` expected types.
- **Supabase remote** — Applied migration `check_daily_completion_completion_date` (`check_daily_completion(uuid, date)`); previously only `(uuid)` existed, so `completion_date` from the app failed and streak never updated from strip completions.
- **Marionette** — `flutter run -d emulator-5554`, connect VM service, Care tab: for each day `care_date_YYYY-MM-DD` then `care_task_check_*` taps; May 14 skipped redundant feeding tap; May 15 added feeding only.
- **Post-run** — `care_logs` for Montu (`14378b2e-5961-4d07-ab9f-48246e839e10`) have feeding+training on May 9–13 and 15; May 14 also has walk/medication from earlier tests. After migration + navigation refresh, Care UI showed **7 day streak**; `care_streaks` / `pet_badges` aligned to seven completed strip days (service SQL used once to backfill streak row where RPC had not run during the earlier tap batch).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streak QA (Marionette) + ring center + RPC calendar date

- **`care_screen.dart`** — Streak hero: softer outer ring stroke; center shows **done / of total** when tasks exist, with **streak** on a sub-row; empty plan keeps flame + streak in center; today legend clarifies inner vs outer rings.
- **`pet_care_repository.dart`** — After a successful complete, always calls `check_daily_completion` with `completion_date` = `logged_date` (local calendar string) so streaks update when finishing a day from the date strip, not only “device today.”
- **`supabase/migrations/20260515193000_check_daily_completion_completion_date.sql`** + **remote `execute_sql`** — `check_daily_completion(uuid, date default null)`; `v_today` uses passed date or UTC fallback; grants on `(uuid, date)`.
- **Marionette (emulator-5554)** — Care tab: May 14 shows chip `3/3`, list aligned; before change, center `0` conflicted with full inner ring.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streak hero synced to selected date + Fitness-style layout

- **`care_dashboard_controller.dart`** — `fetchDailyGoalsHitForDates` week list is `_weekEndingOn(selectedDate)` so week dots match the same 7-day window as the date strip selection (not always ending calendar today).
- **`care_screen.dart`** — `_StreakBanner` inner ring, done/total chip, task-type chips, and week row use `dashboard.tasks` + `selectedDay`; badge shows `TODAY` vs `MAY 14` style label; outer ring maps capped streak (28d) for a second progress track; `LayoutBuilder` + `ConstrainedBox(maxWidth: 560)` on wide windows; date strip in a solid bordered surface card per design system.
- **Supabase `execute_sql`** — Montu `care_logs`: 2026-05-14 feeding/medication/walk; 2026-05-15 feeding only (cross-check for 3/3 vs 1/2 UI).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Marionette + emulator QA; nutrition / home streak fixes

- **`pubspec.yaml`** — `marionette_flutter` for MCP-driven UI automation (debug only; skipped under `FLUTTER_TEST` / `Platform.environment['FLUTTER_TEST']`).
- **`main.dart`** — `MarionetteBinding.ensureInitialized()` when Marionette enabled, else `WidgetsFlutterBinding`.
- **`router.dart`** — `ValueKey('shell_nav_…')` on each `NavigationDestination` for stable taps.
- **`care_screen.dart`** — `ValueKey`s: `care_fab_add_task`, `care_nutrition_banner`, `care_medical_vault_banner`.
- **`nutrition_screen.dart`** — weight chart: `minX`/`maxX`, bottom title `interval: 1` + integer guard against duplicate date labels; `_CalorieCard` takes `AsyncValue<List<HealthLog>>` so MER uses latest logged weight when data loads; display kg uses two decimals under 20 kg.
- **`pet_profile_screen.dart`** — `_HeroCard` reads `careStreakRealtimeProvider(pet.id)` instead of hardcoded `28` for the big streak number.
- **Validation** — Android emulator (`emulator-5554`) + Marionette MCP: Care tab, Nutrition, Medical vault; Supabase MCP row checks for `health_logs`, `medical_vault`, `care_logs`, `care_streaks`.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Orphan `care_logs` rows on historical days (e.g. May 14)

- **`pet_care_repository.dart`** — `fetchTasksForDate` merges `care_logs` for the selected `logged_date` into synthetic `CareTask` rows (`id` prefix `log:`) when no scheduled `care_tasks` definition covers that `care_type` for that day; `toggleCompletion` / `deleteTask` handle `log:` ids (delete log row, no `care_tasks` lookup); `_loggedDayKey` normalizes `logged_date` from PostgREST.
- **`care_task_log.dart`** — `CareTask.isLogDerived` extension.
- **`care_screen.dart`** — log-derived cards skip `Dismissible` swipe; checkbox only clears the log entry; sublabel `Activity log | This day`; `initState` defers `_init` via `Future.microtask` after first frame.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Per-day care completions (care_logs) + ring vs list

- **`pet_care_repository.dart`** — `fetchTasksForDate` scopes tasks by definition + `care_logs` for that **local calendar day**; recurring toggles insert/delete `care_logs` (aligned with `check_daily_completion`); `once` still updates `care_tasks` + log; `fetchDailyGoalsHitForDates` uses logs only; `toggleCompletion(..., forDay)`.
- **`care_dashboard_controller.dart`** — `DailyRoutineState.todayTasks` loaded in parallel so the streak **ring** always reflects **today** while the list reflects the **selected** date; toggle passes `forDay`.
- **`care_screen.dart`** — streak banner uses `todayTasks` for ring/icons and clarifies copy when browsing past days.
- **`supabase/migrations/20260516120000_care_logs_type_day.sql`** — `logged_date` backfill from `occurred_at`, widen `care_type` check, unique `(pet_id, care_type, logged_date)`.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care dashboard Riverpod fix (tasks / add task / dates)

- **`care_dashboard_controller.dart`** — `build()` no longer reads `state` when merging the streak stream (that caused uninitialized-provider crashes and stuck `AsyncLoading` tasks). Dashboard state is merged via a private **`_routine`** snapshot plus `state = _routine` after async `_load` / toggles.
- **`care_controller.dart`** — `ref.listen(careDashboardProvider, …, fireImmediately: true)` replaces the microtask `ref.read(careDashboardProvider)` so the checklist notifier never reads the dashboard before it has emitted.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Freezed + json_serializable `_$XFromJson` fix

- Removed class-level `@JsonSerializable(fieldRename: FieldRename.snake)` from `care_task`, `medical_record`, `health_log`, `pet` (with `@freezed` it duplicated `_$XFromJson` in `.freezed.dart` and `.g.dart`). Added root **`build.yaml`** with `json_serializable` **`field_rename: snake`** so generated `fromJson`/`toJson` keep Supabase-style keys.

---

## 2026-05-15 — Care streak Realtime (UI sync)

- **`care_streak_stream_provider.dart`** — `StreamProvider.autoDispose.family` on `care_streaks` (`primaryKey: ['pet_id']`, `.eq('pet_id', petId)`), empty row → zero `CareStreak`.
- **`care_dashboard_controller.dart`** — `build()` `ref.watch(careStreakRealtimeProvider(petId))` and merges streak into returned `DailyRoutineState` (no HTTP streak in `_load`, no stacked `ref.listen`); `_load` / `toggleTaskCompletion` only refresh tasks, week dots, badges.
- **`supabase/migrations/20260515180000_care_streaks_realtime.sql`** — idempotent add of `public.care_streaks` to `supabase_realtime` publication when missing.

**Applied:** remote project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP `apply_migration` (`care_streaks_realtime`).

**Realtime RLS:** client stream respects existing `care_streaks` SELECT policies (owner via `pets`); if a device shows no stream events, confirm the row exists for that pet after first completion and that the user session matches owner.

**Next step:** None for this slice.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streaks & badges (SQL migration)

- **`supabase/migrations/20260515140000_care_streaks_badges.sql`** — `care_streaks` (PK `pet_id`), `pet_badges` (PK `pet_id`, `badge_type`); RLS **SELECT** for pet owners only; **`check_daily_completion(uuid)`** `SECURITY DEFINER` + `search_path ''`: derives expected task types from `care_tasks` (`daily` / `twice_daily`) or fallback `feeding` / `walk` / `medication`; compares to `care_logs` for **UTC calendar date**; updates streak / `best_streak` / `last_completion_date`; inserts `7_day_hero` on first time `current_streak >= 7`; returns JSON summary (`total`, `completed`, `all_done`, streak fields, `badge_unlocked`). `GRANT EXECUTE` to `authenticated`; table **SELECT** only (writes via RPC).

**Applied:** remote project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP `apply_migration` (`care_streaks_badges`). Verified `care_streaks` / `pet_badges` (RLS on) and `check_daily_completion`.

**Next step:** Wire Flutter: after checklist sync call `supabase.rpc('check_daily_completion', params: {'target_pet_id': petId})` when the third daily log lands (or on refresh). Optional: align `v_today` with app local date via a second argument in a follow-up migration.

---

## 2026-05-15 — Pet care repo: streaks, RPC on complete, task icons

- **`pet_care_repository.dart`** — `PetCareRepository` (replaces `CareTaskRepository` name; `typedef CareTaskRepository` + `careTaskRepositoryProvider` alias preserved); `getPetStreak(petId)` reads `care_streaks` (empty row → zeros); `toggleCompletion` takes `petId`, calls `check_daily_completion` after marking complete (RPC errors swallowed so toggle still succeeds); create/update strip `category_icon` until DB column exists.
- **`care_repository.dart`** — re-exports `pet_care_repository.dart`.
- **`care_streak.dart`** — hand-written model + `fromJson` / `toJson` (no freezed) for `care_streaks` rows.
- **`care_task.dart`** — `categoryIcon` (JSON `category_icon`), `resolvedCategoryIcon`, `categoryIconData`; `careTaskCategoryIconData` maps keys + aliases to `IconData`.
- **`care_dashboard_controller.dart`** — passes `petId` into `toggleCompletion`.
- **`care_screen.dart`** — task cards use `task.categoryIconData`.
- **`analysis_options.yaml`** — exclude `*.g.dart` / `*.freezed.dart` from analyzer (resolves duplicate `_$XFromJson` between freezed + json_serializable outputs).

**Next step:** Optional UI for `getPetStreak`; optional `category_icon` column on `care_tasks` if server-driven icons are required.

---

## 2026-05-15 — Care streak banner UI (Fitness / Snapchat style)

- **`pet_care_repository.dart`** — `fetchPetBadgeTypes`, `fetchDailyGoalsHitForDates` (care_tasks daily expectations + `care_logs` + completed `care_tasks` per day); `toggleCompletion` returns `ToggleCompletionResult` (parses RPC `badge_unlocked`).
- **`care_dashboard_controller.dart`** — `DailyRoutineState` adds `streak`, `weekGoalHit`, `badgeTypes`; `_load` parallel-fetches tasks/streak/badges/week; first-load badge baseline via `_hydratedBadgePets`; subsequent loads detect new `7_day_hero`; toggle still calls `AppSnackBar.showBadgeUnlocked` on RPC flag.
- **`app_snack_bar.dart`** — `showBadgeUnlocked` floating snackbar (green + trophy).
- **`care_task.dart`** — `careTaskTypeIconData` for icon chips.
- **`care_screen.dart`** — `_StreakBanner` is a `ConsumerWidget`: progress ring (`CircularProgressIndicator` + fire + server streak), 7-day dot row from `weekGoalHit`, `Wrap` of unique `taskType` icons for today’s routine list; removed legacy `_DayCell` / `_LegendDot` / `_TaskGlyphPainter`.

**Next step:** Optional full-screen badge overlay; optional confetti package.

---

## 2026-05-15 — Medical record renewal getter + nutrition chart empty state

- **`medical_record.dart`** — `renewalDate` (`nextDueAt ?? expiresAt`) and `isExpiringSoon` (date-only renewal within today…today+30).
- **`medical_vault_screen.dart`** — Warning styling uses `record.isExpiringSoon`; removed duplicate renewal logic from the private extension.
- **`petfolio_empty_state.dart`** + **`widgets.dart`** — Reusable empty state (icon, title, subtitle).
- **`nutrition_screen.dart`** — Weight trend shows `PetfolioEmptyState` when fewer than two weight logs (distinct copy for 0 vs 1); removed `_EmptyChart`.

**Next step:** None.

---

## 2026-05-15 — Care task toggle: optimistic UI + AppSnackBar errors

- **`app_snack_bar.dart`** + **`widgets.dart`** — `appSnackBarMessengerKey` + `AppSnackBar.showError` for app-wide floating snackbars.
- **`main.dart`** — `scaffoldMessengerKey: appSnackBarMessengerKey` on `MaterialApp.router`.
- **`care_dashboard_controller.dart`** — `toggleTaskCompletion`: optimistic list update, await `_repo.toggleCompletion`, on failure revert when still same active pet + `AppSnackBar.showError`.
- **`care_screen.dart`** — call sites use `toggleTaskCompletion`.

**Next step:** None.

---

## 2026-05-15 — Care dashboard & health vault scoped to active pet ID

- **`care_dashboard_controller.dart`** — `careDashboardProvider` is a single `NotifierProvider` that `ref.watch(activePetIdProvider)`; null ID → `AsyncData([])` and today’s date; pet change → loading + `_load` for that pet with stale-response guards; mutations no-op when no active pet.
- **`health_vault_controller.dart`** — `healthVaultControllerProvider` is a non-family `StreamNotifierProvider`; `build()` watches `activePetIdProvider`, null → `Stream.value([])`, else Supabase realtime stream for that `pet_id` (re-subscribes when ID changes).
- **`care_controller.dart`**, **`care_screen.dart`**, **`medical_vault_screen.dart`** — Call sites updated (no `.family` argument).

**Next step:** None required for this wiring; optional QA when switching pets on Care and Medical vault tabs.

---

## 2026-05-14 — Care routing, onboarding → Care, care cleanup

- **`lib/core/router.dart`** — Documented Care routes: shell `/care`, overlays `/care/nutrition`, `/care/medical-vault`. Redirect when `/onboarding` but user already has pets now sends **`/care`** (was `/home`). Deep link after successful onboarding: **`/care?onboardingComplete=1`** (handled in `CareScreen`).
- **`onboarding_screen.dart`** — After successful `_complete`, **`context.go('/care?onboardingComplete=1')`** instead of `/home` (avoids circular import with `router.dart`).
- **`care_screen.dart`** — `didChangeDependencies` + one-shot flag: reads `onboardingComplete=1`, shows floating **SnackBar**, then **`context.go('/care')`** to strip the query.
- **`lib/features/care/data/models/care_task_type.dart`** — Removed unused PetSphere-style **mock** `label` / `sublabel` / `iconColor` / `iconTint` getters; enum `feed` / `walk` / `med` unchanged for checklist + streak wiring.

**Scan note:** No separate mock asset files or deprecated screens under `lib/features/care/` beyond the trimmed enum.

**Next step:** Optional — document `/care?onboardingComplete=1` in README for QA.

---

## 2026-05-14 — Automated Medical Vault UI (Care)

- **`lib/core/widgets/app_bottom_sheet.dart`** — `AppBottomSheet.show` wraps `showModalBottomSheet` with transparent scrim, scroll-controlled sheet, and `PetfolioThemeExtension.surface1` top shell; exported from `widgets.dart`.
- **`lib/features/care/presentation/screens/medical_vault_screen.dart`** — `MedicalVaultScreen` + public `AddMedicalRecordSheet`: three sections (Vaccines: `vaccine`; Medications: `medication`, `parasite_prevention`; Vet visits: `surgery`, `allergy`, `other`) fed by `ref.watch(healthVaultControllerProvider(petId))`. Cards use `pt.warning` border/fill/tint when **renewal** = `nextDueAt ?? expiresAt` falls between **today** and **today + 30 days** (date-only). FAB opens `AppBottomSheet` with the form; save calls `addRecord`. Swipe on a card triggers `deactivateRecord` (optimistic list update via stream).
- **`lib/core/router.dart`** — full-screen route `/care/medical-vault` → `MedicalVaultScreen`.
- **`lib/features/care/presentation/screens/care_screen.dart`** — `_MedicalVaultBanner` under daily tasks (same pattern as nutrition) navigates to the vault.
- **`health_vault_controller.dart`** — `addRecord` returns `Future<bool>` so the sheet can show an error without popping on failure.

**Next step:** Optional polish — record detail screen, edit flow, or push notifications when `reminder_enabled` and `next_due_at` align.

---

## 2026-05-14 — CLAUDE.md Rules & Token Strategy Appended

- Added **Project Rules & Token Optimization Strategy** section to `CLAUDE.md`
- Rules cover: no-documentation policy, `progress.md` pattern, aggressive context scoping, targeted diffs, and strict sequential feature execution order

**Next step:** Begin next feature phase. Start a new task with a specific feature name (e.g. "implement Care Tasks UI") and Claude will scope reads to only that feature directory.

---

---

## 2026-05-14 — Pet Care & Health Management Schema

**Migration:** `supabase/migrations/20260513192825_pet_care_health.sql`
**Applied to:** live Supabase project `jqyjvhwlcqcsuwcqgcwf`
**Docs updated:** `docs/database_schema_and_erd.md` (table count 9 → 12, ERD extended)

### What was done

Added the backend schema for a Pet Care & Health Management system. No Flutter code was written; this session established the data layer only.

1. **`pets.activity_level`** — new nullable column (`sedentary | low | moderate | high | very_high`) added to the existing `pets` table.

2. **`care_tasks`** — new table for scheduled and recurring care tasks per pet. Distinct from `care_logs` (which records past events); `care_tasks` represents the forward-looking schedule. Supports gamification via `gamification_points` (default 10).

3. **`health_logs`** — new table for narrative health events (symptoms, weight entries, vet visit notes). Distinct from `health_vitals` (structured numeric measurements); `health_logs` captures the clinical story around each event.

4. **`medical_vault`** — new table for vaccine and medication records with `expires_at` and `next_due_at` date tracking. Supports reminder logic via `reminder_enabled` flag and partial indexes on the date columns.

5. **`set_updated_at()` trigger function** — shared trigger applied to all three new tables. Created with `SET search_path = ''` (Supabase security lint 0011 compliant).

---

### Data Contracts

#### `care_tasks`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `task_type` | `text` | `feeding \| walk \| grooming \| medication \| vet_visit \| training \| playtime \| dental \| nail_trim \| bath \| other` |
| `frequency` | `text` | `once \| daily \| twice_daily \| weekly \| biweekly \| monthly \| as_needed` |
| `scheduled_time` | `time` | nullable; wall-clock time of day |
| `is_completed` | `boolean` | default `false` |
| `completed_at` | `timestamptz` | nullable; set when task is ticked off |
| `gamification_points` | `integer` | default `10`, must be ≥ 0 |

#### `health_logs`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `recorded_by` | `uuid FK → users.id` | must equal `auth.uid()` on insert |
| `log_type` | `text` | `symptom \| weight \| vet_visit \| medication \| allergy \| injury \| general` |
| `weight_kg` | `numeric` | nullable; only relevant for `log_type = weight` |
| `severity` | `text` | nullable; `mild \| moderate \| severe \| critical` |
| `follow_up_date` | `date` | nullable; drives follow-up reminders |
| `occurred_at` | `timestamptz` | default `now()`; index supports DESC timeline queries |

#### `medical_vault`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `record_type` | `text` | `vaccine \| medication \| allergy \| surgery \| parasite_prevention \| other` |
| `administered_at` | `date` | nullable |
| `expires_at` | `date` | nullable; partial index `(pet_id, expires_at)` |
| `next_due_at` | `date` | nullable; partial index `(pet_id, next_due_at)` — primary field for reminder queries |
| `is_active` | `boolean` | default `true`; set to `false` to archive without deleting |
| `reminder_enabled` | `boolean` | default `true`; UI should gate notification scheduling on this |
| `document_url` | `text` | nullable; link to uploaded vaccine certificate / prescription |

---

### RLS Summary

All three new tables enforce **pet-owner-only** access. The ownership check used consistently:

```sql
(SELECT auth.uid()) IN (
  SELECT owner_id FROM public.pets WHERE id = <table>.pet_id
)
```

- **SELECT / UPDATE / DELETE** — USING clause with the ownership check above.
- **INSERT** — WITH CHECK clause with the same ownership check. `health_logs` INSERT additionally enforces `(SELECT auth.uid()) = recorded_by`.
- **UPDATE** — carries both USING and WITH CHECK to prevent silent 0-row updates (Postgres RLS requirement).

No public or service-role bypass policies exist on these tables.

---

---

## 2026-05-14 — Dart Models: Pet, CareTask, HealthLog, MedicalRecord

**Files created:** `lib/features/care/data/models/` (4 models + 8 generated files)
**Code generation:** `build_runner build` — 12 outputs written, 0 errors

### Models

- **`pet.dart`** — Freezed `Pet` + `ActivityLevel` enum. New fields: `dateOfBirth`, `activityLevel`. Helpers: `ageInYears`, `ageLabel`, `speciesEnum`. **Supersedes** `lib/features/pet_profile/data/models/pet.dart` — that file should be replaced/re-exported once care repositories are wired.
- **`care_task.dart`** — Freezed `CareTask` + `CareTaskType` + `CareFrequency` enums. Maps `care_tasks` table. Helpers: `isDueToday`, `isOverdue`, `markCompleted()`, `reset()`. ⚠️ `CareTaskType` name conflicts with old UI-only enum in `care_task_type.dart` — avoid importing both in the same file.
- **`health_log.dart`** — Freezed `HealthLog` + `HealthLogType` + `HealthSeverity` enums. Maps `health_logs` table. Helpers: `isWeightEntry`, `isVetVisit`, `followUpOverdue`, `daysUntilFollowUp`.
- **`medical_record.dart`** — Freezed `MedicalRecord` + `MedicalRecordType` enum. Maps `medical_vault` table. Helpers: `isExpired`, `isDueSoon(withinDays)`, `isOverdue`, `daysUntilExpiry`, `daysUntilDue`, `needsReminder`.

### Data Contracts

All fields use `@JsonSerializable(fieldRename: FieldRename.snake)` — Dart `camelCase` fields map automatically to DB `snake_case` columns. All enums use `@JsonEnum(fieldRename: FieldRename.snake)`.

### Open items / next steps

- Repositories for `care_tasks`, `health_logs`, and `medical_vault` — Supabase queries, RLS-aware.
- Riverpod providers / StateNotifiers wrapping those repositories.
- Replace `lib/features/pet_profile/data/models/pet.dart` with the new Freezed version (or re-export from care models).
- `pet.dateOfBirth` needs a DB migration to add `date_of_birth date` column to `pets` table if age display is needed.
- `care_tasks` gamification point totals need Dart-side aggregation for streak/score UI.
- `medical_vault.reminder_enabled` + `next_due_at` → push notification scheduling.
- `health_logs.follow_up_date` → optionally auto-create a `vet_visit` `care_task` row.

---

---

## 2026-05-14 — Care & Health Repositories + AppException

**Files created/modified:**
- `lib/core/errors/app_exception.dart` — new
- `lib/features/care/data/repositories/care_repository.dart` — replaced (was checklist logic, now CareTask CRUD)
- `lib/features/care/data/repositories/checklist_repository.dart` — new (renamed from old care_repository.dart)
- `lib/features/care/data/repositories/health_repository.dart` — new
- `lib/features/care/presentation/controllers/care_controller.dart` — import updated
- `lib/features/care/data/models/*.dart` (4 files) — annotation fix

### What was implemented

- **`AppException`** — sealed class with 5 typed subclasses: `NetworkException`, `NotAuthenticatedException`, `NotFoundException`, `ValidationException`, `DatabaseException`. All repositories catch `PostgrestException` and rethrow as the appropriate subclass. `PGRST116` (no rows) maps to `NotFoundException`.

- **`CareTaskRepository`** (`care_repository.dart`) — full CRUD against `care_tasks` table:
  - `fetchTasksForPet(petId)` — all tasks ordered by `created_at`
  - `fetchTasksForDate(petId, date)` — two queries merged: uncompleted tasks + tasks with `completed_at` on target date
  - `createTask(task)` — inserts without `id` (DB generates); returns created row
  - `updateTask(task)` — updates by `id`; returns updated row
  - `deleteTask(taskId)` — hard delete
  - `toggleCompletion(taskId, {required bool isCompleted})` — atomically sets `is_completed` + `completed_at`; returns updated row

- **`HealthRepository`** (`health_repository.dart`) — CRUD against `health_logs` table:
  - `fetchLogsForPet(petId)` — newest first
  - `fetchLogsByType(petId, type)` — filtered by `HealthLogType`
  - `fetchWeightHistory(petId)` — weight entries only, ascending (chart-ready)
  - `createLog`, `updateLog`, `deleteLog`

- **`MedicalVaultRepository`** (`health_repository.dart`) — CRUD against `medical_vault` table:
  - `fetchRecordsForPet(petId)` — all records newest first
  - `fetchActiveRecords(petId)` — `is_active = true`, ordered by `next_due_at` ascending
  - `fetchRecordsByType(petId, type)` — filtered by `MedicalRecordType`
  - `createRecord`, `updateRecord`, `deleteRecord`
  - `deactivateRecord(recordId)` — soft delete (sets `is_active = false`)

- **`ChecklistRepository`** (`checklist_repository.dart`) — existing offline-first daily checklist logic (SharedPreferences + `care_logs` upsert/delete) preserved verbatim; class/provider renamed so `care_repository.dart` was free for the new implementation.

- **Annotation fix** — moved `@JsonSerializable(fieldRename: FieldRename.snake)` from factory constructor to class declaration in `care_task.dart`, `health_log.dart`, `medical_record.dart`, `pet.dart`. Resolves `invalid_annotation_target` lint. `flutter analyze` → 0 issues.

### Providers

| Provider | Type |
|---|---|
| `careTaskRepositoryProvider` | `Provider<CareTaskRepository>` |
| `healthRepositoryProvider` | `Provider<HealthRepository>` |
| `medicalVaultRepositoryProvider` | `Provider<MedicalVaultRepository>` |
| `checklistRepositoryProvider` | `Provider<ChecklistRepository>` (replaces old `careRepositoryProvider`) |

### Next step

Wire controllers (Riverpod StateNotifiers) for `CareTaskRepository` and `HealthRepository`, then build UI screens to display tasks and health logs.

---

---

## 2026-05-14 — Onboarding Refactor: Care Engine Data Capture

**Files modified:**
- `lib/features/pet_profile/data/models/pet.dart`
- `lib/features/pet_profile/data/repositories/pet_repository.dart`
- `lib/features/pet_profile/presentation/controllers/pet_list_controller.dart`
- `lib/features/pet_profile/presentation/screens/onboarding_screen.dart`

### What was implemented

Refactored the pet onboarding flow from 5 steps to 8 steps (6 visible in progress bar) to capture care-engine-required data during pet creation.

**New step flow:**
- Step 0: Welcome (unchanged)
- Step 1: Species + Breed (combined — species grid auto-expands breed list below)
- Step 2: Name (unchanged)
- Step 3: Date of Birth (Material date picker, shows computed age, skippable)
- Step 4: Weight (current + optional target, kg/lbs toggle, skippable)
- Step 5: Activity Level (5-card grid: Couch Potato → Athlete, skippable)
- Step 6: Photo (moved from step 4, unchanged)
- Step 7: Done (updated summary with breed/age/weight chips + accurate checklist)

**Data contracts added to `Pet` model:**
- `dateOfBirth: DateTime?` — maps `pets.date_of_birth`
- `weightKg: double?` — maps `pets.weight_kg`
- `activityLevel: String?` — maps `pets.activity_level`

**Repository changes:**
- `PetRepository.createPet()` now accepts and writes `dateOfBirth`, `weightKg`, `activityLevel`
- `PetRepository.writeTargetWeight(petId, kg)` — inserts target weight into `health_vitals` with `vital_type='weight'`, `notes='goal'` (best-effort, non-fatal if it fails)

**UX decisions:**
- DOB, weight, and activity steps all have "Skip for now" (secondary CTA) — no required steps after name
- Unit toggle (kg/lbs) in the weight step converts on the fly; stores kg in DB
- Species+breed combined: breed section animates in with `AnimatedSize` after species tap; search field clears automatically on species change
- Done step shows breed/age/weight as styled chips; checklist reflects which care-engine fields were provided

### Known constraint
- `health_vitals` RLS policy may need an explicit INSERT policy for the pet owner — verify in Supabase dashboard if target weight writes fail (currently best-effort/silent)

### Next step
Wire the care engine controllers to consume `pet.dateOfBirth` and `pet.activityLevel` for personalised task defaults. The care `Pet` model in `lib/features/care/data/models/pet.dart` is now a duplicate — consolidate with this model when wiring care controllers.
