import 'dart:js_interop';

@JS('window')
external _Window get _window;

extension type _Window(JSObject _) implements JSObject {
  external _Location get location;
}

extension type _Location(JSObject _) implements JSObject {
  external set href(String value);
}

Future<bool> openWebCheckoutUrl(String url) async {
  _window.location.href = url;
  return true;
}
