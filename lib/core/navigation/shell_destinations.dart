import 'package:flutter/material.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/navigation/shell_module_provider.dart';

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

// ── Global shell (4 tabs) ─────────────────────────────────────────────────────
const globalDestinations = <AppShellDestination>[
  AppShellDestination(icon: Icons.home_outlined,                    activeIcon: Icons.home_rounded,                    label: 'Home',     path: '/home'),
  AppShellDestination(icon: Icons.notifications_outlined,           activeIcon: Icons.notifications_rounded,           label: 'Alerts',   path: '/home/notifications'),
  AppShellDestination(icon: Icons.receipt_long_outlined,            activeIcon: Icons.receipt_long_rounded,            label: 'Activity', path: '/home/activity'),
  AppShellDestination(icon: Icons.manage_accounts_outlined,         activeIcon: Icons.manage_accounts_rounded,         label: 'Me',       path: '/home/me'),
];

const globalAccents = <Color>[
  AppColors.tangerine,
  AppColors.sunny,
  AppColors.poppy,
  AppColors.lilac,
];

// ── Care module (5 tabs) ──────────────────────────────────────────────────────
const careDestinations = <AppShellDestination>[
  AppShellDestination(icon: Icons.local_fire_department_outlined,   activeIcon: Icons.local_fire_department,          label: 'Dashboard',  path: '/care'),
  AppShellDestination(icon: Icons.restaurant_outlined,              activeIcon: Icons.restaurant,                     label: 'Nutrition',  path: '/care/nutrition'),
  AppShellDestination(icon: Icons.medical_services_outlined,        activeIcon: Icons.medical_services,               label: 'Health',     path: '/care/health'),
  AppShellDestination(icon: Icons.directions_walk,                  activeIcon: Icons.directions_walk,                label: 'Walk',       path: '/care/walk'),
  AppShellDestination(icon: Icons.calendar_month_outlined,          activeIcon: Icons.calendar_month,                 label: 'Vets',       path: '/care/appointments'),
];

const careAccents = <Color>[
  AppColors.sunny,
  AppColors.sunny,
  AppColors.sunny,
  AppColors.sunny,
  AppColors.sunny,
];

// ── Social module (4 tabs) ────────────────────────────────────────────────────
const socialDestinations = <AppShellDestination>[
  AppShellDestination(icon: Icons.dynamic_feed_outlined,            activeIcon: Icons.dynamic_feed,                   label: 'Feed',       path: '/social'),
  AppShellDestination(icon: Icons.auto_stories_outlined,            activeIcon: Icons.auto_stories,                   label: 'Stories',    path: '/social/stories'),
  AppShellDestination(icon: Icons.groups_outlined,                  activeIcon: Icons.groups,                         label: 'Community',  path: '/social/communities'),
  AppShellDestination(icon: Icons.pets_outlined,                    activeIcon: Icons.pets,                           label: 'My Pet',     path: '/social/profile/me'),
];

const socialAccents = <Color>[
  AppColors.poppy,
  AppColors.poppy,
  AppColors.poppy,
  AppColors.poppy,
];

// ── Matching module (3 tabs) ──────────────────────────────────────────────────
const matchingDestinations = <AppShellDestination>[
  AppShellDestination(icon: Icons.auto_awesome_outlined,            activeIcon: Icons.auto_awesome,                   label: 'Discover',   path: '/matching'),
  AppShellDestination(icon: Icons.chat_bubble_outline_rounded,      activeIcon: Icons.chat_bubble_rounded,            label: 'Messages',   path: '/matching/inbox'),
  AppShellDestination(icon: Icons.favorite_border,                  activeIcon: Icons.favorite,                       label: 'Liked',      path: '/matching/liked'),
];

const matchingAccents = <Color>[
  AppColors.lilac,
  AppColors.lilac,
  AppColors.lilac,
];

// ── Marketplace module (3 tabs) ───────────────────────────────────────────────
const marketplaceDestinations = <AppShellDestination>[
  AppShellDestination(icon: Icons.storefront_outlined,              activeIcon: Icons.storefront,                     label: 'Shop',       path: '/marketplace'),
  AppShellDestination(icon: Icons.category_outlined,                activeIcon: Icons.category,                      label: 'Browse',     path: '/marketplace/categories'),
  AppShellDestination(icon: Icons.shopping_cart_outlined,           activeIcon: Icons.shopping_cart,                  label: 'Cart',       path: '/marketplace/cart'),
];

const marketplaceAccents = <Color>[
  AppColors.mint,
  AppColors.mint,
  AppColors.mint,
];

// ── Helpers ───────────────────────────────────────────────────────────────────

List<AppShellDestination> destinationsFor(ShellModule module) {
  switch (module) {
    case ShellModule.care:        return careDestinations;
    case ShellModule.social:      return socialDestinations;
    case ShellModule.matching:    return matchingDestinations;
    case ShellModule.marketplace: return marketplaceDestinations;
    case ShellModule.global:      return globalDestinations;
  }
}

List<Color> accentsFor(ShellModule module) {
  switch (module) {
    case ShellModule.care:        return careAccents;
    case ShellModule.social:      return socialAccents;
    case ShellModule.matching:    return matchingAccents;
    case ShellModule.marketplace: return marketplaceAccents;
    case ShellModule.global:      return globalAccents;
  }
}

ShellModule moduleFromPath(String location) {
  if (location.startsWith('/care')) { return ShellModule.care; }
  if (location.startsWith('/social')) { return ShellModule.social; }
  if (location.startsWith('/matching')) { return ShellModule.matching; }
  if (location.startsWith('/marketplace') ||
      location.startsWith('/shop')) { return ShellModule.marketplace; }
  return ShellModule.global;
}

int selectedSubIndex(List<AppShellDestination> dests, String location) {
  final indices = List.generate(dests.length, (i) => i)
    ..sort((a, b) => dests[b].path.length.compareTo(dests[a].path.length));
  for (final i in indices) {
    final p = dests[i].path;
    if (location == p || location.startsWith('$p/')) { return i; }
  }
  return 0;
}
