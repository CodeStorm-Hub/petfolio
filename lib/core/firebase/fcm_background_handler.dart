import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../services/notification_service.dart';
import 'fcm_push_display.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await NotificationService.instance.initializeForBackgroundMessaging();
  await showFcmAsLocalNotification(message);
  if (kDebugMode) {
    debugPrint('[FCM] background: ${message.messageId} ${message.data}');
  }
}
