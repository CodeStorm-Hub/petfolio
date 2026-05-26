# Automated Medical Vault UI design
_Exported on 5/15/2026 at 00:30:50 GMT+6 from Cursor (3.3.30)_

---

**User**

Review the attached controller and bottom sheet widget. I need to build the Automated Medical Vault UI under the Pet Care module.

Create a new screen or tab that implements a list view categorized by 'Vaccines', 'Medications', and 'Vet Visits'. Bind this UI directly to the HealthVaultController.

UI Requirements:

1. For any item where the renewal_date is within the next 30 days, style the card with a warning/highlight accent color from our AppTheme design system.

2. Add a floating action button to log a new medical record, utilizing the AppBottomSheet to display the data entry form.

Output the new widget and update progress.md when complete.

---

**Cursor**

Searching the codebase for HealthVaultController, AppBottomSheet, and the care module structure.



Implementing `AppBottomSheet`, the medical vault screen with categorized lists bound to `healthVaultControllerProvider`, and integrating navigation from the care screen.



Fixing Dismissible behavior, returning success from `addRecord`, and wiring the router, widgets export, and care banner.



Here is what was added and how it fits together.

### `AppBottomSheet`
Modal shell matching your care/nutrition pattern: transparent scrim, scroll-controlled sheet, rounded top, `surface1` background.

```1:28:g:\GitHub\petfolio\lib\core\widgets\app_bottom_sheet.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final pt = Theme.of(sheetContext).extension<PetfolioThemeExtension>()!;
        return Container(
          decoration: BoxDecoration(
            color: pt.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius2xl),
            ),
          ),
          child: builder(sheetContext),
        );
      },
    );
  }
}
```

Exported from `lib/core/widgets/widgets.dart`.

### Medical vault screen
- **Route:** `/care/medical-vault` (root navigator, same style as nutrition).
- **Entry:** New `_MedicalVaultBanner` on the Care home screen (below Smart Nutrition).
- **Data:** `ref.watch(healthVaultControllerProvider(petId))` for the active pet.
- **Sections:** Vaccines (`vaccine`), Medications (`medication`, `parasite_prevention`), Vet visits (`surgery`, `allergy`, `other`) so every `MedicalRecordType` appears once.
- **Renewal highlight:** Uses **`nextDueAt ?? expiresAt`** as the renewal date (your schema uses `next_due_at` / `expires_at`; there is no separate `renewal_date` on `MedicalRecord`). Highlight when that **calendar date** is between **today** and **today + 30 days**, using `PetfolioThemeExtension.warning` on border, light fill, optional shadow, and a “Due soon” chip.
- **FAB:** Opens `AppBottomSheet.show` with `AddMedicalRecordSheet` (type, name, dates, dosage/frequency, notes, reminders). Save uses `addRecord`; on failure the sheet stays open and shows a snackbar.
- **Swipe:** Start-to-end swipe runs `deactivateRecord`; `confirmDismiss` returns `false` so removal is driven by the realtime stream, not the dismiss animation alone.

`HealthVaultController.addRecord` is now `Future<bool>` so the form can tell success from failure without guessing.

### `progress.md`
Appended a **2026-05-14 — Automated Medical Vault UI (Care)** section with the file list and behavior notes.

---

Phase complete and logged in `progress.md`. To save tokens in `.remember/remember.md`, run **(/remember)** before the next phase.

---

**User**

Review lib/core/router.dart (or the app's routing configuration). Ensure all the new Care & Health Management screens are properly routed. Implement a deep link or navigation flow so that immediately after a user finishes the 'Pet Onboarding', they are routed directly to the CareScreen with a success snackbar. Finally, scan the lib/features/care/ directory and safely delete any leftover mock files, unused assets, or deprecated UI components from the old PetSphere implementation.

---

**Cursor**

Reviewing routing, onboarding completion flow, and scanning `lib/features/care/` for removable legacy code.



Implementing onboarding → Care with query flag + snackbar, aligning the post-onboarding redirect with `/care`, tightening router documentation, and stripping unused mock getters from `care_task_type.dart`.



Removing the circular import: `router.dart` imports `onboarding_screen.dart`, so onboarding must not import `router.dart`.



Here is what was verified and changed.

### Routing (`lib/core/router.dart`)
Care is already wired consistently:
- **Shell:** `/care` → `CareScreen` (bottom nav / rail).
- **Overlays (root navigator):** `/care/nutrition` → `NutritionScreen`, `/care/medical-vault` → `MedicalVaultScreen`.

Comments were added next to those routes so the Care map is obvious. The redirect that used to send “onboarding URL but user already has pets” to **`/home`** now sends to **`/care`**, so the default post-onboarding shell tab is Care instead of Pets.

```46:95:g:\GitHub\petfolio\lib\core\router.dart
          GoRoute(
            path: '/care',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CareScreen()),
          ),
          // ...
      // Care: shell route /care; full-screen /care/nutrition, /care/medical-vault.
      // After onboarding, app navigates to /care?onboardingComplete=1 (see CareScreen).
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/care/nutrition',
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/care/medical-vault',
        builder: (context, state) => const MedicalVaultScreen(),
      ),
```

```158:166:g:\GitHub\petfolio\lib\core\router.dart
    if (loc == '/onboarding' && pets != null && pets.isNotEmpty) {
      return '/care';
    }

    return null; // no redirect
```

### Onboarding → Care + snackbar (no circular import)
`router.dart` already imports `onboarding_screen.dart`, so onboarding **must not** import `router.dart`. Completion uses a literal deep link:

```70:72:g:\GitHub\petfolio\lib\features\pet_profile\presentation\screens\onboarding_screen.dart
      if (mounted) {
        context.go('/care?onboardingComplete=1');
      }
```

`CareScreen` handles it once: snackbar, then `context.go('/care')` to clear the query.

```31:66:g:\GitHub\petfolio\lib\features\care\presentation\screens\care_screen.dart
class _CareScreenState extends ConsumerState<CareScreen> {
  bool _outdoor = false;
  bool _onboardingSuccessHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_onboardingSuccessHandled) return;
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['onboardingComplete'] != '1') return;
    _onboardingSuccessHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pet = ref.read(activePetControllerProvider);
      final name = pet?.name.trim();
      final msg = (name != null && name.isNotEmpty)
          ? 'Pet setup complete — welcome! Start tracking daily care for $name here.'
          : 'Pet setup complete — welcome! Start tracking daily care here.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      if (!mounted) return;
      if (GoRouterState.of(context).uri.queryParameters['onboardingComplete'] == '1') {
        context.go('/care');
      }
    });
  }
```

**Deep link for QA:** open `/care?onboardingComplete=1` while logged in with a pet — you should get the same snackbar once, then the URL normalizes to `/care`.

### `lib/features/care/` cleanup
There were **no** extra mock-only screens or assets in that tree. The only clear legacy was **`care_task_type.dart`**: unused “demo” `label` / `sublabel` / color getters (nothing referenced them). The enum is still required by `checklist_repository.dart`, `care_controller.dart`, and `care_screen.dart` for the three checklist dimensions (`feed` / `walk` / `med`).

```1:5:g:\GitHub\petfolio\lib\features\care\data\models\care_task_type.dart
enum CareTaskType {
  feed,
  walk,
  med,
}
```

### `progress.md`
Logged this pass at the top of the log.

---

Phase complete and logged in `progress.md`. To save tokens in `.remember/remember.md`, run **(/remember)** before the next phase.

