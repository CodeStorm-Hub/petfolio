String formatCents(int cents, {String currency = 'usd'}) {
  final amount = (cents / 100).toStringAsFixed(2);
  return currency.toLowerCase() == 'usd' ? '\$$amount' : '$amount ${currency.toUpperCase()}';
}
