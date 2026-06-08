import 'package:go_router/go_router.dart';

import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/matching/presentation/screens/matching_screen.dart';
import '../../features/home/presentation/screens/hub_home_screen.dart';
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
          path: '/care',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CareScreen()),
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
