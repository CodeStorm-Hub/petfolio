import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

String? _appliedKey;

Future<void> ensureStripeReady({required String publishableKey}) async {
  if (publishableKey.isEmpty) {
    throw Exception('Stripe is not configured. Check STRIPE_PUBLISHABLE_KEY in your .env file.');
  }
  if (_appliedKey == publishableKey) return;

  Stripe.publishableKey = publishableKey;
  if (!kIsWeb) {
    Stripe.merchantIdentifier = 'merchant.com.petfolio';
  }
  await Stripe.instance.applySettings();
  _appliedKey = publishableKey;
}
