import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';
import 'package:petfolio/core/widgets/app_tutorial_overlay.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/cart_controller.dart';
import 'package:petfolio/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:petfolio/features/matching/presentation/matching_navigation.dart';
import 'package:petfolio/features/matching/presentation/widgets/match_preferences_sheet.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

// ── Tab accent colors (matches design system pillar colors) ──────────────────
const tabAccentColors = [
  AppColors.tangerine, // Pets
  AppColors.sunny,     // Care
  AppColors.poppy,     // Social
  AppColors.lilac,     // Match
  AppColors.mint,      // Market
];

// ── Nav destination descriptor ───────────────────────────────────────────────
class AppShellDestination {
  const AppShellDestination({
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

// ── Shell destinations (single source of truth) ───────────────────────────────
const appShellDestinations = [
  AppShellDestination(icon: Icons.pets_outlined,       activeIcon: Icons.pets,                  label: 'Pets',   path: '/home'),
  AppShellDestination(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department, label: 'Care',   path: '/care'),
  AppShellDestination(icon: Icons.favorite_border,     activeIcon: Icons.favorite,              label: 'Social', path: '/social'),
  AppShellDestination(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome,        label: 'Match',  path: '/matching'),
  AppShellDestination(icon: Icons.storefront_outlined, activeIcon: Icons.storefront,            label: 'Market', path: '/marketplace'),
];

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

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < appShellDestinations.length; i++) {
      if (location.startsWith(appShellDestinations[i].path)) return i;
    }
    return 0;
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
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return _wrapWithTutorial(
        Scaffold(
          body: Row(
            children: [
              _WideNavRail(
                selectedIndex: selectedIndex,
                onSelect: (i) => context.go(appShellDestinations[i].path),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: AppShellHeader(selectedIndex: selectedIndex),
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
                top: 0,
                left: 0,
                right: 0,
                child: AppShellHeader(selectedIndex: selectedIndex),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _FloatingNav(
                selectedIndex: selectedIndex,
                onSelect: (i) => context.go(appShellDestinations[i].path),
              ),
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
              child: AppShellHeader(selectedIndex: selectedIndex),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12 + MediaQuery.paddingOf(context).bottom,
              child: _FloatingNav(
                selectedIndex: selectedIndex,
                onSelect: (i) => context.go(appShellDestinations[i].path),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class AppShellHeader extends ConsumerWidget {
  const AppShellHeader({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);

    final eyebrows = [
      'ACTIVE PET',
      'CARE',
      'PAWSFEED',
      'MATCH · NEARBY',
      'SHOP FOR',
    ];

    Widget trailingActions;
    switch (selectedIndex) {
      case 0:
        trailingActions = Row(children: [
          _HeaderIconBtn(icon: Icons.notifications_rounded, onTap: () => context.push('/social/notifications')),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.settings_rounded, onTap: () => context.push('/pets/manage')),
        ]);
      case 1:
        trailingActions = Row(children: [
          _HeaderIconBtn(
            icon: Icons.directions_walk_rounded,
            tooltip: 'Walk tracking',
            onTap: () => context.push('/care/walk'),
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
      case 2:
        trailingActions = Row(children: [
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
      case 3:
        trailingActions = Row(children: [
          _HeaderIconBtn(icon: Icons.chat_bubble_outline_rounded, onTap: () => openMatchesInbox(context)),
          const SizedBox(width: 8),
          _HeaderIconBtn(icon: Icons.tune_rounded, onTap: () => MatchPreferencesSheet.show(context)),
        ]);
      case 4:
      default:
        trailingActions = Consumer(builder: (context, ref, _) {
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
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      color: Colors.transparent,
      height: topPadding + 76.0,
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
                          eyebrows[selectedIndex],
                          style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 0.6,
                          ),
                        ),
                        Row(children: [
                          Text(
                            activePet?.name ?? (selectedIndex == 4 ? 'Market' : 'PetFolio'),
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
            ),
            trailingActions,
          ],
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
  const _FloatingNav({required this.selectedIndex, required this.onSelect});

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
          for (var i = 0; i < appShellDestinations.length; i++)
            Expanded(
              child: _NavTab(
                destination: appShellDestinations[i],
                isSelected: i == selectedIndex,
                accentColor: tabAccentColors[i],
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
  const _WideNavRail({required this.selectedIndex, required this.onSelect});

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
        for (var i = 0; i < appShellDestinations.length; i++)
          NavigationRailDestination(
            padding: EdgeInsets.zero,
            icon: Icon(
              appShellDestinations[i].icon,
              color: selectedIndex == i ? tabAccentColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
            ),
            selectedIcon: Icon(appShellDestinations[i].activeIcon, color: tabAccentColors[i]),
            label: Text(
              appShellDestinations[i].label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w500,
                color: selectedIndex == i ? tabAccentColors[i] : (isDark ? AppColors.ink500D : AppColors.ink500),
              ),
            ),
          ),
      ],
    );
  }
}
