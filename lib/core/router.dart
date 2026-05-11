import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/care/presentation/screens/care_screen.dart';
import '../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../features/social/presentation/screens/social_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PetProfileScreen()),
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
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavDestination(icon: Icons.pets, label: 'Pets', path: '/home'),
    _NavDestination(icon: Icons.favorite, label: 'Care', path: '/care'),
    _NavDestination(icon: Icons.people, label: 'Social', path: '/social'),
    _NavDestination(
        icon: Icons.favorite_border, label: 'Match', path: '/matching'),
    _NavDestination(icon: Icons.store, label: 'Market', path: '/marketplace'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].path),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}
