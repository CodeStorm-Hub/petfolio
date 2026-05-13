# Handoff

## State
Onboarding UI refinement complete. `flutter analyze` → 0 issues. `onboarding_screen.dart` fully rewritten: steps reduced to 3 visible (Welcome → Species+Breed → PetDetails → Photo → Done). Species grid now 3-col compact (`mainAxisExtent: 56`), breed search uses AuthField-style focus glow + `OutlineInputBorder`. Steps 2/3/4/5 merged into `_PetDetailsStep` (scrollable: name + DOB picker + weight fields + activity tiles). All input fields match auth screen style. Activity overflow fixed via `_ActivityTile` (52dp horizontal rows, no grid).

## Next
1. Wire care engine controllers to consume `pet.dateOfBirth` and `pet.activityLevel` for personalised task defaults (`lib/features/care/presentation/controllers/`)
2. Consolidate duplicate Pet models — `lib/features/care/data/models/pet.dart` (Freezed) duplicates `lib/features/pet_profile/data/models/pet.dart` (source of truth); update care imports and delete Freezed duplicate
3. Verify `health_vitals` INSERT RLS policy allows pet owners to write — target weight write is silent/best-effort and may fail without an explicit policy

## Context
- `_totalSteps = 3` in state; internal steps 0-4 (Welcome/SpeciesBreed/PetDetails/Photo/Done)
- `_PetDetailsStep` owns name/DOB/weight/activity — parent state callbacks: `onNameChanged`, `onDobPick`, `onWeightChanged`, `onTargetChanged`, `onUnitToggle`, `onActivityPick`
- `lib/features/care/data/models/pet.dart` Freezed model has `ActivityLevel` enum the care controllers depend on — check usages before deleting
