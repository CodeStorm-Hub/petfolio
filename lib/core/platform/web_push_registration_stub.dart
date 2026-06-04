Future<bool> registerWebPushIfAvailable({
  required String vapidPublicKey,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String accessToken,
}) async =>
    false;

bool get isWebPushSupported => false;
