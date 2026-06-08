import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/marketplace/data/repositories/order_repository.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/checkout_controller.dart';

void main() {
  group('CheckoutState.isLoading', () {
    test('is true for loadingIntent', () {
      const s = CheckoutState(status: CheckoutStatus.loadingIntent);
      expect(s.isLoading, isTrue);
    });

    test('is true for awaitingSheet', () {
      const s = CheckoutState(status: CheckoutStatus.awaitingSheet);
      expect(s.isLoading, isTrue);
    });

    test('is true for awaitingRedirect', () {
      const s = CheckoutState(status: CheckoutStatus.awaitingRedirect);
      expect(s.isLoading, isTrue);
    });

    test('is false for idle', () {
      const s = CheckoutState(status: CheckoutStatus.idle);
      expect(s.isLoading, isFalse);
    });

    test('is false for success', () {
      const s = CheckoutState(status: CheckoutStatus.success);
      expect(s.isLoading, isFalse);
    });

    test('is false for failure', () {
      const s = CheckoutState(status: CheckoutStatus.failure);
      expect(s.isLoading, isFalse);
    });
  });

  group('CheckoutState.isLoadingShop', () {
    test('returns true when loading and shopId matches', () {
      const s = CheckoutState(
        status: CheckoutStatus.loadingIntent,
        activeShopId: 'shop-abc',
      );
      expect(s.isLoadingShop('shop-abc'), isTrue);
    });

    test('returns false when loading but shopId does not match', () {
      const s = CheckoutState(
        status: CheckoutStatus.loadingIntent,
        activeShopId: 'shop-abc',
      );
      expect(s.isLoadingShop('shop-xyz'), isFalse);
    });

    test('returns false when not loading even if shopId matches', () {
      const s = CheckoutState(
        status: CheckoutStatus.success,
        activeShopId: 'shop-abc',
      );
      expect(s.isLoadingShop('shop-abc'), isFalse);
    });
  });

  group('CheckoutState.copyWith', () {
    test('clearError removes errorMessage', () {
      const s = CheckoutState(
        status: CheckoutStatus.failure,
        errorMessage: 'Something went wrong',
      );
      final next = s.copyWith(
        status: CheckoutStatus.idle,
        clearError: true,
      );
      expect(next.errorMessage, isNull);
      expect(next.status, CheckoutStatus.idle);
    });

    test('without clearError, errorMessage is preserved', () {
      const s = CheckoutState(
        status: CheckoutStatus.failure,
        errorMessage: 'card declined',
      );
      final next = s.copyWith(status: CheckoutStatus.idle);
      expect(next.errorMessage, 'card declined');
    });

    test('verificationPending defaults to false', () {
      const s = CheckoutState(status: CheckoutStatus.idle);
      expect(s.verificationPending, isFalse);
    });

    test('copyWith preserves orderId and activeShopId', () {
      const s = CheckoutState(
        status: CheckoutStatus.awaitingSheet,
        orderId: 'order-1',
        activeShopId: 'shop-1',
      );
      final next = s.copyWith(status: CheckoutStatus.success);
      expect(next.orderId, 'order-1');
      expect(next.activeShopId, 'shop-1');
      expect(next.status, CheckoutStatus.success);
    });
  });

  group('Exception messages', () {
    test('PaymentTimeoutException has informative message', () {
      expect(
        const PaymentTimeoutException().toString(),
        contains('payment was accepted'),
      );
    });

    test('ShopNotVerifiedException message', () {
      expect(
        const ShopNotVerifiedException().toString(),
        contains('payment setup'),
      );
    });

    test('ShopInactiveException message', () {
      expect(
        const ShopInactiveException().toString(),
        contains('inactive'),
      );
    });

    test('InsufficientStockException message contains product name and counts',
        () {
      const e = InsufficientStockException(
        productName: 'Dog Kibble',
        available: 2,
        requested: 5,
      );
      final msg = e.toString();
      expect(msg, contains('Dog Kibble'));
      expect(msg, contains('2'));
      expect(msg, contains('5'));
    });
  });
}
