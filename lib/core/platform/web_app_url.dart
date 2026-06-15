import 'package:flutter/foundation.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co',
);

String petfolioAppUrl(
  String path, {
  Map<String, String>? queryParameters,
}) {
  final normalized = path.startsWith('/') ? path : '/$path';
  final query = queryParameters == null || queryParameters.isEmpty
      ? ''
      : '?${Uri(queryParameters: queryParameters).query}';
  // Uri.base.origin throws on native mobile (file:// scheme).
  // On mobile, SSLCommerz only needs valid HTTPS redirect URLs;
  // the app polls order status on AppLifecycleState.resumed instead.
  final base = kIsWeb ? Uri.base.origin : _supabaseUrl;
  return '$base$normalized$query';
}
