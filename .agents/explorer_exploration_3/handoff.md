# Handoff Report - Home Feature Optimization Plan

## 1. Observation
During the read-only investigation of the `home` feature under `lib/features/home/` and surrounding controllers/routing configurations, the following specific code locations and behaviors were observed:

### A. Root-Level Over-watching and Unnecessary Rebuilds
In `lib/features/home/presentation/screens/hub_home_screen.dart` (lines 72-100):
```dart
    final activePet = ref.watch(activePetControllerProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activePet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        body: const Center(child: TailWagLoader()),
      );
    }

    final streakAsync = ref.watch(careStreakRealtimeProvider(activePet.id));
    final streak = streakAsync.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );

    final todayTasksAsync = ref.watch(
      careDashboardProvider.select((s) => s.todayTasks),
    );
```
- **Line 72**: Watching `activePetControllerProvider` (which returns the entire `Pet?` object) at the root level of `HubHomeScreen` causes the entire dashboard screen (including static sections like quick actions, carousels, and deals) to rebuild whenever any minor property of the pet object (e.g. weight, bio, gender, isPublic) is updated.
- **Line 90-91**: Watching `careDashboardProvider.select((s) => s.todayTasks)` at the root level forces a complete screen rebuild whenever a care task is completed or updated, despite the fact that only the Care tile inside the Bento Grid and the header actually display task completion progress.

### B. Redundant Supabase Realtime Subscription
- **Line 84**: `HubHomeScreen` calls `ref.watch(careStreakRealtimeProvider(activePet.id))` to subscribe directly to the `care_streaks` database table stream.
- However, in `lib/features/care/presentation/controllers/care_dashboard_controller.dart` (lines 105-106):
  ```dart
      final streakState =
          _streakAsync(ref.watch(careStreakRealtimeProvider(petId)));
  ```
  `CareDashboard` is already listening to the same `careStreakRealtimeProvider` stream and updating its own state. It exposes this via the `streak` field in `DailyRoutineState`. Subscribing to it again in `HubHomeScreen` results in duplicate WebSocket subscriptions and connection overhead.

### C. Missing Error Fallback UI
- In `hub_home_screen.dart` (lines 77-82):
  ```dart
      if (activePet == null) {
        return Scaffold(
          backgroundColor: pt.surface1,
          body: const Center(child: TailWagLoader()),
        );
      }
  ```
  If `petListProvider` fails to load (e.g., due to a network disconnect or auth failure during a JWT refresh), the user is left stranded on an infinite `TailWagLoader` spinning screen, with no indication of error or a "Retry" button.

### D. Hardcoded Bento Grid Layout
- In `hub_home_screen.dart` (lines 638-662):
  ```dart
  class _BentoGrid extends StatelessWidget {
    ...
    @override
    Widget build(BuildContext context) {
      const gap = 12.0;
      const rowH = 148.0;
      const careH = rowH * 2 + gap;
  ```
  The Bento grid is implemented with absolute heights and a fixed two-column layout. When viewed on wider mobile displays or tablets (where width >= 720), the layout stays locked in the narrow 2-column format, leaving massive blank spaces on the sides.

### E. Scroll Overflow & Redirection in All Features Sheet
- In `lib/features/home/presentation/widgets/all_features_sheet.dart` (lines 177-186):
  ```dart
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
              ),
  ```
  - **Line 180**: `physics: const NeverScrollableScrollPhysics()` prevents the grid from scrolling. If the bottom sheet is opened in landscape mode or on a screen with constrained vertical space, the sheet will overflow and clip items without scroll accessibility.
  - **Line 182**: `crossAxisCount: 2` is hardcoded. On wider screens, this makes the buttons stretch horizontally to an extreme ratio.
  - **Line 85**:
    ```dart
    route: '/care/medical-vault',
    ```
    This route triggers a redirect in `lib/core/navigation/router_notifier.dart` (line 45: `if (loc == '/care/medical-vault') return '/care/health';`), adding an extra redirect hop when it could navigate directly to `/care/health`.

---

## 2. Logic Chain
1. **Observation A & B**: `HubHomeScreen` watches the entire `activePetControllerProvider` and `careDashboardProvider` select `todayTasks` at the root, and registers a duplicate WebSocket subscription to `careStreakRealtimeProvider(activePet.id)`.
2. **Reasoning**: If a user completes a care task, `todayTasks` changes. This triggers a rebuild of `HubHomeScreen` which in turn rebuilds static UI widgets like `_DealsSection` and `_SpotlightCarousel`. Furthermore, the duplicate subscription wastefully establishes another realtime channel when the data is already cached inside `careDashboardProvider`.
3. **Conclusion**: We should refactor the subscriptions so that `HubHomeScreen` only watches `activePetIdProvider` at the root level, and delegate granular provider watches (with selectors) to isolated child widgets (`_WaveHeroSection`, `_PetHeroCard`, `_CareTile`, and `_QuickActionsRow`).

4. **Observation C**: If `petListProvider` goes into an error state, `activePet` remains null.
5. **Reasoning**: Without check/handling of the error state in the home screen, the UI is stuck in `TailWagLoader` forever.
6. **Conclusion**: We should watch `petListProvider` state using `.when` or checking `.hasError` to show a proper error UI with a retry option.

7. **Observation D**: Bento Grid uses hardcoded layout values suited for small mobile screens.
8. **Reasoning**: Widescreen layouts require columns to span horizontally rather than vertically stretching or squeezing.
9. **Conclusion**: Refactor `_BentoGrid` to adapt based on screen width: on narrow screens, keep the 2-column grid; on wider screens (width >= 720px), rearrange the tiles into a 3-column layout (CareTile in Col 1; PawsFeed/Market stacked in Col 2; Match/Vet stacked in Col 3).

