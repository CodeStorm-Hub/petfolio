import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/appointments/presentation/screens/appointments_screen.dart';
import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/care/presentation/screens/medical_vault_screen.dart';
import '../../features/care/presentation/screens/nutrition_screen.dart';
import '../../features/care/presentation/screens/walk_tracking_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/matching/presentation/screens/matching_screen.dart';
import '../../features/home/presentation/screens/hub_home_screen.dart';
import '../../features/profile/presentation/screens/me_screen.dart';
import '../../features/social/presentation/screens/notifications_screen.dart';
import '../../features/social/presentation/screens/social_screen.dart';
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
          path: '/matching',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MatchingScreen()),
        ),
        GoRoute(
          path: '/marketplace',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MarketplaceScreen()),
        ),
      ],
    );
