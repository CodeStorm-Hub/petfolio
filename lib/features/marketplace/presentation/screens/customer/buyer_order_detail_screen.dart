import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/buyer_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';

class BuyerOrderDetailScreen extends ConsumerWidget {
  const BuyerOrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  final String orderId;
  final MarketplaceOrder? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final resolved = ordersAsync.value?.firstWhere(
          (o) => o.id == orderId,
          orElse: () => order!,
        ) ??
        order;

    if (resolved == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Order not found',
                    style: TextStyle(color: AppColors.ink500)),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
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
                      'Order Detail',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _StatusCard(order: resolved),
            ),

            SliverToBoxAdapter(
              child: _SummaryCard(order: resolved),
            ),

            SliverToBoxAdapter(
              child: _LineItemsCard(order: resolved),
            ),

            if (resolved.hasTracking)
              SliverToBoxAdapter(
                child: _TrackingCard(order: resolved),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.pending    => AppColors.warning,
      OrderStatus.processing => AppColors.info,
      OrderStatus.shipped    => AppColors.amber500,
      OrderStatus.delivered  => AppColors.success,
      OrderStatus.cancelled  => AppColors.danger,
    };
    final icon = switch (order.status) {
      OrderStatus.pending    => Icons.hourglass_empty_rounded,
      OrderStatus.processing => Icons.autorenew_rounded,
      OrderStatus.shipped    => Icons.local_shipping_outlined,
      OrderStatus.delivered  => Icons.check_circle_outline_rounded,
      OrderStatus.cancelled  => Icons.cancel_outlined,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: color.withAlpha(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(40),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status.label,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusMessage(order.status),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.ink500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(OrderStatus s) => switch (s) {
        OrderStatus.pending    => 'Awaiting seller confirmation',
        OrderStatus.processing => 'Being prepared by the seller',
        OrderStatus.shipped    => 'On its way to you',
        OrderStatus.delivered  => 'Delivered successfully',
        OrderStatus.cancelled  => 'This order was cancelled',
      };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            const Text(
              'ORDER SUMMARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Order ID',
              value: '#${order.id.substring(0, 8)}',
            ),
            const SizedBox(height: 6),
            _Row(
              label: 'Placed on',
              value: _formatDate(order.createdAt),
            ),
            const SizedBox(height: 6),
            _Row(label: 'Total', value: order.amountFormatted),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _LineItemsCard extends StatelessWidget {
  const _LineItemsCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            const Text(
              'ITEMS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in order.lineItems) ...[
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surface2,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        size: 18, color: AppColors.ink300),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ink950,
                          ),
                        ),
                        if (item.isSubscribed)
                          Text(
                            'Subscribe · every ${item.frequencyWeeks}w',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.meadow500),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink950,
                        ),
                      ),
                      Text(
                        '×${item.quantity}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.ink500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            const Text(
              'SHIPPING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.88,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 12),
            if (order.shippingCarrier != null)
              _Row(label: 'Carrier', value: order.shippingCarrier!),
            const SizedBox(height: 6),
            _Row(
              label: 'Tracking #',
              value: order.shippingTrackingNumber!,
            ),
            const SizedBox(height: 16),
            if (order.shippingTrackingUrl != null &&
                order.shippingTrackingUrl!.isNotEmpty)
              PrimaryPillButton(
                label: 'Track Package',
                size: PillButtonSize.lg,
                isFullWidth: true,
                leadingIcon:
                    const Icon(Icons.open_in_new_rounded, size: 18),
                onPressed: () async {
                  final uri = Uri.tryParse(order.shippingTrackingUrl!);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.ink500)),
        Text(value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink950,
            )),
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
