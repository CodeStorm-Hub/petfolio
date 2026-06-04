import 'package:flutter/foundation.dart';

String petfolioAppUrl(
  String path, {
  Map<String, String>? queryParameters,
}) {
  final normalized = path.startsWith('/') ? path : '/$path';
  final query = queryParameters == null || queryParameters.isEmpty
      ? ''
      : '?${Uri(queryParameters: queryParameters).query}';
  if (kIsWeb) {
    return '${Uri.base.origin}/#$normalized$query';
  }
  return '${Uri.base.origin}$normalized$query';
}
