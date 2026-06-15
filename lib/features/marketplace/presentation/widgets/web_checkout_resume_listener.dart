import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/order_repository.dart';
import '../controllers/checkout_controller.dart';

class WebCheckoutResumeListener extends ConsumerStatefulWidget {
  const WebCheckoutResumeListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WebCheckoutResumeListener> createState() =>
      _WebCheckoutResumeListenerState();
}

class _WebCheckoutResumeListenerState extends ConsumerState<WebCheckoutResumeListener>
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
    if (state != AppLifecycleState.resumed) return;
    _handlePaymentReturn();
    ref.read(checkoutProvider.notifier).resumeWebCheckoutIfNeeded();
  }

  void _handlePaymentReturn() {
    final params = GoRouterState.of(context).uri.queryParameters;

    if (params['stripe'] == 'cancel') {
      final orderId = ref.read(checkoutProvider).orderId;
      if (orderId != null) {
        ref.read(orderRepositoryProvider).cancelOrder(orderId).ignore();
      }
      ref.read(checkoutProvider.notifier).reset();
      if (mounted) context.go('/marketplace');
      return;
    }

    if (params['ssl'] == 'cancel' || params['ssl'] == 'fail') {
      final orderId = ref.read(checkoutProvider).orderId;
      if (orderId != null) {
        ref.read(orderRepositoryProvider).cancelOrder(orderId).ignore();
      }
      ref.read(checkoutProvider.notifier).reset();
      if (mounted) context.go('/marketplace');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
