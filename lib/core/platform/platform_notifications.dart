import 'package:flutter/material.dart';

import 'platform_notifications_io.dart'
    if (dart.library.html) 'platform_notifications_web.dart' as impl;

abstract class PlatformNotifications {
  static PlatformNotifications get instance => impl.platformNotifications;

  Future<void> initialize();

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required TimeOfDay tod,
    required bool repeating,
  });

  Future<void> cancelForTask(String taskId);

  Future<void> cancelAll();
}
