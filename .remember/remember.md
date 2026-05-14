# Handoff

## State
Care Dynamic Daily Routine Dashboard complete. `flutter analyze` → 0 issues.
- `care_dashboard_controller.dart`: `DailyRoutineState` + `careDashboardProvider` (NotifierProvider.family) + `CareDashboardNotifier` (selectDate, refresh, toggleTask with optimistic updates)
- `care_screen.dart` fully rewritten: `_HorizontalDatePicker` (14-day chips, auto-scroll to today), `_DailyTasksDashboard` (AsyncValue.when + skeleton/error/empty states), `_CareTaskCard` (Dismissible swipe + animated checkbox), `_EmptyRoutineState`. All mock vitals/checkup data removed.
- Onboarding: `_totalSteps = 3` (internal 0-4), `_PetDetailsStep` merges Name/DOB/Weight/Activity, `_ActivityTile` rows fix overflow.

## Next
1. Consolidate duplicate Pet models — `lib/features/care/data/models/pet.dart` (Freezed) duplicates `lib/features/pet_profile/data/models/pet.dart`; check `ActivityLevel` enum usages in care controllers before deleting
2. Wire care controllers to consume `pet.dateOfBirth` and `pet.activityLevel` for personalised task defaults
3. Verify `health_vitals` INSERT RLS policy allows pet owners to write

## Context
- `CareTaskType` name conflict: old `care_task_type.dart` (3 values) vs new `care_task.dart` (11 values). Care screen uses `import '../../data/models/care_task.dart' as dbtask;` to alias new type; streak banner uses unaliased old enum
- `careDashboardProvider` is family-keyed by `petId` (String); consume via `ref.watch(careDashboardProvider(activePet.id))`
- `careControllerProvider` (ChecklistRepository) still used for streak banner — two systems coexist intentionally
