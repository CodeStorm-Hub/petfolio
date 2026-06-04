# PetFolio Code Audit & Stability Fixes — Memory Log

**Date:** May 31, 2026  
**Architect:** Principal Mobile & Backend Architect  

This document preserves the context, logic, and solutions implemented during the systematic fix execution of the non-marketplace items from the `FULL_PROJECT_AUDIT_REPORT.md`.

---

## 1. Feature Teardown (Explicit Feature Teardown)
* **Goal:** Override Audit Items 1.1 and 1.2. Completely remove the Treat and Undo features.
* **Files Modified:**
  * [matching_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/matching/presentation/screens/matching_screen.dart)
* **Actions Taken:**
  * Removed the bone icon (`🦴`) Treat button and its stubbed snackbar handler from the swipe screen dock.
  * Removed the replay icon (`↺`) Undo button and its stubbed snackbar handler from the swipe screen dock.
  * Removed all companion margins and layout spacing associated with these buttons.

---

## 2. Database & Storage Policy (Phase 2)
* **Goal:** Implement the admin read policy for the `medical-documents` storage bucket (Audit Item 4.8).
* **Files Modified / Created:**
  * [20260531_audit_fixes.sql](file:///home/kratzer/workspace/petfolio/supabase/migrations/20260531_audit_fixes.sql) [NEW]
* **Fix details:**
  * Added a `medical-documents` bucket admin read policy.
  * Wrapped the authentication checks in a subselect `(select public.is_admin())` to force the Postgres optimizer to cache the plan and prevent severe database jank.
  ```sql
  CREATE POLICY "medical-documents: admin read"
    ON storage.objects FOR SELECT TO authenticated
    USING (
      bucket_id = 'medical-documents'
      AND (select public.is_admin())
    );
  ```

---

## 3. State Management & Lifecycle Correctness (Phase 3)
* **Goal:** Eliminate duplicate listeners and build-phase mutations inside `CareNotifier` (Audit Item 2.2).
* **Files Modified:**
  * [care_controller.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/presentation/controllers/care_controller.dart)
* **Fix details:**
  * Replaced the unsafe `ref.listen<DailyRoutineState>(careDashboardProvider, ...)` inside `build()` with `ref.watch(careDashboardProvider)`.
  * Deferred the state synchronization side effects to run inside `Future.microtask` to guarantee it does not trigger Riverpod's "mutating state during build" exceptions.
  ```dart
  @override
  CareState build() {
    final petId = arg;
    final dashboard = ref.watch(careDashboardProvider);
    Future.microtask(() {
      if (ref.mounted) {
        _onDashboardChange(dashboard);
      }
    });
    // ...
  }
  ```

---

## 4. Deep-Link Route Gating & Cold-Starts (Phase 3)
* **Goal:** Resolve deep-link race condition for the pet edit route (Audit Item 3.5).
* **Files Modified:**
  * [router.dart](file:///home/kratzer/workspace/petfolio/lib/core/router.dart)
* **Fix details:**
  * Replaced the inline `ref.read(petListProvider).value` lookup inside GoRouter's builder block with a dynamic `Consumer` that actively watches (`ref.watch`) the `petListProvider`.
  * Handled the loading, error, and data states appropriately using `AsyncValue.when` to prevent the false-positive "Pet not found" screen during cold-start deep-links.

---

## 5. Query Boundaries & Performance (Phase 3)
* **Goal:** Add limits to unbounded streams/queries (Audit Item 3.1 & 3.3) and optimize follows checks (Audit Item 3.6).
* **Files Modified:**
  * [matching_supabase_data_source.dart](file:///home/kratzer/workspace/petfolio/lib/features/matching/data/datasources/matching_supabase_data_source.dart)
  * [health_repository.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/data/repositories/health_repository.dart)
  * [health_vault_controller.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/presentation/controllers/health_vault_controller.dart)
  * [social_repository.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/data/repositories/social_repository.dart)
* **Fix details:**
  * Added `.limit(100)` boundaries to `fetchMatchesForPet` and `fetchLogsForPet` queries.
  * Added `.limit(100)` to the `medical_vault` realtime stream in `HealthVaultController`.
  * Refactored `isFollowing` to select only `follower_pet_id` instead of performing a full wildcard column select (`.select()`).

---

## 6. Rendering & UI Virtualization (Phase 4)
* **Goal:** Convert memory-heavy list instantiations to lazy virtualization (Audit Item 4.2).
* **Files Modified:**
  * [care_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/presentation/screens/care_screen.dart)
  * [matches_inbox_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/matching/presentation/screens/matches_inbox_screen.dart)
* **Fix details:**
  * Converted the main layout container of `care_screen.dart` to a `ListView.builder`.
  * Refactored the matches inbox screen to build a composite item representation, fully virtualizing the inbox messages list using `ListView.builder`.
  * Added a `mounted` guard prior to performing context layout calculations (`context.size`) inside `care_screen.dart`'s `_scrollToToday()`.

---

## 7. Social Card Actions & Stub Hiding (Phase 4)
* **Goal:** Wire up overflow menus, hide stubbed icons/actions (Audit Items 1.7, 1.4, 1.3).
* **Files Modified:**
  * [post_detail_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/post_detail_screen.dart)
  * [social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart)
  * [manage_pets_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/manage_pets_screen.dart)
* **Actions Taken:**
  * Renamed `_PostOptionsSheet` to `PostOptionsSheet` (made public) in `post_detail_screen.dart`.
  * Wired up the three-dot button in feed cards (`social_screen.dart`) to show the sheet.
  * Removed the stubbed search icon from the feed header actions.
  * Removed the unimplemented co-carer "Share access" option from the pet actions popup menu in `manage_pets_screen.dart`.

---

## 8. Robust Error Handling & Media Queries (Phase 4)
* **Goal:** Replace silent error swallowing with minimal retry blocks (Audit Item 3.4) and optimize MediaQuery subscriptions (Audit Item 4.3).
* **Files Modified:**
  * [nutrition_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/presentation/screens/nutrition_screen.dart)
  * [social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart)
  * [social_profile_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_profile_screen.dart)
  * [pet_switcher_sheet.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart)
  * [pet_profile_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/pet_profile_screen.dart)
  * [onboarding_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/onboarding_screen.dart)
* **Fix details:**
  * Implemented elegant error and retry indicators (`ref.invalidate`/`refresh`) inside the five swallowed error scenarios (Weight list, Stories, Achievements tab, Switcher sheet, and Quests card).
  * Optimized `MediaQuery.of(context)` subscriptions in `onboarding_screen.dart` and `nutrition_screen.dart` to use `MediaQuery.sizeOf(context)` and `MediaQuery.viewInsetsOf(context)` to prevent unnecessary widget rebuilds.

---

## 9. Production Crash Shield (Phase 4)
* **Goal:** Setup global crash catching (Audit Item 4.5).
* **Files Modified:**
  * [main.dart](file:///home/kratzer/workspace/petfolio/lib/main.dart)
* **Fix details:**
  * Registered unified error hooks for synchronous Widget build errors and asynchronous exceptions:
  ```dart
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };
  ```

---

## 10. Modal Bottom Sheets & Root Navigator Routing
* **Goal:** Ensure all modal bottom sheets/popups appear on top of the persistent bottom navigation bar.
* **Files Modified:**
  * [create_post_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/create_post_screen.dart)
  * [post_detail_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/post_detail_screen.dart)
  * [social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart)
  * [manage_pets_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/manage_pets_screen.dart)
  * [nutrition_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/care/presentation/screens/nutrition_screen.dart)
* **Fix details:**
  * Added `useRootNavigator: true` to the remaining `showModalBottomSheet` calls in the application context so that the modals are pushed on the root navigator instead of the GoRouter nested shell route navigator. This resolves the issue where the bottom navigation bar overlaps or obscures bottom sheets.

