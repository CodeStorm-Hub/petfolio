import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:petfolio/core/theme/app_theme.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/models/shipment.dart';
import '../controllers/shipment_controller.dart';
import '../widgets/marketplace_back_button.dart';
import '../widgets/marketplace_state_views.dart';

class ShipmentTrackingScreen extends ConsumerWidget {
  const ShipmentTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final async = ref.watch(shipmentProvider(orderId));

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const MarketplaceBackButton(),
                    const SizedBox(width: 4),
                    Text(
                      'Track Shipment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            async.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: MarketplaceErrorView(
                  message: 'Could not load shipment info',
                  onRetry: () => ref.invalidate(shipmentProvider(orderId)),
                ),
              ),
              data: (shipment) {
                if (shipment == null) {
                  return const SliverFillRemaining(
                    child: MarketplaceEmptyView(
                      icon: Icons.local_shipping_outlined,
                      title: 'No shipment info yet',
                      message: 'Check back once your order ships.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ShipmentStatusCard(shipment: shipment),
                      const SizedBox(height: 16),
                      _ShipmentTimeline(status: shipment.status),
                      const SizedBox(height: 16),
                      if (shipment.courier != null || shipment.trackingId != null)
                        _TrackingDetails(shipment: shipment),
                      const SizedBox(height: 16),
                      if (shipment.trackingUrl != null &&
                          shipment.trackingUrl!.isNotEmpty)
                        PrimaryPillButton(
                          label: 'Track on Courier Website',
                          size: PillButtonSize.lg,
                          isFullWidth: true,
                          leadingIcon:
                              const Icon(Icons.open_in_new_rounded, size: 18),
                          onPressed: () async {
                            final uri =
                                Uri.tryParse(shipment.trackingUrl!);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentStatusCard extends StatelessWidget {
  const _ShipmentStatusCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final color = switch (shipment.status) {
      ShipmentStatus.pending        => AppColors.warning,
      ShipmentStatus.pickedUp       => AppColors.info,
      ShipmentStatus.inTransit      => AppColors.blue500,
      ShipmentStatus.outForDelivery => AppColors.mint,
      ShipmentStatus.delivered      => AppColors.success,
      ShipmentStatus.failed         => AppColors.danger,
    };
    final icon = switch (shipment.status) {
      ShipmentStatus.pending        => Icons.hourglass_empty_rounded,
      ShipmentStatus.pickedUp       => Icons.inventory_2_outlined,
      ShipmentStatus.inTransit      => Icons.local_shipping_outlined,
      ShipmentStatus.outForDelivery => Icons.directions_bike_outlined,
      ShipmentStatus.delivered      => Icons.check_circle_outline_rounded,
      ShipmentStatus.failed         => Icons.error_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withAlpha(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(40),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                if (shipment.estimatedDeliveryAt != null)
                  Text(
                    'Est. delivery: ${_formatDate(shipment.estimatedDeliveryAt!)}',
                    style: TextStyle(
                        fontSize: 12, color: pt.ink500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _ShipmentTimeline extends StatelessWidget {
  const _ShipmentTimeline({required this.status});

  final ShipmentStatus status;

  static const _steps = [
    ShipmentStatus.pending,
    ShipmentStatus.pickedUp,
    ShipmentStatus.inTransit,
    ShipmentStatus.outForDelivery,
    ShipmentStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _steps.indexOf(status);

    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface,
        boxShadow: [
          BoxShadow(color: pt.line, spreadRadius: 0.5),
        ],
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final isDone = i <= currentIdx;
          final isLast = i == _steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.mint : pt.surface2,
                      border: Border.all(
                        color: isDone ? AppColors.mint : pt.line,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: isDone ? AppColors.mint : pt.line,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 28),
                child: Text(
                  _steps[i].label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        i == currentIdx ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? pt.ink950 : pt.ink300,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TrackingDetails extends StatelessWidget {
  const _TrackingDetails({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface,
        boxShadow: [
          BoxShadow(color: pt.line, spreadRadius: 0.5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRACKING DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.88,
              color: pt.ink500,
            ),
          ),
          const SizedBox(height: 12),
          if (shipment.courier != null)
            _DetailRow(label: 'Courier', value: shipment.courier!),
          if (shipment.trackingId != null) ...[
            const SizedBox(height: 6),
            _DetailRow(label: 'Tracking ID', value: shipment.trackingId!),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 13, color: pt.ink500)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: pt.ink950)),
      ],
    );
  }
}
