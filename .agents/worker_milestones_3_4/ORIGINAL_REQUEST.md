## 2026-06-28T12:20:00Z
Implement Milestone 3 (Profile Optimization) and Milestone 4 (Home Dashboard Optimization) as detailed in:
- j:\GitHub\petfolio\PROJECT.md
- j:\GitHub\petfolio\.agents\explorer_exploration_2\handoff.md (Profile)
- j:\GitHub\petfolio\.agents\explorer_exploration_3\handoff.md (Home)

Specifically, perform these steps:

For Milestone 3 (Profile):
1. Delete the obsolete file `lib/features/settings/presentation/screens/settings_screen.dart`.
2. Move the GoRoute `/settings/addresses` and the classes `_AddressManagementScreen` and `_AddressCard` from `lib/features/settings/settings_routes.dart` to a new routing file `lib/features/profile/profile_routes.dart`.
3. In `lib/core/router.dart`, import `profile_routes.dart` and register the profile routes in the list of routes (replace the import/usage of `settingsRoutes`).
4. Fix the syntax error typo in `lib/core/widgets/section_header.dart` on line 29: change `?action,` to `if (action != null) action,`.
5. Establish Profile Data/Domain Layers:
   - Create `lib/features/profile/domain/models/user_profile.dart` using `@freezed` and `@JsonSerializable` to model the `public.users` table (columns: `id`, `username`, `display_name`, `avatar_url`, `bio`, `location`, `created_at`, `updated_at`).
   - Create `lib/features/profile/data/repositories/profile_repository.dart` that fetches and updates the user profile from Supabase.
   - Create `lib/features/profile/presentation/controllers/profile_controller.dart` as a code-generated notifier using `@riverpod` to fetch/update the user profile (caching it based on the logged-in user id).
6. In `lib/features/profile/presentation/screens/account_screen.dart`, add a user profile card at the top displaying the display name, email (from auth state), and avatar/initials.
7. In `lib/core/widgets/app_shell.dart`, modify `AppShellHeader` to align with the centered 640px constraint when `isWide` is true (define `final isWide = MediaQuery.sizeOf(context).width >= 600;` and wrap `innerContent` with a `Center` and `ConstrainedBox(maxWidth: 640)` if `isWide` is true).

For Milestone 4 (Home):
1. In `lib/features/home/presentation/screens/hub_home_screen.dart`, refactor the root build method to watch `activePetIdProvider` instead of `activePetControllerProvider`. Watch `petListProvider` to handle loading/error states (rendering `TailWagLoader` for loading and a friendly error page with a retry option for errors).
2. Granularize widgets (`_WaveHeroSection`, `_PetHeroCard`, `_CareTile`, `_QuickActionsRow`) to be `ConsumerWidget`s and watch their own required sub-states (like task progress or current pet name) via Riverpod selectors, instead of passing everything down from the root build method.
3. Remove the duplicate websocket/realtime stream subscription `careStreakRealtimeProvider` from `HubHomeScreen`.
4. In `_BentoGrid` (in `hub_home_screen.dart`), support widescreen layout (width >= 720px) by arranging tiles in a 3-column layout:
   - Column 1: CareTile.
   - Column 2: Stacked PawsFeed and Market.
   - Column 3: Stacked Match and Vet.
5. In `lib/features/home/presentation/widgets/all_features_sheet.dart`:
   - Enable scrolling (remove `physics: NeverScrollableScrollPhysics()`).
   - Dynamically compute crossAxisCount: `final width = MediaQuery.sizeOf(context).width; final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);`
   - Update the route to `/care/health` instead of `/care/medical-vault`.

Validation/Code-generation:
- Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- Run static analysis: `dart analyze` to make sure there are no warnings or compilation issues.
- Run tests to verify everything passes:
  - `flutter test`

Write your changes and verification report to: j:\GitHub\petfolio\.agents\worker_milestones_3_4\handoff.md
Send a completion message when done.
