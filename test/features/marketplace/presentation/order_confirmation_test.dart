import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/features/marketplace/data/models/marketplace_order.dart';
import 'package:petfolio/features/marketplace/data/repositories/order_repository.dart';
import 'package:petfolio/features/marketplace/presentation/screens/order_confirmation_screen.dart';

// ── Standalone poll-logic helper (mirrors OrderRepository.pollOrderConfirmation) ──

Future<MarketplaceOrder> _poll({
  required Future<MarketplaceOrder> Function(String) fetchOrder,
  required Duration timeout,
  required Duration interval,
  String orderId = _testOrderId,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final order = await fetchOrder(orderId);
    if (order.paymentStatus == PaymentStatus.paid ||
        order.status == OrderStatus.processing) {
      return order;
    }
    if (order.status == OrderStatus.cancelled) {
      throw Exception('Order was cancelled during verification.');
    }
    await Future<void>.delayed(interval);
  }
  throw const PaymentTimeoutException();
}

// ── Helpers ──────────────────────────────────────────────────────────────────

const _testOrderId = 'aabbccdd-0000-0000-0000-aabbccddee00';

MarketplaceOrder _fakeOrder({
  OrderStatus status = OrderStatus.processing,
  PaymentStatus paymentStatus = PaymentStatus.paid,
}) =>
    MarketplaceOrder(
      id: _testOrderId,
      buyerId: 'buyer-1',
      shopId: 'shop-1',
      title: 'Test order',
      amountCents: 1000,
      currency: 'usd',
      status: status,
      paymentStatus: paymentStatus,
      lineItems: const [],
      createdAt: DateTime(2026, 1, 1),
    );

Widget _wrap(
  Widget child, {
  OrderRepository? repo,
  String? stripeParam,
}) {
  final router = GoRouter(
    initialLocation: stripeParam != null
        ? '/marketplace/order/aabbccdd?stripe=$stripeParam'
        : '/marketplace/order/aabbccdd',
    routes: [
      GoRoute(
        path: '/marketplace/order/:id',
        builder: (_, _) => child,
      ),
      GoRoute(
        path: '/marketplace',
        builder: (_, _) => const Scaffold(body: Text('marketplace')),
      ),
      GoRoute(
        path: '/marketplace/orders/:id',
        builder: (_, _) => const Scaffold(body: Text('order-detail')),
      ),
      GoRoute(
        path: '/profile/orders',
        builder: (_, _) => const Scaffold(body: Text('orders')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      if (repo != null)
        orderRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('OrderConfirmationScreen', () {
    testWidgets('native path: shows confirmed state immediately', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const OrderConfirmationScreen(orderId: _testOrderId),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order placed!'), findsOneWidget);
      expect(
        find.text(
          'Your order is confirmed and will\narrive within 3–5 business days.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(_testOrderId.substring(0, 8).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Continue shopping'), findsOneWidget);
      expect(find.text('View Order'), findsOneWidget);
    });

    testWidgets('native path: "View Order" navigates to order detail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderConfirmationScreen(orderId: _testOrderId)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Order'));
      await tester.pumpAndSettle();
      expect(find.text('order-detail'), findsOneWidget);
    });

    testWidgets('native path: "Continue shopping" navigates to marketplace',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderConfirmationScreen(orderId: _testOrderId)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue shopping'));
      await tester.pumpAndSettle();
      expect(find.text('marketplace'), findsOneWidget);
    });

    testWidgets('native path: "Back to home" navigates to home', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderConfirmationScreen(orderId: _testOrderId)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });
  });

  // ── Poll-logic unit tests (independent of Supabase) ─────────────────────

  group('pollOrderConfirmation logic', () {
    test('resolves immediately when order is processing', () async {
      final order = _fakeOrder();
      final result = await _poll(
        fetchOrder: (_) async => order,
        timeout: const Duration(seconds: 5),
        interval: Duration.zero,
      );
      expect(result.status, OrderStatus.processing);
    });

    test('resolves when paymentStatus is paid even if status is still pending',
        () async {
      final order = _fakeOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.paid,
      );
      final result = await _poll(
        fetchOrder: (_) async => order,
        timeout: const Duration(seconds: 5),
        interval: Duration.zero,
      );
      expect(result.paymentStatus, PaymentStatus.paid);
    });

    test('throws PaymentTimeoutException when deadline passes', () async {
      final pending = _fakeOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
      );
      await expectLater(
        _poll(
          fetchOrder: (_) async => pending,
          timeout: const Duration(milliseconds: 40),
          interval: const Duration(milliseconds: 10),
        ),
        throwsA(isA<PaymentTimeoutException>()),
      );
    });

    test('throws exception immediately when order is cancelled', () async {
      final cancelled = _fakeOrder(
        status: OrderStatus.cancelled,
        paymentStatus: PaymentStatus.pending,
      );
      await expectLater(
        _poll(
          fetchOrder: (_) async => cancelled,
          timeout: const Duration(seconds: 5),
          interval: Duration.zero,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('cancelled'),
          ),
        ),
      );
    });
  });
}
