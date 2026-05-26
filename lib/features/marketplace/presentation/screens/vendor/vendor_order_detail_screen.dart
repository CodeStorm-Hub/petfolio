import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/vendor_orders_controller.dart';
import '../../../data/models/marketplace_order.dart';
import '../../../../../core/theme/app_theme.dart';


class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  final String orderId;
  final MarketplaceOrder? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);
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
                    style: TextStyle(color: Color(0xFF64748B))),
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
      backgroundColor: const Color(0xFFFFFFFF),
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
                    Text(
                      'Order Detail',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _OrderSummaryCard(order: resolved),
            ),

            SliverToBoxAdapter(
              child: _LineItemsCard(order: resolved),
            ),

            if (resolved.status.isActive)
              SliverToBoxAdapter(
                child: _ActionButtons(order: resolved),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cs.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: pt.ink950,
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: const Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 12),
            _InfoRow(label: 'Total', value: order.amountFormatted),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Placed',
              value: _formatDate(order.createdAt),
            ),
            if (order.hasTracking) ...[
              const SizedBox(height: 6),
              _InfoRow(
                label: 'Tracking',
                value: order.shippingTrackingNumber!,
              ),
              if (order.shippingCarrier != null) ...[
                const SizedBox(height: 6),
                _InfoRow(label: 'Carrier', value: order.shippingCarrier!),
              ],
            ],
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cs.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
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
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            for (final item in order.lineItems) ...[
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: pt.surface2,
                    ),
                    child: Icon(Icons.shopping_bag_outlined,
                        size: 18, color: pt.ink300),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: TextStyle(
                          fontSize: 13, color: pt.ink950),
                    ),
                  ),
                  Text(
                    '×${item.quantity}  \$${(item.lineTotalCents / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pt.ink950,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.order});

  final MarketplaceOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.processing)
            PrimaryPillButton(
              label: 'Add tracking info',
              size: PillButtonSize.lg,
              isFullWidth: true,
              variant: PillButtonVariant.secondary,
              leadingIcon:
                  const Icon(Icons.local_shipping_outlined, size: 18),
              onPressed: () => _showTrackingSheet(context, ref),
            ),
          const SizedBox(height: 10),
          if (order.status == OrderStatus.pending)
            PrimaryPillButton(
              label: 'Mark as processing',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: () => ref
                  .read(vendorOrdersProvider.notifier)
                  .updateStatus(
                    orderId: order.id,
                    status: OrderStatus.processing,
                  ),
            ),
          if (order.status == OrderStatus.shipped)
            PrimaryPillButton(
              label: 'Mark as delivered',
              size: PillButtonSize.lg,
              isFullWidth: true,
              onPressed: () => ref
                  .read(vendorOrdersProvider.notifier)
                  .updateStatus(
                    orderId: order.id,
                    status: OrderStatus.delivered,
                  ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTrackingSheet(
      BuildContext context, WidgetRef ref) async {
    final trackingCtrl = TextEditingController();
    final carrierCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    await AppBottomSheet.show<void>(
      context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add tracking info',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950,
              ),
            ),
            const SizedBox(height: 16),
            _SheetField(controller: carrierCtrl, hint: 'Carrier (e.g. UPS)'),
            const SizedBox(height: 12),
            _SheetField(
                controller: trackingCtrl,
                hint: 'Tracking number'),
            const SizedBox(height: 12),
            _SheetField(
                controller: urlCtrl,
                hint: 'Tracking URL (optional)'),
            const SizedBox(height: 20),
            PrimaryPillButton(
              label: 'Save & mark shipped',
              size: PillButtonSize.xl,
              isFullWidth: true,
              onPressed: () async {
                if (trackingCtrl.text.trim().isEmpty ||
                    carrierCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                await ref
                    .read(vendorOrdersProvider.notifier)
                    .updateTracking(
                      orderId: order.id,
                      trackingNumber: trackingCtrl.text.trim(),
                      trackingUrl: urlCtrl.text.trim(),
                      carrier: carrierCtrl.text.trim(),
                    );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: pt.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: const Color(0xFF64748B))),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: pt.ink950,
            )),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  Color _color(BuildContext context) => switch (status) {
        OrderStatus.pending    => Theme.of(context).extension<PetfolioThemeExtension>()!.warning,
        OrderStatus.processing => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
        OrderStatus.shipped    => Theme.of(context).extension<PetfolioThemeExtension>()!.info,
        OrderStatus.delivered  => Theme.of(context).extension<PetfolioThemeExtension>()!.success,
        OrderStatus.cancelled  => Theme.of(context).colorScheme.error,
      };

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    // ignore: unused_local_variable
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _color(context).withAlpha(26),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color(context),
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
    // ignore: unused_local_variable
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerLowest,
          boxShadow: const [
            BoxShadow(color: Color(0xFFE2E8F0), spreadRadius: 0.5),
          ],
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF334155)),
      ),
    );
  }
}
