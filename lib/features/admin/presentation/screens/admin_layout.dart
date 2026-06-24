import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/admin_auth_controller.dart';
import '../widgets/admin_dashboard_tab.dart';
import '../widgets/moderation_tab.dart';

enum _AdminTab { dashboard, moderation }

class AdminLayout extends ConsumerStatefulWidget {
  const AdminLayout({super.key});

  @override
  ConsumerState<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends ConsumerState<AdminLayout> {
  _AdminTab _tab = _AdminTab.dashboard;

  static const _destinations = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      tab: _AdminTab.dashboard,
    ),
    (
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_rounded,
      label: 'Moderation',
      tab: _AdminTab.moderation,
    ),
  ];

  Widget get _body => switch (_tab) {
        _AdminTab.dashboard  => const AdminDashboardTab(),
        _AdminTab.moderation => const ModerationTab(),
      };

  int get _selectedIndex =>
      _destinations.indexWhere((d) => d.tab == _tab);

  void _onDestinationSelected(int i) =>
      setState(() => _tab = _destinations[i].tab);

  Widget _destinationIcon(IconData icon, _AdminTab tab, WidgetRef ref) =>
      Icon(icon);

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 48, color: pt.ink300),
              const SizedBox(height: 16),
              Text(
                'Admin access required',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => _buildLayout(context, constraints.maxWidth > 800),
    );
  }

  Widget _buildLayout(BuildContext context, bool isWide) {
    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.surface1,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.surface0,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _AdminBadge(),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go('/home'),
                      tooltip: 'Back to app',
                    ),
                  ),
                ),
              ),
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: _destinationIcon(d.icon, d.tab, ref),
                    selectedIcon: _destinationIcon(d.activeIcon, d.tab, ref),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface1,
      appBar: AppBar(
        backgroundColor: AppColors.surface0,
        // Title inherits appBarTheme.titleTextStyle (Sora 20sp w600) from AppTheme
        title: Text(_destinations[_selectedIndex].label),
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Open menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
            tooltip: 'Back to app',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface0,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _AdminBadge(),
              ),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 8),
              for (final d in _destinations)
                ListTile(
                  leading: Icon(
                    _tab == d.tab ? d.activeIcon : d.icon,
                    color: _tab == d.tab
                        ? AppColors.blue500
                        : AppColors.ink500,
                  ),
                  title: Text(
                    d.label,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: _tab == d.tab
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _tab == d.tab
                              ? AppColors.blue500
                              : AppColors.ink700,
                        ),
                  ),
                  selected: _tab == d.tab,
                  selectedTileColor: AppColors.blue500.withAlpha(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      PetfolioThemeExtension.radiusMd,
                    ),
                  ),
                  onTap: () {
                    setState(() => _tab = d.tab);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      body: _body,
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue500.withAlpha(20),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 20, color: AppColors.blue500),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: AppColors.blue500,
                ),
          ),
        ],
      ),
    );
  }
}
