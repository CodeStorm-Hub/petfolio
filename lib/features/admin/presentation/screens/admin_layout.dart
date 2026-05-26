import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/admin_dashboard_tab.dart';
import '../widgets/financial_ledger_tab.dart';
import '../widgets/kyc_approvals_tab.dart';
import '../widgets/moderation_tab.dart';
import '../widgets/orders_tab.dart';
import '../widgets/shops_tab.dart';
import '../controllers/shop_deletion_controller.dart';

enum _AdminTab { dashboard, kyc, ledger, orders, moderation, shops }

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
      icon: Icons.verified_user_outlined,
      activeIcon: Icons.verified_user_rounded,
      label: 'KYC',
      tab: _AdminTab.kyc,
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: 'Ledger',
      tab: _AdminTab.ledger,
    ),
    (
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Orders',
      tab: _AdminTab.orders,
    ),
    (
      icon: Icons.shield_outlined,
      activeIcon: Icons.shield_rounded,
      label: 'Moderation',
      tab: _AdminTab.moderation,
    ),
    (
      icon: Icons.store_outlined,
      activeIcon: Icons.store_rounded,
      label: 'Shops',
      tab: _AdminTab.shops,
    ),
  ];

  Widget get _body => switch (_tab) {
        _AdminTab.dashboard  => const AdminDashboardTab(),
        _AdminTab.kyc        => const KycApprovalsTab(),
        _AdminTab.ledger     => const FinancialLedgerTab(),
        _AdminTab.orders     => const OrdersTab(),
        _AdminTab.moderation => const ModerationTab(),
        _AdminTab.shops      => const ShopsTab(),
      };

  int get _selectedIndex =>
      _destinations.indexWhere((d) => d.tab == _tab);

  void _onDestinationSelected(int i) =>
      setState(() => _tab = _destinations[i].tab);

  Widget _destinationIcon(IconData icon, _AdminTab tab, WidgetRef ref) {
    if (tab != _AdminTab.shops) return Icon(icon);
    final hasPending = ref.watch(
      shopDeletionRequestsProvider.select((v) => (v.value?.isNotEmpty) ?? false),
    );
    return Badge(
      isLabelVisible: hasPending,
      backgroundColor: Theme.of(context).colorScheme.error,
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width > 800;

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              backgroundColor: cs.surfaceContainerLowest,
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        // Title inherits appBarTheme.titleTextStyle (Sora 20sp w600) from AppTheme
        title: Text(_destinations[_selectedIndex].label),
        leading: Builder(
          builder: (ctx) => IconButton(
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
        backgroundColor: cs.surfaceContainerLowest,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _AdminBadge(),
              ),
              Divider(height: 1, color: const Color(0xFFE2E8F0)),
              const SizedBox(height: 8),
              for (final d in _destinations)
                ListTile(
                  leading: Icon(
                    _tab == d.tab ? d.activeIcon : d.icon,
                    color: _tab == d.tab
                        ? pt.info
                        : const Color(0xFF64748B),
                  ),
                  title: Text(
                    d.label,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: _tab == d.tab
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _tab == d.tab
                              ? pt.info
                              : const Color(0xFF334155),
                        ),
                  ),
                  selected: _tab == d.tab,
                  selectedTileColor: pt.info.withAlpha(12),
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pt.info.withAlpha(20),
            ),
            child: Icon(Icons.admin_panel_settings_rounded,
                size: 20, color: pt.info),
          ),
          const SizedBox(height: 4),
          Text(
            'Admin',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: pt.info,
                ),
          ),
        ],
      ),
    );
  }
}
