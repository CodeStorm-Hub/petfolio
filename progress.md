# Petfolio — Progress Log

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
