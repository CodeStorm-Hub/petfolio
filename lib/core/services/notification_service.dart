import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'petfolio_care';
  static const _channelName = 'Care Reminders';
  static const pushChannelId = 'petfolio_push';
  static const pushChannelName = 'PetFolio';
  static const chatChannelId = 'petfolio_chat_v2';
  static const chatChannelName = 'Chat messages';
  static const chatSoundResource = 'chat_message';
  static const _legacyChatChannelId = 'petfolio_chat';

  NotificationTapCallback? _onTap;
  bool _pluginReady = false;

  Future<void> initialize({NotificationTapCallback? onTap}) async {
    _onTap = onTap;
    await _ensurePluginReady();
    await _requestAndroidPermissions();
  }

  Future<void> initializeForBackgroundMessaging() async {
    await _ensurePluginReady();
  }

  Future<void> _ensurePluginReady() async {
    if (_pluginReady) return;
    tz.initializeTimeZones();
    _setLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.deleteNotificationChannel(
      channelId: _legacyChatChannelId,
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        pushChannelId,
        pushChannelName,
        description: 'Matches, social, and order alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        description: 'New chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(chatSoundResource),
      ),
    );
    _pluginReady = true;
  }

  Future<void> _requestAndroidPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    NotificationService.instance._handleTapPayload(response.payload);
  }

  void _onNotificationResponse(NotificationResponse response) {
    _handleTapPayload(response.payload);
  }

  void _handleTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _onTap?.call(decoded);
      }
    } catch (_) {}
  }

  Future<void> showPushNotification({
    required int id,
    String? title,
    String? body,
    Map<String, dynamic> data = const {},
  }) async {
    final displayTitle = title?.trim();
    final displayBody = body?.trim();
    if ((displayTitle == null || displayTitle.isEmpty) &&
        (displayBody == null || displayBody.isEmpty)) {
      return;
    }

    final isChat = data['type'] == 'chat_message';
    final androidDetails = AndroidNotificationDetails(
      isChat ? chatChannelId : pushChannelId,
      isChat ? chatChannelName : pushChannelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: isChat
          ? const RawResourceAndroidNotificationSound(chatSoundResource)
          : null,
    );

    await _plugin.show(
      id: id,
      title: displayTitle ?? 'PetFolio',
      body: displayBody ?? '',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: isChat ? 'chat_message.wav' : 'default',
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _setLocalTimezone() {
    final localOffset = DateTime.now().timeZoneOffset;
    for (final name in tz.timeZoneDatabase.locations.keys) {
      try {
        final loc = tz.getLocation(name);
        if (tz.TZDateTime.now(loc).timeZoneOffset == localOffset) {
          tz.setLocalLocation(loc);
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required TimeOfDay tod,
    required bool repeating,
  }) async {
    await cancelForTask(taskId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      tod.hour,
      tod.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id: _idFor(taskId),
      title: 'Care Reminder',
      body: title,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: repeating ? DateTimeComponents.time : null,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String serviceName,
    required DateTime scheduledAt,
  }) async {
    final reminderTime = scheduledAt.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final tzScheduled = tz.TZDateTime.from(reminderTime, tz.local);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id: _idFor(appointmentId),
      title: 'Appointment in 1 hour',
      body: serviceName,
      scheduledDate: tzScheduled,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    await _plugin.cancel(id: _idFor(appointmentId));
  }

  Future<void> cancelForTask(String taskId) async {
    await _plugin.cancel(id: _idFor(taskId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  int _idFor(String taskId) => taskId.hashCode.abs() % 1000000;
}
