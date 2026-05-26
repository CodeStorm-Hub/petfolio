import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_colors.dart';

import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/registration_screen.dart';
import '../features/care/presentation/screens/care_screen.dart';
import '../features/care/presentation/screens/medical_vault_screen.dart';
import '../features/care/presentation/screens/nutrition_screen.dart';
import '../features/marketplace/data/models/marketplace_order.dart';
import '../features/marketplace/data/models/product.dart';
import '../features/marketplace/presentation/screens/cart_screen.dart';
import '../features/marketplace/presentation/screens/customer/buyer_order_detail_screen.dart';
import '../features/marketplace/presentation/screens/customer/buyer_order_list_screen.dart';
import '../features/marketplace/presentation/screens/customer/shop_storefront_screen.dart';
import '../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../features/marketplace/presentation/screens/order_confirmation_screen.dart';
import '../features/marketplace/presentation/screens/product_detail_screen.dart';
import '../features/marketplace/presentation/screens/vendor/add_edit_product_screen.dart';
import '../features/marketplace/presentation/screens/vendor/seller_dashboard_screen.dart';
import '../features/marketplace/presentation/screens/vendor/shop_setup_screen.dart';
import '../features/admin/presentation/controllers/admin_auth_controller.dart';
import '../features/admin/presentation/screens/admin_screen.dart';
import '../features/marketplace/presentation/screens/vendor/edit_shop_screen.dart';
import '../features/marketplace/presentation/screens/vendor/manual_kyc_screen.dart';
import '../features/marketplace/presentation/screens/vendor/stripe_onboarding_screen.dart';
import '../features/marketplace/presentation/screens/vendor/vendor_order_detail_screen.dart';
import '../features/marketplace/presentation/screens/vendor/vendor_order_queue_screen.dart';
import '../features/marketplace/presentation/screens/vendor/vendor_product_list_screen.dart';
import '../features/matching/presentation/screens/chat_screen.dart';
import '../features/matching/presentation/screens/matches_inbox_screen.dart';
import '../features/matching/presentation/screens/matching_screen.dart';
import 'package:petfolio/core/domain/controllers/pet_list_controller.dart';
import '../features/pet_profile/presentation/screens/manage_pets_screen.dart';
import '../features/pet_profile/presentation/screens/edit_profile_screen.dart';
import '../features/pet_profile/presentation/screens/onboarding_screen.dart';
import '../features/pet_profile/presentation/screens/pet_profile_screen.dart';
import '../features/social/data/models/feed_post.dart';
import '../features/social/presentation/screens/create_post_screen.dart';
import '../features/social/presentation/screens/create_story_screen.dart';
import '../features/social/presentation/screens/notifications_screen.dart';
import '../features/social/presentation/screens/post_detail_screen.dart';
import '../features/social/presentation/screens/social_profile_screen.dart';
import '../features/social/presentation/screens/social_screen.dart';
import '../features/social/presentation/screens/story_viewer_screen.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PetProfileScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/care',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CareScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SocialScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matching',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MatchingScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/marketplace',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MarketplaceScreen()),
              ),
            ],
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
        path: '/marketplace/orders/:id',
        builder: (context, state) => BuyerOrderDetailScreen(
          orderId: state.pathParameters['id']!,
          order: state.extra as MarketplaceOrder?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/orders',
        builder: (context, state) => const BuyerOrderListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile/orders/:id',
        builder: (context, state) => BuyerOrderDetailScreen(
          orderId: state.pathParameters['id']!,
          order: state.extra as MarketplaceOrder?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/shop/:id',
        builder: (context, state) => ShopStorefrontRoute(
          shopId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/setup',
        builder: (context, state) => const ShopSetupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/onboarding',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          return StripeOnboardingScreen(accountLinkUrl: url);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/edit-shop',
        builder: (context, state) => const EditShopScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/kyc',
        builder: (context, state) => const ManualKycScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/products',
        builder: (context, state) => const VendorProductListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/products/:id/edit',
        builder: (context, state) => AddEditProductScreen(
          product: state.extra as Product?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/orders',
        builder: (context, state) => const VendorOrderQueueScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/seller/orders/:id',
        builder: (context, state) => VendorOrderDetailScreen(
          orderId: state.pathParameters['id']!,
          order: state.extra as MarketplaceOrder?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/social/create-story',
        builder: (context, state) => const CreateStoryScreen(),
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
        path: '/social/stories',
        builder: (context, state) {
          final petId = state.uri.queryParameters['petId'] ?? '';
          return StoryViewerScreen(initialPetId: petId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/matching/inbox',
        builder: (context, state) => const MatchesInboxScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/matching/chat/:threadId',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final petNameRaw = query['petName'];
          return ChatScreen(
            threadId: state.pathParameters['threadId']!,
            actorPetId: query['actorPetId'] ?? '',
            matchId: query['matchId'],
            otherPetName: petNameRaw != null
                ? Uri.decodeComponent(petNameRaw)
                : 'Match',
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/pet/:petId/edit',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final pets = ref.read(petListProvider).value ?? [];
          for (final p in pets) {
            if (p.id == petId) return EditProfileScreen(pet: p);
          }
          return const _PetEditMissingScreen();
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
        // Auth status truly flipped — invalidate so petListProvider and
        // isAdminProvider re-run with the new (or absent) user.
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

    // ── Not logged in → only /login and /register are allowed ────────
    if (!isLoggedIn) {
      return (loc == '/login' || loc == '/register') ? null : '/login';
    }

    // ── Logged in on an auth screen → leave ─────────────────────────
    if (loc == '/login' || loc == '/register') return '/home';

    // ── Logged in but no pets → go to /onboarding ───────────────────
    // Only redirect when the pet list has finished loading AND is empty,
    // so we don't flash the onboarding screen on cold start.
    final pets = _ref.read(petListProvider).value;
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

    // ── Admin route — only users with role=admin in appMetadata ─────────────
    if (loc.startsWith('/admin')) {
      final isAdmin = _ref.read(isAdminProvider);
      if (!isAdmin) return '/home';
    }

    return null; // no redirect
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigator keys
// ─────────────────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — adaptive nav (bottom bar ≤ 599 dp, rail ≥ 600 dp)
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    _NavDestination(icon: Icons.pets_outlined, activeIcon: Icons.pets, label: 'Pets'),
    _NavDestination(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department, label: 'Care'),
    _NavDestination(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Social'),
    _NavDestination(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Match'),
    _NavDestination(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Market'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              _WideNavRail(
                selectedIndex: selectedIndex,
                destinations: _destinations,
                onSelect: _onSelect,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 0,
              child: navigationShell,
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: _FloatingNav(
                selectedIndex: selectedIndex,
                destinations: _destinations,
                onSelect: _onSelect,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetEditMissingScreen extends StatelessWidget {
  const _PetEditMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pet not found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Pets'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ─── Tab accent colors (matches design system pillar colors) ─────────────────
const _tabColors = [
  AppColors.tangerine,  // Pets
  AppColors.sunny,      // Care
  AppColors.poppy,      // Social
  AppColors.lilac,      // Match
  AppColors.mint,       // Market
];

// ─── Floating pill bottom nav ─────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface0D : AppColors.surface0;
    final border = isDark ? AppColors.lineD : AppColors.line;
    final shadowColor = isDark ? AppColors.shadowE3D : AppColors.shadowE3L;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Sliding focus background window
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment(
              -1.0 + (2.0 * selectedIndex / (destinations.length - 1)),
              0.0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1.0 / destinations.length,
              heightFactor: 1.0,
              child: Center(
                child: Container(
                  height: 40,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(_tabColors[selectedIndex].withAlpha(36), Colors.transparent),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          // Foreground icons
          Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavTab(
                    destination: destinations[i],
                    isSelected: i == selectedIndex,
                    accentColor: _tabColors[i],
                    isDark: isDark,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unselectedColor = isDark ? AppColors.ink500D : AppColors.ink500;
    final iconColor = isSelected ? accentColor : unselectedColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Icon(
              isSelected ? destination.activeIcon : destination.icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: iconColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wide nav rail ───────────────────────────────────────────────────────────

class _WideNavRail extends StatelessWidget {
  const _WideNavRail({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_NavDestination> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: isDark ? AppColors.surface0D : AppColors.surface0,
      indicatorColor: Colors.transparent,
      onDestinationSelected: onSelect,
      destinations: [
        for (var i = 0; i < destinations.length; i++)
          NavigationRailDestination(
            padding: EdgeInsets.zero,
            icon: Icon(destinations[i].icon,
                color: selectedIndex == i ? _tabColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500)),
            selectedIcon: Icon(destinations[i].activeIcon, color: _tabColors[i]),
            label: Text(
              destinations[i].label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w500,
                color: selectedIndex == i ? _tabColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
              ),
            ),
          ),
      ],
    );
  }
}
