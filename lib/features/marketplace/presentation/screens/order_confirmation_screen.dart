import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../data/repositories/order_repository.dart';
import '../controllers/buyer_orders_controller.dart';
import '../controllers/cart_controller.dart';

enum _ConfirmState { idle, polling, confirmed, verificationPending, failed }

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends ConsumerState<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  _ConfirmState _confirmState = _ConfirmState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirmWebPayment());
    } else {
      setState(() => _confirmState = _ConfirmState.confirmed);
    }
  }

  Future<void> _confirmWebPayment() async {
    final stripe = GoRouterState.of(context).uri.queryParameters['stripe'];
    if (stripe != 'success') return;
    if (_confirmState == _ConfirmState.polling) return;

    setState(() => _confirmState = _ConfirmState.polling);
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .pollOrderConfirmation(widget.orderId);

      ref.read(cartProvider.notifier).clearShopCart(order.shopId);
      ref.invalidate(buyerOrdersProvider);

      if (mounted) setState(() => _confirmState = _ConfirmState.confirmed);
    } on PaymentTimeoutException {
      ref.invalidate(buyerOrdersProvider);
      if (mounted) {
        setState(() => _confirmState = _ConfirmState.verificationPending);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _confirmState = _ConfirmState.failed;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
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
                    _buildStatusIcon(),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildStatusBody(),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildActions(context),
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

  Widget _buildStatusIcon() {
    if (_confirmState == _ConfirmState.polling) {
      return const SizedBox(
        width: 96,
        height: 96,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    final isFailure = _confirmState == _ConfirmState.failed;
    final iconColor = isFailure ? AppColors.danger : AppColors.success;
    final bgColor = isFailure
        ? AppColors.danger.withAlpha(26)
        : AppColors.success.withAlpha(26);
    final icon = isFailure
        ? Icons.error_outline_rounded
        : Icons.check_circle_rounded;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
        child: Icon(icon, size: 56, color: iconColor),
      ),
    );
  }

  Widget _buildStatusBody() {
    switch (_confirmState) {
      case _ConfirmState.polling:
        return const Text(
          'Confirming your payment…',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink500),
        );

      case _ConfirmState.failed:
        return Column(
          children: [
            const Text(
              'Payment verification failed',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: -0.24,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.ink500,
              ),
            ),
          ],
        );

      case _ConfirmState.verificationPending:
        return Column(
          children: [
            const Text(
              'Payment accepted!',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.28,
                color: AppColors.ink950,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your payment went through but confirmation\nis still processing. Check your Orders shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 24),
            _orderRefBadge(),
          ],
        );

      case _ConfirmState.confirmed:
      case _ConfirmState.idle:
        return Column(
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
            const Text(
              'Your order is confirmed and will\narrive within 3–5 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.ink500,
              ),
            ),
            const SizedBox(height: 24),
            _orderRefBadge(),
          ],
        );
    }
  }

  Widget _orderRefBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_confirmState == _ConfirmState.polling) return const SizedBox.shrink();

    if (_confirmState == _ConfirmState.failed) {
      return Column(
        children: [
          PrimaryPillButton(
            label: 'View Orders',
            size: PillButtonSize.lg,
            isFullWidth: true,
            onPressed: () => context.go('/profile/orders'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text(
              'Back to home',
              style: TextStyle(fontSize: 14, color: AppColors.ink500),
            ),
          ),
        ],
      );
    }

    return Column(
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
          onPressed: () => context.go('/marketplace/orders/${widget.orderId}'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text(
            'Back to home',
            style: TextStyle(fontSize: 14, color: AppColors.ink500),
          ),
        ),
      ],
    );
  }
}
