import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';


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
import '../features/pet_profile/presentation/controllers/pet_list_controller.dart';
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

import 'package:petfolio/core/widgets/pet_avatar.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import 'package:petfolio/features/matching/presentation/matching_navigation.dart';
import 'package:petfolio/features/matching/presentation/widgets/match_preferences_sheet.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/cart_controller.dart';
import 'package:petfolio/core/theme/theme.dart';

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
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// AppShell — adaptive nav (bottom bar ≤ 599 dp, rail ≥ 600 dp)
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    _NavDestination(icon: Icons.pets_outlined, activeIcon: Icons.pets, label: 'Pets', path: '/home'),
    _NavDestination(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department, label: 'Care', path: '/care'),
    _NavDestination(icon: Icons.favorite_border, activeIcon: Icons.favorite, label: 'Social', path: '/social'),
    _NavDestination(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Match', path: '/matching'),
    _NavDestination(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Market', path: '/marketplace'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _WideNavRail(
              selectedIndex: selectedIndex,
              destinations: _destinations,
              onSelect: (i) => context.go(_destinations[i].path),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 0,
                    bottom: 0,
                    child: child,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _AppShellHeader(selectedIndex: selectedIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            top: 0,
            bottom: 0,
            child: child,
          ),
          // Fixed wavy header at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _AppShellHeader(selectedIndex: selectedIndex),
          ),
          // Floating pill bottom nav, raised above system home indicator
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
            child: _FloatingNav(
              selectedIndex: selectedIndex,
              destinations: _destinations,
              onSelect: (i) => context.go(_destinations[i].path),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppShellHeader extends ConsumerWidget {
  const _AppShellHeader({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);

    String eyebrow = 'ACTIVE PET';
    switch (selectedIndex) {
      case 0:
        eyebrow = 'ACTIVE PET';
        break;
      case 1:
        eyebrow = activePet != null ? 'CARE · ${activePet.name.toUpperCase()}' : 'CARE';
        break;
      case 2:
        eyebrow = 'PAWSFEED';
        break;
      case 3:
        eyebrow = 'MATCH · NEARBY';
        break;
      case 4:
        eyebrow = 'SHOP FOR';
        break;
    }

    Widget trailingActions = const SizedBox.shrink();
    switch (selectedIndex) {
      case 0: // Home
        trailingActions = Row(
          children: [
            _HeaderIconBtn(
              icon: Icons.notifications_rounded,
              onTap: () => context.push('/social/notifications'),
            ),
            const SizedBox(width: 8),
            _HeaderIconBtn(
              icon: Icons.settings_rounded,
              onTap: () => context.push('/pets/manage'),
            ),
          ],
        );
        break;
      case 1: // Care
        trailingActions = Consumer(
          builder: (context, ref, child) {
            final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
            return _HeaderIconBtn(
              icon: isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            );
          },
        );
        break;
      case 2: // Social
        trailingActions = Row(
          children: [
            _HeaderIconBtn(
              icon: Icons.search,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _HeaderIconBtn(
              icon: Icons.send_rounded,
              onTap: () => context.push('/matching/inbox'),
            ),
          ],
        );
        break;
      case 3: // Match
        trailingActions = Row(
          children: [
            _HeaderIconBtn(
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => openMatchesInbox(context),
            ),
            const SizedBox(width: 8),
            _HeaderIconBtn(
              icon: Icons.tune_rounded,
              onTap: () => MatchPreferencesSheet.show(context),
            ),
          ],
        );
        break;
      case 4: // Market
        trailingActions = Consumer(
          builder: (context, ref, child) {
            final cart = ref.watch(cartProvider);
            return GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: 560),
                builder: (ctx) => const CartDrawer(),
              ),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.tangerine,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.tangerine700, offset: Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.poppy,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cream, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cart.itemCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
        break;
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = topPadding + 76.0;

    return Container(
      color: Colors.transparent,
      height: headerHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => PetSwitcherSheet.show(context),
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(56),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activePet != null) ...[
                      PetAvatar(
                        imageUrl: activePet.avatarUrl,
                        species: activePet.speciesEnum,
                        size: PetAvatarSize.sm,
                        showRing: true,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              activePet?.name ?? (selectedIndex == 4 ? 'Market' : 'PetFolio'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            trailingActions,
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(56),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
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
    required this.path,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
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
      child: Row(
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
    final softColor = Color.alphaBlend(accentColor.withAlpha(36), Colors.transparent);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? softColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
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
