import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/repositories/order_repository.dart';

class OrderSuccessSheet extends ConsumerStatefulWidget {
  const OrderSuccessSheet({super.key, required this.orderId, this.confirmStripePayment = false});

  final String orderId;
  final bool confirmStripePayment;

  static Future<void> show(
    BuildContext context,
    String orderId, {
    bool confirmStripePayment = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface0,
      builder: (_) => OrderSuccessSheet(orderId: orderId, confirmStripePayment: confirmStripePayment),
    ).then((_) {
      if (context.mounted) context.go('/home/activity');
    });
  }

  @override
  ConsumerState<OrderSuccessSheet> createState() => _OrderSuccessSheetState();
}

class _OrderSuccessSheetState extends ConsumerState<OrderSuccessSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _controller.forward();

    if (widget.confirmStripePayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirmStripe());
    }
  }

  Future<void> _confirmStripe() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      await ref.read(orderRepositoryProvider).pollOrderConfirmation(widget.orderId);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success.withAlpha(26)),
                child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  const Text(
                    'Order placed!',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28, letterSpacing: -0.28, color: AppColors.ink950),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _confirming
                        ? 'Confirming your payment…'
                        : 'Your order is confirmed and will\narrive within 3–5 business days.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink500),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColors.surface2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.ink500),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ORDER REFERENCE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.ink500),
                            ),
                            Text(
                              widget.orderId.substring(0, 8).toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink950),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryPillButton(
                    label: 'Continue shopping',
                    size: PillButtonSize.lg,
                    isFullWidth: true,
                    onPressed: () {
                      context.pop();
                      context.go('/marketplace');
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryPillButton(
                    label: 'View Order',
                    size: PillButtonSize.lg,
                    isFullWidth: true,
                    onPressed: () {
                      context.pop();
                      context.go('/marketplace/orders/${widget.orderId}');
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.pop();
                      context.go('/home');
                    },
                    child: const Text('Back to home', style: TextStyle(fontSize: 14, color: AppColors.ink500)),
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

// Backward-compat alias.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: SafeArea(child: OrderSuccessSheet(orderId: orderId)),
    );
  }
}
