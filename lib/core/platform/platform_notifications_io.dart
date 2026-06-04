import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notification_service.dart';
import 'care_fcm_reminder_sync.dart';
import 'platform_notifications.dart';

final PlatformNotifications platformNotifications = _IoPlatformNotifications();

class _IoPlatformNotifications implements PlatformNotifications {
  final _native = NotificationService.instance;

  @override
  Future<void> initialize() => _native.initialize();

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required TimeOfDay tod,
    required bool repeating,
  }) async {
    await _native.scheduleTaskReminder(
      taskId: taskId,
      title: title,
      tod: tod,
      repeating: repeating,
    );
    await upsertCareFcmReminder(
      taskId: taskId,
      title: title,
      tod: tod,
      repeating: repeating,
    );
  }

  @override
  Future<void> cancelForTask(String taskId) async {
    await _native.cancelForTask(taskId);
    await deleteCareFcmReminder(taskId);
  }

  @override
  Future<void> cancelAll() async {
    await _native.cancelAll();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client
          .from('care_web_reminders')
          .delete()
          .eq('user_id', userId);
    }
  }
}
