import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'care_fcm_reminder_sync.dart';
import 'platform_notifications.dart';

final PlatformNotifications platformNotifications = _WebPlatformNotifications();

class _WebPlatformNotifications implements PlatformNotifications {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required TimeOfDay tod,
    required bool repeating,
  }) => upsertCareFcmReminder(
        taskId: taskId,
        title: title,
        tod: tod,
        repeating: repeating,
      );

  @override
  Future<void> cancelForTask(String taskId) => deleteCareFcmReminder(taskId);

  @override
  Future<void> cancelAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('care_web_reminders').delete().eq('user_id', userId);
  }
}
