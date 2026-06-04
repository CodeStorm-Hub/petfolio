import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../../firebase_options.dart';

class FirebaseEnv {
  FirebaseEnv._();

  static const vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');

  static bool get isConfigured => true;

  static FirebaseOptions get options => DefaultFirebaseOptions.currentPlatform;

  static bool get canRequestWebToken => !kIsWeb || vapidKey.isNotEmpty;

  static String get platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'unknown';
    }
  }
}
