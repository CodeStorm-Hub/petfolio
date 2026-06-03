// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';

@JS('window.navigator.userAgent')
external JSString? get _jsUserAgent;

@JS('window.navigator.standalone')
external JSBoolean? get _jsStandalone;

@JS('window.matchMedia')
external JSObject? _jsMatchMedia(JSString query);

extension type _MediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
}

bool isIOSWebNotStandalone() {
  try {
    final ua = _jsUserAgent?.toDart.toLowerCase() ?? '';
    final isIOS = ua.contains('iphone') || 
                  ua.contains('ipad') || 
                  ua.contains('ipod');
    if (!isIOS) return false;

    // 1. Check iOS Safari specific property navigator.standalone
    final isStandalone = _jsStandalone?.toDart ?? false;
    if (isStandalone) return false;

    // 2. Check W3C standard media query display-mode
    final mql = _jsMatchMedia('(display-mode: standalone)'.toJS);
    if (mql != null) {
      final matches = _MediaQueryList(mql).matches;
      if (matches) return false;
    }

    return true;
  } catch (_) {
    return false;
  }
}
