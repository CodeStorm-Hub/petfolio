import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDG5_rufMTdwV9X2wc7M5YNyEkWwXN8tGM',
    appId: '1:86798095066:web:61021d3c9119434a68cbe3',
    messagingSenderId: '86798095066',
    projectId: 'petfolio-v1',
    authDomain: 'petfolio-v1.firebaseapp.com',
    storageBucket: 'petfolio-v1.firebasestorage.app',
    measurementId: 'G-57M4WLN8YH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW3jiVahlDqTey6aj0zsj9Z-Dj-kvamgE',
    appId: '1:86798095066:android:5b5d6008f7ab957f68cbe3',
    messagingSenderId: '86798095066',
    projectId: 'petfolio-v1',
    storageBucket: 'petfolio-v1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDW3jiVahlDqTey6aj0zsj9Z-Dj-kvamgE',
    appId: '1:86798095066:android:5b5d6008f7ab957f68cbe3',
    messagingSenderId: '86798095066',
    projectId: 'petfolio-v1',
    storageBucket: 'petfolio-v1.firebasestorage.app',
    iosBundleId: 'com.example.petfolio',
  );
}