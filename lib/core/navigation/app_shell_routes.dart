import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/care/presentation/screens/medical_vault_screen.dart';
import '../../features/care/presentation/screens/nutrition_screen.dart';
import '../../features/care/presentation/screens/walk_tracking_screen.dart';
import '../../features/communities/data/models/community.dart';
import '../../features/communities/presentation/screens/communities_screen.dart';
import '../../features/communities/presentation/screens/community_detail_screen.dart';
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

ShellRoute appShellRoute() => ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HubHomeScreen()),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotificationsScreen(showHeader: false)),
        ),
        GoRoute(
          path: '/activity',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ActivityScreen(showHeader: false)),
        ),
        GoRoute(
          path: '/me',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MeScreen()),
        ),
        GoRoute(
          path: '/care',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CareScreen()),
        ),
        GoRoute(
          path: '/care/nutrition',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NutritionScreen()),
        ),
        GoRoute(
          path: '/care/health',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MedicalVaultScreen()),
        ),
        GoRoute(
          path: '/care/walk',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: WalkTrackingScreen()),
        ),
        GoRoute(
          path: '/care/appointments',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AppointmentsScreen()),
        ),
        GoRoute(
          path: '/social',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SocialScreen()),
        ),
        GoRoute(
          path: '/social/stories',
          pageBuilder: (context, state) {
            final petId = state.uri.queryParameters['petId'] ?? '';
            return NoTransitionPage(child: StoryViewerScreen(initialPetId: petId));
          },
        ),
        GoRoute(
          path: '/social/communities',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CommunitiesScreen()),
          routes: [
            GoRoute(
              path: ':communityId',
              pageBuilder: (context, state) {
                final extra = state.extra;
                return NoTransitionPage(
                  child: extra is Community
                      ? CommunityDetailScreen(community: extra)
                      : const Scaffold(
                          body: Center(child: Text('Community not found')),
                        ),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/social/profile/me',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: _MePetProfileTab()),
        ),
        GoRoute(
          path: '/matching',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MatchingScreen()),
        ),
        GoRoute(
          path: '/matching/inbox',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MatchesInboxScreen()),
        ),
        GoRoute(
          path: '/matching/liked',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MatchLikedScreen()),
        ),
        GoRoute(
          path: '/marketplace',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MarketplaceScreen()),
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
    return SocialProfileScreen(petId: pet.id);
  }
}
