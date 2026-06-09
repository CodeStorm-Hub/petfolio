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
import 'package:petfolio/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:petfolio/features/matching/presentation/matching_navigation.dart';
import 'package:petfolio/features/matching/presentation/widgets/match_preferences_sheet.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/core/providers/shell_scroll_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

// ── App shell ─────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _showTutorial = false;
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    _loadTutorialFlag();
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

  ShellModule _currentModule(BuildContext context) =>
      moduleFromPath(GoRouterState.of(context).matchedLocation);

  int _currentSubIndex(ShellModule module, BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return selectedSubIndex(destinationsFor(module), location);
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
        onSelect: (i) => context.go(dests[i].path),
        accentColors: accents,
      ),
    );

    if (isWide) {
      return _wrapWithTutorial(
        Scaffold(
          body: Row(
            children: [
              _WideNavRail(
                destinations: dests,
                accentColors: accents,
                selectedIndex: subIndex,
                onSelect: (i) => context.go(dests[i].path),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
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
      );
    }

    if (kIsWeb) {
      return _wrapWithTutorial(
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              Positioned.fill(child: widget.child),
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
      );
    }

    return _wrapWithTutorial(
      Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(child: widget.child),
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
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class AppShellHeader extends ConsumerWidget {
  const AppShellHeader({super.key, required this.module, required this.subIndex});

  final ShellModule module;
  final int subIndex;

  static const _globalEyebrows = ['HOME', 'ALERTS', 'ACTIVITY', 'ME'];
  static const _moduleEyebrows = {
    ShellModule.care:        'CARE',
    ShellModule.social:      'PAWSFEED',
    ShellModule.matching:    'MATCH · NEARBY',
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
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x38FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(width: 8),
            _HeaderIconBtn(icon: Icons.notifications_rounded, onTap: () => context.go('/notifications')),
            const SizedBox(width: 8),
            _HeaderIconBtn(icon: Icons.manage_accounts_rounded, onTap: () => context.go('/me')),
          ]);
        case 1: // Alerts
          return Consumer(builder: (context, ref, _) {
            final notifs = ref.watch(notificationsProvider).value ?? [];
            final unread = notifs.where((n) => !n.isRead).length;
            if (unread == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
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
            onTap: () => context.push('/social/communities'),
          ),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.search, onTap: () {}),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.send_rounded, onTap: () => context.push('/matching/inbox')),
        ]);
      case ShellModule.matching:
        return Row(children: [
          _HeaderIconBtn(icon: Icons.chat_bubble_outline_rounded, onTap: () => openMatchesInbox(context)),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.tune_rounded, onTap: () => MatchPreferencesSheet.show(context)),
        ]);
      case ShellModule.marketplace:
        return Consumer(builder: (context, ref, _) {
          final cart = ref.watch(cartProvider);
          return GestureDetector(
            key: const ValueKey<String>('market_action_cart'),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              backgroundColor: Colors.transparent,
              constraints: const BoxConstraints(maxWidth: 560),
              builder: (_) => const CartDrawer(),
            ),
            child: Container(
              width: 44, height: 44,
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
                      top: -6, right: -8,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.poppy,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cream, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
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
    final waveColor = activePet?.speciesEnum.resolvedAccent(isDark) ?? AppColors.tangerine;
    final bgColor = Color.lerp(
      Colors.transparent,
      waveColor.withAlpha(238),
      scrollProgress,
    )!;
    final blurSigma = 24.0 * scrollProgress;

    final eyebrow = module == ShellModule.global
        ? _globalEyebrows[subIndex.clamp(0, _globalEyebrows.length - 1)]
        : _moduleEyebrows[module] ?? '';

    Widget leftWidget;
    if (module != ShellModule.global) {
      leftWidget = GestureDetector(
        onTap: () => context.go('/home'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(56),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'HOME',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6),
                  ),
                  Text(
                    eyebrow,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      leftWidget = GestureDetector(
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
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: Colors.white, letterSpacing: 0.6,
                    ),
                  ),
                  Row(children: [
                    Text(
                      activePet?.name ?? (subIndex == 4 ? 'Market' : 'PetFolio'),
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
                  ]),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final innerContent = Padding(
      padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leftWidget,
          _buildTrailing(context, ref),
        ],
      ),
    );

    Widget header = Container(
      color: bgColor,
      height: topPadding + 76.0,
      child: innerContent,
    );

    if (scrollProgress > 0.01) {
      header = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: header,
        ),
      );
    }

    return header;
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
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(
          color: Color(0x38FFFFFF),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
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
  });

  final List<AppShellDestination> destinations;
  final List<Color> accentColors;
  final int selectedIndex;
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
                key: ValueKey('nav_${destinations[i].label.toLowerCase()}'),
                destination: destinations[i],
                isSelected: i == selectedIndex,
                accentColor: accentColors[i],
                isDark: isDark,
                onTap: () => onSelect(i),
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
  });

  final AppShellDestination destination;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _spring = SpringDescription(mass: 1.0, stiffness: 550, damping: 32);

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
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1.0, 0.0));
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
              const SizedBox(height: 2),
              Text(
                widget.destination.label,
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
  });

  final List<AppShellDestination> destinations;
  final List<Color> accentColors;
  final int selectedIndex;
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
            icon: Icon(
              destinations[i].icon,
              color: selectedIndex == i ? accentColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
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
  }
}
