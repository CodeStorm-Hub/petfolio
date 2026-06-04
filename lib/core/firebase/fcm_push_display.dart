import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/notification_service.dart';

Future<void> showFcmAsLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] as String?;
  final body = message.notification?.body ?? message.data['body'] as String?;
  final data = Map<String, dynamic>.from(message.data);
  final id = message.messageId?.hashCode ??
      message.sentTime?.millisecondsSinceEpoch ??
      DateTime.now().millisecondsSinceEpoch;

  await NotificationService.instance.showPushNotification(
    id: id.abs() % 1000000,
    title: title,
    body: body,
    data: data,
  );
}
