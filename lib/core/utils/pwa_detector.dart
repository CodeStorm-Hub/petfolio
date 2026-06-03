import 'pwa_detector_stub.dart'
    if (dart.library.js_interop) 'pwa_detector_web.dart'
    as impl;

/// Returns true if the app is currently running in a web browser on an iOS device
/// (iPhone/iPad/iPod) but is not installed or running in standalone PWA mode.
bool isIOSWebNotStandalone() => impl.isIOSWebNotStandalone();
