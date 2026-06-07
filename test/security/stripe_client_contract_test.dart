import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stripe client security contract', () {
    late String libSource;

    setUpAll(() {
      final libDir = Directory('lib');
      final buffer = StringBuffer();
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        buffer.writeln(entity.readAsStringSync());
      }
      libSource = buffer.toString();
    });

    test('lib/ contains no Stripe secret key patterns', () {
      expect(libSource.contains('STRIPE_SECRET_KEY'), isFalse);
      expect(RegExp(r'sk_live_[a-zA-Z0-9]+').hasMatch(libSource), isFalse);
      expect(RegExp(r'sk_test_[a-zA-Z0-9]+').hasMatch(libSource), isFalse);
    });

    test('lib/ uses publishable key via dart-define only', () {
      expect(libSource.contains('STRIPE_PUBLISHABLE_KEY'), isTrue);
      expect(libSource.contains('String.fromEnvironment'), isTrue);
    });

    test('Edge Functions hold STRIPE_SECRET_KEY (not client)', () {
      final edgeFn = File('supabase/functions/create-payment-intent/index.ts');
      expect(edgeFn.existsSync(), isTrue);
      final src = edgeFn.readAsStringSync();
      expect(src.contains('STRIPE_SECRET_KEY'), isTrue);
      expect(src.contains('Deno.env.get'), isTrue);
    });
  });
}
