# Handoff

## State
Smart Nutrition & Weight Tracking feature complete. `flutter analyze` → 0 issues.
- `lib/features/care/presentation/controllers/nutrition_controller.dart`: `NutritionState`, `nutritionProvider`, `NutritionNotifier` (logWeight, refresh)
- `lib/features/care/presentation/screens/nutrition_screen.dart`: full screen — fl_chart LineChart weight history, NRC calorie card (RER = 70×kg^0.75×activity×species), `_LogWeightSheet` (kg/lbs toggle, notes, date picker)
- `lib/core/router.dart`: `/care/nutrition` route added (`parentNavigatorKey: _rootNavigatorKey`)
- `lib/features/care/presentation/screens/care_screen.dart`: `_NutritionBanner` card appended to ListView, navigates to `/care/nutrition`

## Next
1. Consolidate duplicate Pet models — `lib/features/care/data/models/pet.dart` (Freezed) vs `lib/features/pet_profile/data/models/pet.dart`; check `ActivityLevel` enum usages before deleting
2. Verify `health_vitals` / `health_logs` INSERT RLS policy allows pet owners to write (weight log is best-effort/silent on failure)
3. Wire Symptom / Vet Visit logging into the nutrition screen or a new Health Log screen

## Context
- `fl_chart 0.69.2`: use `LineTouchTooltipData(getTooltipColor: ...)` not deprecated `tooltipBgColor`
- Calorie factors: sedentary=1.2, low=1.4, moderate=1.6, high=1.8, very_high=2.0; cat modifier=0.9
- `CareTaskType` name conflict still exists: old `care_task_type.dart` (3 values) vs new `care_task.dart` (11 values); care_screen uses `import '../../data/models/care_task.dart' as dbtask;`
