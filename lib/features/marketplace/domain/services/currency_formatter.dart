const _currencySymbols = <String, String>{
  'usd': '\$',
  'bdt': '৳',
  'eur': '€',
  'gbp': '£',
  'cad': 'CA\$',
  'aud': 'A\$',
  'inr': '₹',
  'sgd': 'S\$',
};

String formatCents(int cents, {String currency = 'usd'}) {
  final amount = (cents / 100).toStringAsFixed(2);
  final symbol = _currencySymbols[currency.toLowerCase()];
  return symbol != null ? '$symbol$amount' : '$amount ${currency.toUpperCase()}';
}
