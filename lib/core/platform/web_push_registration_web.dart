import 'dart:js_interop';

@JS('PetfolioPush.isSupported')
external bool _petfolioPushIsSupported();

@JS('PetfolioPush.register')
external JSPromise<JSAny?> _petfolioPushRegister(
  JSString vapidPublicKey,
  JSString supabaseUrl,
  JSString supabaseAnonKey,
  JSString accessToken,
);

bool get isWebPushSupported {
  try {
    return _petfolioPushIsSupported();
  } catch (_) {
    return false;
  }
}

Future<bool> registerWebPushIfAvailable({
  required String vapidPublicKey,
  required String supabaseUrl,
  required String supabaseAnonKey,
  required String accessToken,
}) async {
  if (vapidPublicKey.isEmpty) return false;
  try {
    await _petfolioPushRegister(
      vapidPublicKey.toJS,
      supabaseUrl.toJS,
      supabaseAnonKey.toJS,
      accessToken.toJS,
    ).toDart;
    return true;
  } catch (_) {
    return false;
  }
}
