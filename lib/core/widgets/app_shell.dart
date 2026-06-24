import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/navigation/shell_destinations.dart';
import 'package:petfolio/core/navigation/shell_module_provider.dart';
import 'package:petfolio/features/social/presentation/controllers/notification_controller.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';
import 'package:petfolio/core/widgets/app_tutorial_overlay.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/cart_controller.dart';
import 'package:petfolio/features/marketplace/presentation/screens/marketplace_categories_screen.dart';
import 'package:petfolio/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:petfolio/features/matching/presentation/matching_navigation.dart';
import 'package:petfolio/features/matching/presentation/widgets/match_preferences_sheet.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/core/providers/shell_scroll_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

// ── App shell ─────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  bool _showTutorial = false;
  bool _tutorialChecked = false;
  GoRouterDelegate? _delegate;

  static const _branchRoots = {'/care', '/social', '/matching', '/marketplace'};

  @override
  void initState() {
    super.initState();
    _loadTutorialFlag();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newDelegate = GoRouter.of(context).routerDelegate;
    if (_delegate != newDelegate) {
      _delegate?.removeListener(_onRouteChange);
      _delegate = newDelegate;
      _delegate!.addListener(_onRouteChange);
    }
  }

  void _onRouteChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _delegate?.removeListener(_onRouteChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;
    final location = GoRouterState.of(context).matchedLocation;
    if (_branchRoots.contains(location)) {
      context.go('/home');
      return true;
    }
    return false;
  }

  Future<void> _loadTutorialFlag() async {
    final show = await shouldShowAppTutorial();
    if (mounted) {
      setState(() {
        _showTutorial = show;
        _tutorialChecked = true;
      });
    }
  }

  void _onBranchPop(BuildContext context, [Object? result]) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (_branchRoots.contains(loc)) {
      context.go('/home');
    }
  }

  String _currentLocation() =>
      _delegate?.currentConfiguration.uri.path ??
      GoRouterState.of(context).matchedLocation;

  ShellModule _currentModule(BuildContext context) =>
      moduleFromPath(_currentLocation());

  int _currentSubIndex(ShellModule module, BuildContext context) =>
      selectedSubIndex(destinationsFor(module), _currentLocation());

  void _onNavSelect(BuildContext context, ShellModule module, int i) {
    if (module != ShellModule.marketplace) {
      context.go(destinationsFor(module)[i].path);
      return;
    }
    switch (i) {
      case 1:
        MarketplaceCategoriesSheet.show(context);
        break;
      case 2:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          constraints: const BoxConstraints(maxWidth: 560),
          builder: (_) => const CartDrawer(),
        );
        break;
      default:
        context.go('/marketplace');
    }
  }

  Widget _wrapWithTutorial(Widget shell) {
    if (!_tutorialChecked || !_showTutorial) return shell;
    return Stack(
      children: [
        shell,
        Positioned.fill(
          child: AppTutorialOverlay(
            onDismiss: () => setState(() => _showTutorial = false),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final module = _currentModule(context);
    final subIndex = _currentSubIndex(module, context);
    final dests = destinationsFor(module);
    final accents = accentsFor(module);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    final cartCount = module == ShellModule.marketplace
        ? ref.watch(cartProvider).itemCount
        : 0;
    final badgeCounts = module == ShellModule.marketplace
        ? [0, 0, cartCount, 0]
        : null;

    Widget floatingNav = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: _FloatingNav(
        key: ValueKey(module),
        destinations: dests,
        selectedIndex: subIndex,
        onSelect: (i) => _onNavSelect(context, module, i),
        accentColors: accents,
        badgeCounts: badgeCounts,
      ),
    );

    final shell = widget.navigationShell;

    if (isWide) {
      return _wrapWithTutorial(
        PopScope(
          canPop: false,
          child: Scaffold(
            body: Row(
              children: [
                _WideNavRail(
                  destinations: dests,
                  accentColors: accents,
                  selectedIndex: subIndex,
                  onSelect: (i) => _onNavSelect(context, module, i),
                  module: module,
                  badgeCounts: badgeCounts,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NavigatorPopHandler(
                          onPopWithResult: (r) => _onBranchPop(context, r),
                          child: shell,
                        ),
                      ),
                      Positioned(
                        top: 0, left: 0, right: 0,
                        child: AppShellHeader(module: module, subIndex: subIndex),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (kIsWeb) {
      return _wrapWithTutorial(
        PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                Positioned.fill(
                  child: NavigatorPopHandler(
                    onPopWithResult: (r) => _onBranchPop(context, r),
                    child: shell,
                  ),
                ),
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: AppShellHeader(module: module, subIndex: subIndex),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: floatingNav,
              ),
            ),
          ),
        ),
      );
    }

    return _wrapWithTutorial(
      PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: NavigatorPopHandler(
                  onPopWithResult: (r) => _onBranchPop(context, r),
                  child: shell,
                ),
              ),
              Positioned(
                top: 0, left: 0, right: 0,
                child: AppShellHeader(module: module, subIndex: subIndex),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12 + MediaQuery.paddingOf(context).bottom,
                child: floatingNav,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class AppShellHeader extends ConsumerWidget {
  const AppShellHeader({super.key, required this.module, required this.subIndex});

  final ShellModule module;
  final int subIndex;

  static const _globalEyebrows   = ['HOME', 'ALERTS', 'ACTIVITY', 'ME'];
  static const _socialEyebrows   = ['PAWSFEED', 'STORIES', 'COMMUNITY', 'MY PET'];
  static const _matchingEyebrows = ['MATCH · NEARBY', 'MATCH · MESSAGES', 'MATCH · LIKED'];
  static const _moduleEyebrows = {
    ShellModule.care:        'CARE',
    ShellModule.marketplace: 'MARKET',
  };

  Widget _buildTrailing(BuildContext context, WidgetRef ref) {
    if (module == ShellModule.global) {
      switch (subIndex) {
        case 0: // Home
          return Row(children: [
            Consumer(builder: (context, ref, _) {
              final pet = ref.watch(activePetControllerProvider);
              if (pet == null) return const SizedBox.shrink();
              final streakAsync = ref.watch(careStreakRealtimeProvider(pet.id));
              final streak = streakAsync.maybeWhen(
                data: (s) => s.currentStreak,
                orElse: () => 0,
              );
              if (streak == 0) return const SizedBox.shrink();
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final sFill   = isDark ? Colors.white.withAlpha(48) : Colors.black.withAlpha(8);
              final sBorder = isDark ? Colors.white.withAlpha(80) : Colors.black.withAlpha(20);
              final sText   = isDark ? Colors.white : Colors.black87;
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: sBorder, width: 0.8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: sFill,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800, color: sText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _HeaderIconBtn(icon: Icons.notifications_rounded, tooltip: 'Alerts', onTap: () => context.go('/home/notifications')),
            const SizedBox(width: 8),
            _HeaderIconBtn(icon: Icons.manage_accounts_rounded, tooltip: 'Account', onTap: () => context.go('/home/me')),
          ]);
        case 1: // Alerts
          return Consumer(builder: (context, ref, _) {
            final notifs = ref.watch(notificationsProvider).value ?? [];
            final unread = notifs.where((n) => !n.isRead).length;
            if (unread == 0) return const SizedBox.shrink();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          });
        case 2: // Activity
          return _HeaderIconBtn(icon: Icons.tune_rounded, onTap: () {});
        case 3: // Me
        default:
          return Consumer(builder: (context, ref, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return _HeaderIconBtn(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            );
          });
      }
    }

    switch (module) {
      case ShellModule.care:
        return Row(children: [
          _HeaderIconBtn(
            icon: Icons.directions_walk_rounded,
            tooltip: 'Walk tracking',
            onTap: () => context.go('/care/walk'),
          ),
          const SizedBox(width: 8),
          Consumer(builder: (context, ref, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return _HeaderIconBtn(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            );
          }),
        ]);
      case ShellModule.social:
        return Row(children: [
          _HeaderIconBtn(
            icon: Icons.groups_rounded,
            tooltip: 'Communities',
            onTap: () => context.go('/social/communities'),
          ),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.search, tooltip: 'Search', onTap: () => context.push('/social/search')),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.send_rounded, tooltip: 'Direct messages', onTap: () => context.go('/matching/inbox')),
        ]);
      case ShellModule.matching:
        return Row(children: [
          if (subIndex == 0) ...[
            _HeaderIconBtn(icon: Icons.chat_bubble_outline_rounded, tooltip: 'Messages', onTap: () => openMatchesInbox(context)),
            const SizedBox(width: 8),
          ],
          _HeaderIconBtn(icon: Icons.tune_rounded, tooltip: 'Match preferences', onTap: () => MatchPreferencesSheet.show(context)),
        ]);
      case ShellModule.marketplace:
        return Consumer(builder: (context, ref, _) {
          final cart = ref.watch(cartProvider);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cFill   = isDark ? Colors.white.withAlpha(48) : Colors.black.withAlpha(8);
          final cBorder = isDark ? Colors.white.withAlpha(80) : Colors.black.withAlpha(20);
          final cIcon   = isDark ? Colors.white : Colors.black87;
          return Semantics(
            key: const ValueKey<String>('market_action_cart'),
            label: 'Cart${cart.itemCount > 0 ? ", ${cart.itemCount} items" : ""}',
            button: true,
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: 560),
                builder: (_) => const CartDrawer(),
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: cBorder, width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.shopping_bag_outlined, color: cIcon, size: 18),
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          top: -4, right: -6,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tangerine,
                              shape: cart.itemCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: cart.itemCount > 9 ? BorderRadius.circular(8) : null,
                              border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, height: 1.2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      case ShellModule.global:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final topPadding = MediaQuery.paddingOf(context).top;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHome = module == ShellModule.global && subIndex == 0;
    final scrollProgress = isHome ? ref.watch(homeScrollProgressProvider) : 0.0;
    final t = isHome ? scrollProgress : 1.0;
    final blurSigma = 6.0 + 22.0 * t;
    final veilTopAlpha   = isDark ? (55 * t).round()  : (180 * t).round();
    final veilBottomAlpha = isDark ? (18 * t).round() : (120 * t).round();
    final rimColor       = isDark ? Colors.white.withAlpha((100 * t).round())
                                  : Colors.black.withAlpha((20 * t).round());
    final separatorColor = isDark ? Colors.white.withAlpha((35 * t).round())
                                  : Colors.black.withAlpha((25 * t).round());
    final btnFill        = isDark ? Colors.white.withAlpha(55)  : Colors.black.withAlpha(8);
    final btnBorder      = isDark ? Colors.white.withAlpha(90)  : Colors.black.withAlpha(20);
    final btnIcon        = isDark ? Colors.white : Colors.black87;

    final eyebrow = switch (module) {
      ShellModule.global   => _globalEyebrows[subIndex.clamp(0, _globalEyebrows.length - 1)],
      ShellModule.social   => _socialEyebrows[subIndex.clamp(0, _socialEyebrows.length - 1)],
      ShellModule.matching => _matchingEyebrows[subIndex.clamp(0, _matchingEyebrows.length - 1)],
      _                    => _moduleEyebrows[module] ?? '',
    };

    Widget leftWidget;
    if (module != ShellModule.global) {
      leftWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Back to Home',
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: btnBorder, width: 0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Material(
                  color: btnFill,
                  child: InkWell(
                    onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: btnIcon, size: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _PetSwitcherPill(
              eyebrow: eyebrow,
              petName: activePet?.name,
              avatarUrl: activePet?.avatarUrl,
              species: activePet?.speciesEnum,
              onTap: () => PetSwitcherSheet.show(context),
            ),
          ),
        ],
      );
    } else {
      leftWidget = _PetSwitcherPill(
        eyebrow: eyebrow,
        petName: activePet?.name ?? (subIndex == 4 ? 'Market' : null),
        avatarUrl: activePet?.avatarUrl,
        species: activePet?.speciesEnum,
        onTap: () => PetSwitcherSheet.show(context),
      );
    }

    final innerContent = Padding(
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(fit: FlexFit.loose, child: leftWidget),
          _buildTrailing(context, ref),
        ],
      ),
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: SizedBox(
          height: topPadding + 76.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(veilTopAlpha),
                  Colors.white.withAlpha(veilBottomAlpha),
                ],
              ),
              border: Border(
                top: BorderSide(color: rimColor, width: 0.5),
                bottom: BorderSide(color: separatorColor, width: 0.5),
              ),
            ),
            child: innerContent,
          ),
        ),
      ),
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor   = isDark ? Colors.white.withAlpha(48) : Colors.black.withAlpha(8);
    final borderColor = isDark ? Colors.white.withAlpha(80) : Colors.black.withAlpha(20);
    final iconColor   = isDark ? Colors.white : Colors.black87;
    final btn = Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 0.8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ── Pet switcher pill ─────────────────────────────────────────────────────────

class _PetSwitcherPill extends StatelessWidget {
  const _PetSwitcherPill({
    required this.eyebrow,
    required this.onTap,
    this.petName,
    this.avatarUrl,
    this.species,
  });

  final String eyebrow;
  final VoidCallback onTap;
  final String? petName;
  final String? avatarUrl;
  final PetSpecies? species;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor  = isDark ? Colors.white : Colors.black.withAlpha(200);
    final fillColor   = isDark ? Colors.white.withAlpha(55) : Colors.black.withAlpha(8);
    final borderColor = isDark ? Colors.white.withAlpha(90) : Colors.black.withAlpha(20);
    return Semantics(
      button: true,
      label: 'Switch active pet',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Material(
            color: fillColor,
            child: InkWell(
              onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (avatarUrl != null || species != null) ...[
                        PetAvatar(
                          imageUrl: avatarUrl,
                          species: species ?? PetSpecies.dog,
                          size: PetAvatarSize.sm,
                          showRing: true,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              eyebrow,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: labelColor.withAlpha(180),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    petName ?? 'PetFolio',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.sora(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: labelColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: labelColor,
                                  size: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

// ── Floating pill bottom nav ──────────────────────────────────────────────────


class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    super.key,
    required this.destinations,
    required this.accentColors,
    required this.selectedIndex,
    required this.onSelect,
    this.badgeCounts,
  });

  final List<AppShellDestination> destinations;
  final List<Color> accentColors;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<int>? badgeCounts;

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
                key: ValueKey('nav_${destinations[i].label.toLowerCase()}'),
                destination: destinations[i],
                isSelected: i == selectedIndex,
                accentColor: accentColors[i],
                isDark: isDark,
                onTap: () => onSelect(i),
                badgeCount: badgeCounts?[i] ?? 0,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Nav tab item — M3 Expressive spring animation ─────────────────────────────

class _NavTab extends StatefulWidget {
  const _NavTab({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
    this.badgeCount = 0,
  });

  final AppShellDestination destination;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, value: widget.isSelected ? 1.0 : 0.0);
  }

  @override
  void didUpdateWidget(_NavTab old) {
    super.didUpdateWidget(old);
    if (widget.isSelected == old.isSelected) return;
    if (widget.isSelected) {
      _ctrl.animateWith(
        SpringSimulation(PetfolioThemeExtension.spring, _ctrl.value, 1.0, 0.0),
      );
    } else {
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselected = widget.isDark ? AppColors.ink500D : AppColors.ink500;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          // Clamp to [0, 1.3] — allow slight overshoot without color math overflow.
          final t = _ctrl.value.clamp(0.0, 1.3);
          final tC = t.clamp(0.0, 1.0); // clamped for color lerp

          final iconColor = Color.lerp(unselected, widget.accentColor, tC)!;
          final bgAlpha = (36 * tC).round();
          final hPad = 8.0 + 6.0 * t; // 8 → 14 dp

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.scale(
                    scale: 1.0 + 0.08 * t,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withAlpha(bgAlpha),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        tC > 0.5
                            ? widget.destination.activeIcon
                            : widget.destination.icon,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.poppy,
                          shape: widget.badgeCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: widget.badgeCount > 9 ? BorderRadius.circular(8) : null,
                          border: Border.all(color: widget.isDark ? AppColors.surface0D : AppColors.surface0, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: tC > 0.5 ? FontWeight.w700 : FontWeight.w500,
                  color: iconColor,
                  height: 1.0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Wide nav rail ─────────────────────────────────────────────────────────────

class _WideNavRail extends StatelessWidget {
  const _WideNavRail({
    required this.destinations,
    required this.accentColors,
    required this.selectedIndex,
    required this.onSelect,
    required this.module,
    this.badgeCounts,
  });

  final List<AppShellDestination> destinations;
  final List<Color> accentColors;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ShellModule module;
  final List<int>? badgeCounts;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface0D : AppColors.surface0;

    final rail = NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      backgroundColor: bg,
      onDestinationSelected: onSelect,
      destinations: [
        for (var i = 0; i < destinations.length; i++)
          NavigationRailDestination(
            padding: EdgeInsets.zero,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  destinations[i].icon,
                  color: selectedIndex == i ? accentColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
                ),
                if ((badgeCounts?[i] ?? 0) > 0)
                  Positioned(
                    top: -4, right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppColors.poppy,
                        shape: BoxShape.circle,
                        border: Border.all(color: bg, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${badgeCounts![i]}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Icon(destinations[i].activeIcon, color: accentColors[i]),
            label: Text(
              destinations[i].label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w500,
                color: selectedIndex == i ? accentColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
              ),
            ),
          ),
      ],
    );

    if (module == ShellModule.global) {
      return SafeArea(bottom: false, right: false, child: rail);
    }

    return SafeArea(
      bottom: false,
      right: false,
      child: Container(
        color: bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Tooltip(
              message: 'Back to Home',
              child: InkWell(
                onTap: () => context.go('/home'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.ink500D : AppColors.ink500).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.home_rounded,
                    color: isDark ? AppColors.ink500D : AppColors.ink500,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.lineD : AppColors.line),
          Expanded(child: rail),
        ],
      ),
    ),
  );
  }
}
