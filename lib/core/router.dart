import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_routes.dart';
import '../features/appointments/appointment_routes.dart';
import '../features/auth/auth_routes.dart';
import '../features/care/care_routes.dart';
import '../features/care/presentation/screens/care_screen.dart';
import '../features/marketplace/marketplace_routes.dart';
import '../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../features/matching/matching_routes.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/pet_profile/pet_profile_routes.dart';
import '../features/pet_profile/presentation/controllers/pet_list_controller.dart';
import '../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../features/social/presentation/screens/social_screen.dart';
import '../features/social/social_routes.dart';
import 'navigation/navigator_keys.dart';
import 'navigation/route_overlay_dismissal.dart';
import 'widgets/app_shell.dart';
import '../features/admin/presentation/controllers/admin_auth_controller.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => _RouterErrorScreen(
      location: state.uri.toString(),
    ),
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
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
      ...authRoutes(),
      ...petProfileRoutes(rootNavigatorKey),
      ...careRoutes(rootNavigatorKey),
      ...appointmentRoutes(rootNavigatorKey),
      ...socialRoutes(rootNavigatorKey),
      ...matchingRoutes(rootNavigatorKey),
      ...marketplaceRoutes(rootNavigatorKey),
      ...adminRoutes(rootNavigatorKey),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  String? _lastDismissedLocation;

  _RouterNotifier(this._ref) {
    _ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (previous != next) {
        _ref.invalidate(petListProvider);
        _ref.invalidate(isAdminProvider);
      }
      notifyListeners();
    });
    _ref.listen(petListProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _ref.read(isLoggedInProvider);
    final loc = state.matchedLocation;
    final path = state.uri.path;

    if (_lastDismissedLocation != loc) {
      _lastDismissedLocation = loc;
      dismissRootOverlayRoutes(rootNavigatorKey);
    }

    if (path == '/' || path.isEmpty) {
      return isLoggedIn ? '/home' : '/login';
    }

    if (loc == '/pets') return '/home';
    if (loc == '/shop') return '/marketplace';

    if (!isLoggedIn) {
      return (loc == '/login' || loc == '/register') ? null : '/login';
    }

    if (loc == '/login' || loc == '/register') return '/home';

    final pets = _ref.read(petListProvider).value;
    if (pets != null && pets.isEmpty && loc != '/onboarding') {
      return '/onboarding';
    }

    if (loc == '/onboarding' && pets != null && pets.isNotEmpty) {
      final mode = state.uri.queryParameters['mode'];
      if (mode != 'add') return '/care';
    }

    if (loc.startsWith('/admin')) {
      final isAdmin = _ref.read(isAdminProvider);
      if (!isAdmin) return '/home';
    }

    return null;
  }
}

class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
