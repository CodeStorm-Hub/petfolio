# Handoff Report: Profile Feature Investigation

This report details the architectural, database, and UI/UX analysis of the `profile` feature in PetFolio, including a proposed migration plan.

---

## 1. Observation

During read-only inspection of the codebase, the following was observed:

### Screen Structure and Routing
- `MeScreen` (`lib/features/profile/presentation/screens/me_screen.dart`) is a stateless wrapper that directly returns `AccountScreen` (line 11):
  ```dart
  @override
  Widget build(BuildContext context) => const AccountScreen();
  ```
- `AccountScreen` (`lib/features/profile/presentation/screens/account_screen.dart`) is a `ConsumerWidget` rendering a `CustomScrollView` with setting options (My Pets, Account, Store, Social, Appearance, Help, etc.).
- There is a completely unused screen, `SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`), which is not registered in `settings_routes.dart` or the main router (`lib/core/router.dart`).

### Wide Screen & Responsiveness
- `AccountScreen` limits its layout to `640px` and centers it on wide displays (lines 128–135):
  ```dart
  if (isWide) {
    scrollView = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: scrollView,
      ),
    );
  }
  ```
- The global `AppShellHeader` (`lib/core/widgets/app_shell.dart`) overlays the content via a `Stack` and stretches to the full width of the screen (lines 584–609):
  ```dart
  SizedBox(
    height: topPadding + 76.0,
    child: DecoratedBox(
      ...
  ```
- A syntax error was observed in `lib/core/widgets/section_header.dart` on line 29:
  ```dart
  ?action,
  ```

### State Management & Layers
- The `profile` feature contains no `data` or `domain` layers, only `presentation/screens/`.
- The database table `public.users` (`supabase/schema.sql`, lines 24–33) holds columns for `username`, `display_name`, `avatar_url`, `bio`, and `location`. Currently, this table is never queried or mutated by the client app.
- `AccountScreen` reads `themeProvider` (generated) for theme toggling, and `authRepositoryProvider` (manual manual `Provider<AuthRepository>`) for signing out.

---

## 2. Logic Chain

From the observations above, we establish the following logic:

### UI/UX Responsiveness Issue
- **Premise**: `AccountScreen` centers its scrollable settings column within a `640px` constraint on screens wider than `600px`.
- **Premise**: `AppShellHeader` stretches to the full width of the window/pane.
- **Inference**: On wide displays (e.g., 1000px+), the header controls (like the active pet switcher on the left and theme toggle on the right) align to the outer window edges (18px padding), whereas the body content aligns to a centered 640px column. This causes a major visual alignment mismatch between the header controls and the settings tiles.

### Code Redundancy and Duplication
- **Premise**: `SettingsScreen` is completely unused in routing.
- **Premise**: `SettingsScreen` defines duplicate UI widgets, layout code, list tiles, and groups that are highly redundant with those in `AccountScreen`.
- **Inference**: The `settings` feature directory and `SettingsScreen` are obsolete. They should be deleted to prevent confusion and code bloat.

### Architectural Layering Needs
- **Premise**: Currently, the profile feature is presentation-only because it acts as a navigation launcher.
- **Premise**: The `public.users` table contains rich profile data (`username`, `display_name`, `avatar_url`, `bio`, `location`), but it is not currently displayed, edited, or fetched.
- **Premise**: If we show a profile card (like the one in `SettingsScreen`) or allow users to update their profile settings (display name, bio, location, avatar), we will need database reads and writes.
- **Inference**: Maintaining a presentation-only structure is not ideal long-term. We must establish a layered architecture (presentation, domain, data) to handle user profile state management, repository requests, and data models.

---

## 3. Caveats

- We did not execute unit tests or compile the code due to CLI command authorization timeout.
- The syntax anomaly in `lib/core/widgets/section_header.dart` (`?action,`) may already prevent compilation unless it is resolved or conditionally parsed.

---

## 4. Conclusion

The `profile` feature requires:
1. **Responsiveness Optimization**: Synchronize horizontal alignment between the `AppShellHeader` and `AccountScreen` when `isWide` is true.
2. **Feature Consolidation**: Remove the unused `settings_screen.dart` and merge necessary route layouts.
3. **Layered Refactoring**: Define a data/domain model for user profiles, fetch database records from `public.users`, and create a code-generated Riverpod controller (`profileControllerProvider`) for state management.
4. **Syntax Fix**: Resolve the typo in `section_header.dart`.

---

## 5. Migration Plan

Here is the proposed step-by-step migration plan:

### Phase 1: Cleanup and Consolidate
1. **Delete Obsolete Files**: Remove `lib/features/settings/presentation/screens/settings_screen.dart`.
2. **Move Address Route**: Relocate `/settings/addresses` from `settings_routes.dart` to a unified router file or into `lib/features/profile/profile_routes.dart`.
3. **Fix Typo**: Correct `lib/core/widgets/section_header.dart` line 29:
   - Change `?action,` to `if (action != null) action,`.

### Phase 2: Establish Profile Data/Domain Layers
1. **Domain Layer**: Create `lib/features/profile/domain/models/user_profile.dart` (using `@freezed` and JSON serialization) to model the `public.users` table.
2. **Data Layer**: Create `lib/features/profile/data/repositories/profile_repository.dart` that communicates with Supabase:
   - `Future<UserProfile?> fetchProfile(String userId)`
   - `Future<void> updateProfile(UserProfile profile)`
3. **State Management**: Create `lib/features/profile/presentation/controllers/profile_controller.dart` as a code-generated notifier:
   ```dart
   @riverpod
   class UserProfileController extends _$UserProfileController {
     @override
     FutureOr<UserProfile?> build() {
       final user = ref.watch(currentUserProvider);
       if (user == null) return null;
       return ref.read(profileRepositoryProvider).fetchProfile(user.id);
     }
     
     Future<void> updateProfile(UserProfile profile) async { ... }
   }
   ```

### Phase 3: Enhance UI & Wide-Screen Layout
1. **Show User Profile Card**: Integrate a user profile card (showing avatar/initials, email, display name) at the top of `AccountScreen` using the profile controller state.
2. **Align Header**: Align `AppShellHeader` content with the 640px constraint when on wide screens:
   - In `AppShellHeader`, wrap `innerContent` in a `Center` and `ConstrainedBox(maxWidth: 640)` on wide displays to align perfectly with the centered settings columns in `AccountScreen`.

---

## 6. Verification Method

To verify these issues and proposed fixes:
1. **Inspect Header Alignment**: Run the app in a tablet/desktop simulator, navigate to `/home/me`. Observe that the active pet pill is on the far-left and the theme toggle is on the far-right, while the setting tiles are centered.
2. **Verify Compilability**: Run `flutter analyze` or `dart analyze` to identify if the typo `?action,` in `section_header.dart` throws compilation issues.
3. **Check Routing**: Inspect `lib/core/router.dart` and `lib/core/navigation/app_shell_routes.dart` to verify `SettingsScreen` is never registered.
