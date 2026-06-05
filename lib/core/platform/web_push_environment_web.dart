import 'dart:js_interop';

@JS('window.__petfolioFcmSwReady')
external JSPromise<JSAny?>? get _fcmSwReady;

@JS('navigator.userAgent')
external String get _userAgent;

@JS('window.__petfolioIsIosStandalonePwa')
external bool Function() _isIosStandalonePwa;

bool get isAppleMobileWeb {
  return _userAgent.contains('iPhone') ||
      _userAgent.contains('iPad') ||
      _userAgent.contains('iPod');
}

bool get isIosStandalonePwa {
  if (!isAppleMobileWeb) return false;
  try {
    return _isIosStandalonePwa();
  } catch (_) {
    return false;
  }
}

Future<void> waitForFcmServiceWorker() async {
  final ready = _fcmSwReady;
  if (ready == null) return;
  try {
    await ready.toDart;
  } catch (_) {}
}
