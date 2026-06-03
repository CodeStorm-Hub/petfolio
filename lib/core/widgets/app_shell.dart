import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/cart_controller.dart';
import 'package:petfolio/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:petfolio/features/matching/presentation/matching_navigation.dart';
import 'package:petfolio/features/matching/presentation/widgets/match_preferences_sheet.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import 'package:petfolio/core/widgets/pwa_onboarding_prompt.dart';

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

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < appShellDestinations.length; i++) {
      if (location.startsWith(appShellDestinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PwaOnboardingPrompt.checkAndShow(context);
    });
    final selectedIndex = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return Scaffold(
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
                  Positioned.fill(child: child),
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: AppShellHeader(selectedIndex: selectedIndex),
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
          Positioned.fill(child: child),
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
        trailingActions = Consumer(builder: (context, ref, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return _HeaderIconBtn(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          );
        });
      case 2:
        trailingActions = Row(children: [
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

// ── Nav tab item ──────────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
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