10. **Observation E**: `AllFeaturesSheet` blocks grid scrolling, uses a hardcoded 2-column count, and navigates to a redirect route.
11. **Reasoning**: Disabling scroll causes height overflow errors. Hardcoded grid columns lead to wide stretches on desktop. Direct routes avoid GoRouter processing delays.
12. **Conclusion**: Enable scroll physics, dynamically set `crossAxisCount` based on width (e.g. 4 for wide, 3 for tablet, 2 for mobile), and update the route to `/care/health`.

---

## 3. Caveats
- **No Caveats**: All relevant files, paths, and configurations were fully investigated.

---

## 4. Conclusion
The current `home` feature is presentation-only but suffers from unnecessary rebuilds, redundant Supabase subscriptions, poor error recovery, and suboptimal responsiveness.
Applying the following migration plan will optimize performance, resource usage, and responsiveness:

### Migration Plan (Step-by-Step)

#### Phase 1: Rebuild & Subscription Isolation
1. **Refactor `HubHomeScreen`**:
   - Change the root build method to watch `activePetIdProvider` instead of `activePetControllerProvider`.
   - Use `ref.watch(petListProvider)` to determine load states:
     ```dart
     final petListAsync = ref.watch(petListProvider);
     return petListAsync.when(
       data: (pets) {
         if (pets.isEmpty) return const Scaffold(body: Center(child: Text('No pets found')));
         final activePetId = ref.watch(activePetIdProvider);
         if (activePetId == null) return const Scaffold(body: Center(child: TailWagLoader()));
         return _buildHomeScreen(context, ref); // Render the CustomScrollView shell
       },
       loading: () => const Scaffold(body: Center(child: TailWagLoader())),
       error: (err, stack) => _HomeErrorView(error: err), // Renders with retry option
     );
     ```
2. **Granularize `_WaveHeroSection`**:
   - Convert `_WaveHeroSection` to a `ConsumerWidget`.
   - Read the active pet details: `final pet = ref.watch(activePetControllerProvider)!;`
   - Select streak and tasks from the cache:
     ```dart
     final todayTasks = ref.watch(careDashboardProvider.select((s) => s.todayTasks.valueOrNull ?? []));
     final doneTasks = todayTasks.where((t) => t.isCompleted).length;
     final totalTasks = todayTasks.length;
     final streak = ref.watch(careDashboardProvider.select((s) => s.streak.valueOrNull?.currentStreak ?? 0));
     ```
3. **Granularize `_PetHeroCard`**:
   - Convert to a `ConsumerWidget`.
   - Retrieve tasks and streak using selectors on `careDashboardProvider` (reusing the logic above).
4. **Granularize `_CareTile` (inside `_BentoGrid`)**:
   - Convert `_CareTile` to a `ConsumerWidget`.
   - Read tasks and streak using selectors from `careDashboardProvider`.
   - Remove these parameters from `_BentoGrid` so `_BentoGrid` remains static.
5. **Optimize `_QuickActionsRow`**:
   - Extract `petName` via selector:
     ```dart
     final petName = ref.watch(activePetControllerProvider.select((p) => p?.name ?? ''));
     ```

#### Phase 2: Widescreen Bento Grid Responsiveness
1. Update `_BentoGrid.build` to adjust based on width (e.g. `final isWide = MediaQuery.sizeOf(context).width >= 720;`):
   - **Mobile Layout**: Keep existing column setup.
   - **Widescreen Layout**:
     ```dart
     Row(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         Expanded(child: _CareTile(...)),
         const SizedBox(width: gap),
         Expanded(
           child: Column(
             children: [
               Expanded(child: _BentoTile(label: 'PawsFeed', ...)),
               const SizedBox(height: gap),
               Expanded(child: _BentoTile(label: 'Market', ...)),
             ],
           ),
         ),
         const SizedBox(width: gap),
         Expanded(
           child: Column(
             children: [
               Expanded(child: _BentoTile(label: 'Match', ...)),
               const SizedBox(height: gap),
               Expanded(child: _BentoTile(label: 'Vet', ...)),
             ],
           ),
         ),
       ],
     );
     ```

#### Phase 3: All Features Sheet Improvements
1. Remove `physics: NeverScrollableScrollPhysics()` from `GridView.builder` in `AllFeaturesSheet`. Wrap the modal layout in a scrollable container or allow grid scroll.
2. Calculate column counts dynamically:
   ```dart
   final width = MediaQuery.sizeOf(context).width;
   final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
   ```
3. Update route mapping inside `AllFeaturesSheet._features`:
   ```dart
   route: '/care/health', // instead of '/care/medical-vault'
   ```

---

## 5. Verification Method
After applying these changes, verification can be performed as follows:

### Step 1: Code Verification & Dependency Mapping
Inspect the import statements and watch lists of `hub_home_screen.dart` to verify that:
1. No top-level watch points exist for `careStreakRealtimeProvider`.
2. Rebuild prints inside `DealsSection` and `SpotlightCarousel` do not trigger when toggling tasks in the Care screen.

### Step 2: Running Unit & Widget Tests
Execute the flutter test commands to ensure no router or screen transitions break:
```bash
flutter test test/features/home/hub_home_screen_test.dart
```

### Step 3: Network Diagnostics
Inspect Supabase client logs (or WebSockets inspector in Flutter DevTools) when logging into the application:
1. Verify that only a single WebSocket channel subscription is opened for `care_streaks` (originating from `CareDashboard`).
2. Verify that changing the active pet closes the previous subscription and starts the new one.
