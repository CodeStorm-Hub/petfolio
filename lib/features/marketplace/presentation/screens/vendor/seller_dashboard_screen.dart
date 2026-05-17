import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
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
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: shopAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (shop) => shop == null
              ? _NoShopView(onCreateShop: () => context.push('/seller/setup'))
              : _DashboardBody(shop: shop),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2,
              ),
              child: const Icon(Icons.storefront_outlined,
                  size: 36, color: AppColors.ink300),
            ),
            const SizedBox(height: 20),
            const Text(
              'Open your shop',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Create a storefront to sell pet products\nto the PetFolio community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.ink500),
            ),
            const SizedBox(height: 28),
            PrimaryPillButton(
              label: 'Create My Shop',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: onCreateShop,
              leadingIcon: const Icon(Icons.add_rounded, size: 20),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                _IconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Seller Dashboard',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.ink950,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.ink500),
                  onPressed: () => context.push('/seller/setup'),
                ),
              ],
            ),
          ),
        ),

        // Onboarding banner
        if (shop.needsOnboarding)
          SliverToBoxAdapter(
            child: _OnboardingBanner(shopId: shop.id),
          ),

        // Shop card
        SliverToBoxAdapter(
          child: _ShopCard(shop: shop),
        ),

        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                const SizedBox(width: 12),
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.ink500,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _QuickActions(shop: shop),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFFF3CD),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Complete your Stripe setup to start receiving payments.',
                style: TextStyle(fontSize: 13, color: AppColors.ink700),
              ),
            ),
            const SizedBox(width: 8),
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
              child: const Text(
                'Setup',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.warning,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface2,
              ),
              child: shop.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(shop.logoUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.storefront_outlined,
                      color: AppColors.ink300),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink950,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.description ?? 'No description yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: shop.isVerified
                    ? AppColors.success.withAlpha(20)
                    : AppColors.warning.withAlpha(20),
              ),
              child: Text(
                shop.isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: shop.isVerified
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
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
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.ink500)),
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
        route: '/seller/setup',
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ink500),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink950,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.ink300),
          ],
        ),
      ),
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
          color: AppColors.surface0,
          boxShadow: const [
            BoxShadow(color: AppColors.line200, spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.ink700),
      ),
    );
  }
}
