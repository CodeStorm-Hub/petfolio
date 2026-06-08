import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

bool _stripeSettingsApplied = false;

Future<void> ensureStripeReady({required String publishableKey}) async {
  if (_stripeSettingsApplied) return;

  Stripe.publishableKey = publishableKey;
  if (!kIsWeb) {
    Stripe.merchantIdentifier = 'merchant.com.petfolio';
  }
  await Stripe.instance.applySettings();
  _stripeSettingsApplied = true;
}
