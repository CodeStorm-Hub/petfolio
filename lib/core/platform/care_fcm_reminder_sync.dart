import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> upsertCareFcmReminder({
  required String taskId,
  required String title,
  required TimeOfDay tod,
  required bool repeating,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  await Supabase.instance.client.from('care_web_reminders').upsert(
    {
      'user_id': userId,
      'task_id': taskId,
      'title': title,
      'remind_at': scheduled.toUtc().toIso8601String(),
      'repeating': repeating,
      'fcm_sent_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    onConflict: 'user_id,task_id',
  );
}

Future<void> deleteCareFcmReminder(String taskId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  await Supabase.instance.client
      .from('care_web_reminders')
      .delete()
      .eq('user_id', userId)
      .eq('task_id', taskId);
}
