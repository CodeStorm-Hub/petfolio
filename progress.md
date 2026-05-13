# Petfolio — Progress Log

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
