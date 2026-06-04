import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/repositories/order_repository.dart';

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirmWebPayment());
    }
  }

  Future<void> _confirmWebPayment() async {
    final stripe = GoRouterState.of(context).uri.queryParameters['stripe'];
    if (stripe != 'success' || _confirming) return;

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
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface0,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 0, 32, bottomPad + 24),
                child: Column(
                  children: [
                    const Spacer(),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withAlpha(26),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 56,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          const Text(
                            'Order placed!',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              letterSpacing: -0.28,
                              color: AppColors.ink950,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _confirming
                                ? 'Confirming your payment…'
                                : 'Your order is confirmed and will\narrive within 3–5 business days.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: AppColors.ink500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.surface2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 16,
                                  color: AppColors.ink500,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ORDER REFERENCE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: AppColors.ink500,
                                      ),
                                    ),
                                    Text(
                                      widget.orderId.substring(0, 8).toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppColors.ink950,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          PrimaryPillButton(
                            label: 'Continue shopping',
                            size: PillButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () => context.go('/marketplace'),
                          ),
                          const SizedBox(height: 12),
                          PrimaryPillButton(
                            label: 'View Order',
                            size: PillButtonSize.lg,
                            isFullWidth: true,
                            onPressed: () =>
                                context.go('/marketplace/orders/${widget.orderId}'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/home'),
                            child: const Text(
                              'Back to home',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.ink500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
