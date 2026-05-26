import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/deletion_request_controller.dart';
import '../../controllers/my_shop_controller.dart';
import '../../controllers/vendor_orders_controller.dart';
import '../../controllers/vendor_products_controller.dart';
import '../../../data/models/marketplace_order.dart';
import '../../../data/models/shop.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(myShopProvider.notifier).refreshAfterOnboarding();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(myShopProvider.notifier).refreshAfterOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: shopAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (shop) {
            if (shop == null) {
              return _NoShopView(
                onCreateShop: () => context.push('/seller/setup'),
              );
            }
            if (!shop.isActive) {
              return _ShopDeactivatedView(
                onRefresh: () =>
                    ref.read(myShopProvider.notifier).refreshAfterOnboarding(),
              );
            }
            return _DashboardBody(shop: shop);
          },
        ),
      ),
    );
  }
}

class _NoShopView extends StatelessWidget {
  const _NoShopView({required this.onCreateShop});

  final VoidCallback onCreateShop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.surface2,
              ),
              child: Icon(Icons.storefront_outlined,
                  size: 36, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink300),
            ),
            SizedBox(height: 20),
            Text(
              'Open your shop',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Create a storefront to sell pet products\nto the PetFolio community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 28),
            PrimaryPillButton(
              label: 'Create My Shop',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: onCreateShop,
              leadingIcon: Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopDeactivatedView extends StatefulWidget {
  const _ShopDeactivatedView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  State<_ShopDeactivatedView> createState() => _ShopDeactivatedViewState();
}

class _ShopDeactivatedViewState extends State<_ShopDeactivatedView> {
  bool _checking = false;

  Future<void> _handleRefresh() async {
    setState(() => _checking = true);
    widget.onRefresh();
    await Future<void>.delayed(Duration(seconds: 2));
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.error.withAlpha(16),
              ),
              child: Icon(Icons.store_outlined,
                  size: 36, color: Theme.of(context).colorScheme.error),
            ),
            SizedBox(height: 20),
            Text(
              'Shop Closed',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your deletion request was approved.\nThis shop and all its products have been deactivated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            SizedBox(height: 28),
            PrimaryPillButton(
              label: 'Set Up New Shop',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: () => context.push('/seller/setup'),
              leadingIcon: Icon(Icons.add_rounded, size: 20),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _checking ? null : _handleRefresh,
              icon: _checking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : Icon(Icons.refresh_rounded, size: 18),
              label: Text(_checking ? 'Checking…' : 'Check for active shop'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_rounded, size: 16),
              label: Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);

    final productCount = productsAsync.value?.length ?? 0;
    final pendingOrders = ordersAsync.value
            ?.where((o) => o.status == OrderStatus.processing)
            .length ??
        0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
                SizedBox(width: 12),
                Text(
                  'Seller Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 20, color: Color(0xFF64748B)),
                  onPressed: () => context.push('/seller/edit-shop'),
                ),
              ],
            ),
          ),
        ),

        // Stripe onboarding banner (International vendors only)
        if (shop.needsOnboarding)
          SliverToBoxAdapter(
            child: _OnboardingBanner(shopId: shop.id),
          ),

        // KYC status banners (Bangladesh / manual payout vendors)
        if (shop.payoutMethod == PayoutMethod.manual &&
            shop.kycStatus == KycStatus.submitted)
          SliverToBoxAdapter(child: _KycPendingBanner()),
        if (shop.payoutMethod == PayoutMethod.manual &&
            shop.kycStatus == KycStatus.rejected)
          SliverToBoxAdapter(
            child: _KycRejectedBanner(reason: shop.rejectionReason),
          ),

        // Shop card
        SliverToBoxAdapter(
          child: _ShopCard(shop: shop),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    value: '$productCount',
                    color: AppColors.apricot500,
                    onTap: () => context.push('/seller/products'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pending orders',
                    value: '$pendingOrders',
                    color: AppColors.coral500,
                    onTap: () => context.push('/seller/orders'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick actions
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _QuickActions(shop: shop),
        ),

        SliverToBoxAdapter(
          child: _DangerZone(shop: shop),
        ),

        SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _OnboardingBanner extends ConsumerWidget {
  const _OnboardingBanner({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color(0xFFFFF3CD),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete your Stripe setup to start receiving payments.',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                try {
                  final url =
                      await ref.read(myShopProvider.notifier).startOnboarding();
                  if (!context.mounted) return;
                  context.push(
                    '/seller/onboarding?url=${Uri.encodeComponent(url)}',
                  );
                } catch (e) {
                  if (context.mounted) AppSnackBar.showError(e);
                }
              },
              child: Text(
                'Setup',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.surface2,
              ),
              child: shop.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(shop.logoUrl!, fit: BoxFit.cover),
                    )
                  : Icon(Icons.storefront_outlined,
                      color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink300),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    shop.description ?? 'No description yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            _ShopStatusChip(shop: shop),
          ],
        ),
      ),
    );
  }
}

