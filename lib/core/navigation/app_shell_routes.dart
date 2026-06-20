import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/care/presentation/screens/medical_vault_screen.dart';
import '../../features/care/presentation/screens/nutrition_screen.dart';
import '../../features/care/presentation/screens/walk_tracking_screen.dart';
import '../../features/communities/presentation/screens/communities_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/matching/presentation/screens/match_liked_screen.dart';
import '../../features/matching/presentation/screens/matches_inbox_screen.dart';
import '../../features/matching/presentation/screens/matching_screen.dart';
import '../../features/home/presentation/screens/hub_home_screen.dart';
import '../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../features/profile/presentation/screens/me_screen.dart';
import '../../features/social/presentation/screens/notifications_screen.dart';
import '../../features/social/presentation/screens/social_profile_screen.dart';
import '../../features/social/presentation/screens/social_screen.dart';
import '../../features/social/presentation/screens/story_viewer_screen.dart';
import '../widgets/app_shell.dart';
import 'navigator_keys.dart';

StatefulShellRoute appShellRoute() => StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: globalBranchKey,
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HubHomeScreen()),
              routes: [
                GoRoute(
                  path: 'notifications',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: NotificationsScreen(showHeader: false)),
                ),
                GoRoute(
                  path: 'activity',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: ActivityScreen(showHeader: false)),
                ),
                GoRoute(
                  path: 'me',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MeScreen()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: careBranchKey,
          routes: [
            GoRoute(
              path: '/care',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CareScreen()),
              routes: [
                GoRoute(
                  path: 'nutrition',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: NutritionScreen()),
                ),
                GoRoute(
                  path: 'health',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MedicalVaultScreen()),
                ),
                GoRoute(
                  path: 'walk',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: WalkTrackingScreen()),
                ),
                GoRoute(
                  path: 'appointments',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: AppointmentsScreen()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: socialBranchKey,
          routes: [
            GoRoute(
              path: '/social',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SocialScreen()),
              routes: [
                GoRoute(
                  path: 'stories',
                  pageBuilder: (context, state) {
                    final petId = state.uri.queryParameters['petId'] ?? '';
                    return NoTransitionPage(child: StoryViewerScreen(initialPetId: petId));
                  },
                ),
                GoRoute(
                  path: 'communities',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: CommunitiesScreen()),
                ),
                GoRoute(
                  path: 'profile/me',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: _MePetProfileTab()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: matchingBranchKey,
          routes: [
            GoRoute(
              path: '/matching',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MatchingScreen()),
              routes: [
                GoRoute(
                  path: 'inbox',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MatchesInboxScreen()),
                ),
                GoRoute(
                  path: 'liked',
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: MatchLikedScreen()),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: marketplaceBranchKey,
          routes: [
            GoRoute(
              path: '/marketplace',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MarketplaceScreen()),
            ),
          ],
        ),
      ],
    );

class _MePetProfileTab extends ConsumerWidget {
  const _MePetProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return SocialProfileScreen(petId: pet.id, showAppBar: false);
  }
}
