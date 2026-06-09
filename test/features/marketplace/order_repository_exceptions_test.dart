import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/features/marketplace/data/repositories/order_repository.dart';

PostgrestException _rpcError(String message) => PostgrestException(
      message: message,
      code: 'P0001',
      details: '',
      hint: '',
    );

void main() {
  group('mapAndThrowCheckoutRpcException', () {
    test('maps SHOP_INACTIVE', () {
      expect(
        () => mapAndThrowCheckoutRpcException(_rpcError('SHOP_INACTIVE')),
        throwsA(isA<ShopInactiveException>()),
      );
    });

    test('maps SHOP_NOT_VERIFIED', () {
      expect(
        () => mapAndThrowCheckoutRpcException(_rpcError('SHOP_NOT_VERIFIED')),
        throwsA(isA<ShopNotVerifiedException>()),
      );
    });

    test('maps INSUFFICIENT_STOCK with parsed fields', () {
      expect(
        () => mapAndThrowCheckoutRpcException(
          _rpcError('INSUFFICIENT_STOCK:Kibble:2:5'),
        ),
        throwsA(
          predicate<InsufficientStockException>(
            (e) =>
                e.productName == 'Kibble' &&
                e.available == 2 &&
                e.requested == 5,
          ),
        ),
      );
    });

    test('rethrows unknown PostgrestException', () {
      expect(
        () => mapAndThrowCheckoutRpcException(_rpcError('UNKNOWN_ERROR')),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