class _ShopStatusChip extends StatelessWidget {
  const _ShopStatusChip({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, tappable) = _resolve(context);

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withAlpha(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (tappable) ...[
            SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 13, color: color),
          ],
        ],
      ),
    );

    if (!tappable) return chip;

    return GestureDetector(
      onTap: () => context.push('/seller/kyc'),
      child: chip,
    );
  }

  (String, Color, IconData, bool) _resolve(BuildContext context) {
    if (shop.isVerified) {
      return ('Verified', Color(0xFF10B981), Icons.check_circle_outline_rounded, false);
    }
    if (shop.payoutMethod == PayoutMethod.manual) {
      return switch (shop.kycStatus) {
        KycStatus.submitted => (
            'Under Review',
            Color(0xFF3B82F6),
            Icons.hourglass_top_rounded,
            false,
          ),
        KycStatus.rejected => (
            'Rejected',
            Theme.of(context).colorScheme.error,
            Icons.cancel_outlined,
            true,
          ),
        _ => (
            'Complete KYC',
            Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
            Icons.upload_file_outlined,
            true,
          ),
      };
    }
    return ('Pending', Theme.of(context).extension<PetfolioThemeExtension>()!.warning, Icons.schedule_rounded, false);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withAlpha(26),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              ),
            ),
            SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.add_box_outlined,
        label: 'Add product',
        route: '/seller/products/add',
      ),
      (
        icon: Icons.inventory_2_outlined,
        label: 'Manage products',
        route: '/seller/products',
      ),
      (
        icon: Icons.receipt_long_outlined,
        label: 'View orders',
        route: '/seller/orders',
      ),
      (
        icon: Icons.storefront_outlined,
        label: 'Edit shop',
        route: '/seller/edit-shop',
      ),
    ];

    return Column(
      children: [
        for (final a in actions)
          _ActionRow(icon: a.icon, label: a.label, route: a.route),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Color(0xFF64748B)),
            SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              ),
            ),
            Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink300),
          ],
        ),
      ),
    );
  }
}

class _KycPendingBanner extends StatelessWidget {
  const _KycPendingBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Color(0xFFFFF3CD),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Documents under review. We\'ll notify you once verified.',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycRejectedBanner extends StatelessWidget {
  const _KycRejectedBanner({required this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.error.withAlpha(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documents rejected.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (reason != null && reason!.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      reason!,
                      style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ],
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/seller/kyc'),
                    child: Text(
                      'Resubmit documents',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Danger Zone ──────────────────────────────────────────────────────────────

class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(deletionRequestProvider);
    final request = requestAsync.value;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Color(0xFFE2E8F0)),
          SizedBox(height: 12),
          Text(
            'DANGER ZONE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.88,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          SizedBox(height: 12),
          if (request == null)
            _DeleteTile(shop: shop)
          else if (request['status'] == 'pending')
            _PendingBanner(requestedAt: DateTime.parse(request['requested_at'] as String))
          else if (request['status'] == 'rejected')
            _RejectedBanner(
              rejectionNote: request['rejection_note'] as String?,
              shop: shop,
            ),
        ],
      ),
    );
  }
}

class _DeleteTile extends StatelessWidget {
  const _DeleteTile({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DeleteShopRequestSheet(shop: shop),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.error.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_forever_rounded,
                size: 20, color: Theme.of(context).colorScheme.error),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request shop deletion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Requires admin review',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink300),
          ],
        ),
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.requestedAt});

  final DateTime requestedAt;

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final date =
        '${months[requestedAt.month - 1]} ${requestedAt.day}, ${requestedAt.year}';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 20, color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deletion request pending',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Admin review in progress · Submitted $date',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({required this.rejectionNote, required this.shop});

  final String? rejectionNote;
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.error.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, size: 20, color: Theme.of(context).colorScheme.error),
              SizedBox(width: 10),
              Text(
                'Deletion request rejected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          if (rejectionNote != null && rejectionNote!.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              rejectionNote!,
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ],
          SizedBox(height: 10),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _DeleteShopRequestSheet(shop: shop),
            ),
            child: Text(
              'Submit new request →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteShopRequestSheet extends ConsumerStatefulWidget {
  const _DeleteShopRequestSheet({required this.shop});

  final Shop shop;

  @override
  ConsumerState<_DeleteShopRequestSheet> createState() =>
      _DeleteShopRequestSheetState();
}

class _DeleteShopRequestSheetState
    extends ConsumerState<_DeleteShopRequestSheet> {
  final _reasonController = TextEditingController();
  var _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(deletionRequestProvider.notifier)
          .submitRequest(
            widget.shop.id,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(parseDeletionError(e));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Request Shop Deletion',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: pt.ink950,
            ),
          ),
          SizedBox(height: 16),
          _ConsequenceItem(
              icon: Icons.visibility_off_outlined,
              text: 'Shop hidden from all buyers immediately on approval'),
          SizedBox(height: 8),
          _ConsequenceItem(
              icon: Icons.inventory_2_outlined,
              text: 'All products will be unlisted'),
          SizedBox(height: 8),
          _ConsequenceItem(
              icon: Icons.warning_amber_rounded,
              text: 'Cannot be undone without contacting support'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pt.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: pt.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PetFolio reviews requests within 2–3 business days. You\'ll be notified of the outcome.',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Why are you closing your shop?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Submit Request'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConsequenceItem extends StatelessWidget {
  const _ConsequenceItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Color(0xFF64748B)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: Color(0xFF334155)),
      ),
    );
  }
}
