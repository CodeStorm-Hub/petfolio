import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/registration_screen.dart';
import '../features/care/presentation/screens/care_screen.dart';
import '../features/care/presentation/screens/medical_vault_screen.dart';
import '../features/care/presentation/screens/nutrition_screen.dart';
import '../features/marketplace/data/models/product.dart';
import '../features/marketplace/presentation/screens/cart_screen.dart';
import '../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../features/marketplace/presentation/screens/order_confirmation_screen.dart';
import '../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import '../features/pet_profile/presentation/controllers/pet_list_controller.dart';
import '../features/pet_profile/presentation/screens/manage_pets_screen.dart';
import '../features/pet_profile/presentation/screens/edit_profile_screen.dart';
import '../features/pet_profile/presentation/screens/onboarding_screen.dart';
import '../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../features/social/data/models/feed_post.dart';
import '../features/social/presentation/screens/create_post_screen.dart';
import '../features/social/presentation/screens/notifications_screen.dart';
import '../features/social/presentation/screens/post_detail_screen.dart';
import '../features/social/presentation/screens/social_profile_screen.dart';
import '../features/social/presentation/screens/social_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Router provider — must be consumed with ref.watch in the app widget.
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
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
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          // `?mode=add` means an authenticated user adding a second-or-later
          // pet from the switcher. Skip the welcome step and rebound to /care
          // (or wherever they came from) on completion.
          final mode = state.uri.queryParameters['mode'];
          return OnboardingScreen(addAnotherPet: mode == 'add');
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pets/manage',
        builder: (context, state) => const ManagePetsScreen(),
      ),

      // Care: shell route /care; full-screen /care/nutrition, /care/medical-vault.
      // After onboarding, app navigates to /care?onboardingComplete=1 (see CareScreen).
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/care/nutrition',
        builder: (context, state) => const NutritionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/care/medical-vault',
        builder: (context, state) => const MedicalVaultScreen(),
      ),

      // ── Marketplace full-screen routes (outside ShellRoute / no bottom nav) ─
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/marketplace/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
          product: state.extra as Product?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/marketplace/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/marketplace/order/:id',
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/post/:postId',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
          post: state.extra as FeedPost?,
          autofocusComment: state.uri.queryParameters['focus'] == 'true',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/profile/:petId',
        builder: (context, state) => SocialProfileScreen(
          petId: state.pathParameters['petId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pet/:petId/edit',
        builder: (context, state) {
          final pets = ref.read(petListProvider).valueOrNull ?? [];
          final pet = pets.firstWhere((p) => p.id == state.pathParameters['petId']);
          return EditProfileScreen(pet: pet);
        },
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Redirect logic
// ─────────────────────────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Re-evaluate redirects whenever auth status genuinely changes (sign-in /
    // sign-out) AND invalidate the pet list so it re-fetches for the new user.
    // We intentionally do NOT notify on every auth event (e.g. tokenRefreshed)
    // because that would put petListProvider back into AsyncLoading on each
    // ~55-minute token rotation, making all screens show a loading spinner.
    _ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (previous != next) {
        // Auth status truly flipped — invalidate so petListProvider re-runs
        // with the new (or absent) user ID.
        _ref.invalidate(petListProvider);
      }
      notifyListeners();
    });
    _ref.listen(petListProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _ref.read(isLoggedInProvider);
    final loc = state.matchedLocation;

    // ── Not logged in → only /login and /register are allowed ────────
    if (!isLoggedIn) {
      return (loc == '/login' || loc == '/register') ? null : '/login';
    }

    // ── Logged in on an auth screen → leave ─────────────────────────
    if (loc == '/login' || loc == '/register') return '/home';

    // ── Logged in but no pets → go to /onboarding ───────────────────
    // Only redirect when the pet list has finished loading AND is empty,
    // so we don't flash the onboarding screen on cold start.
    final pets = _ref.read(petListProvider).valueOrNull;
    if (pets != null && pets.isEmpty && loc != '/onboarding') {
      return '/onboarding';
    }

    // Honor "?mode=add" when an authenticated user with pets opens onboarding
    // from the switcher; otherwise bounce them back to /care so we don't show
    // the first-run welcome twice.
    if (loc == '/onboarding' && pets != null && pets.isNotEmpty) {
      final mode = state.uri.queryParameters['mode'];
      if (mode != 'add') return '/care';
    }

    return null; // no redirect
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigator keys
// ─────────────────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — adaptive nav (bottom bar ≤ 599 dp, rail ≥ 600 dp)
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavDestination(icon: Icons.pets_outlined, activeIcon: Icons.pets, label: 'Pets', path: '/home'),
    _NavDestination(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Care', path: '/care'),
    _NavDestination(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Social', path: '/social'),
    _NavDestination(icon: Icons.favorite_border_outlined, activeIcon: Icons.favorite, label: 'Match', path: '/matching'),
    _NavDestination(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Market', path: '/marketplace'),
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
                    selectedIcon: Icon(d.activeIcon),
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
              key: ValueKey<String>('shell_nav_${d.path.replaceAll('/', '_')}'),
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
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
    required this.activeIcon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
