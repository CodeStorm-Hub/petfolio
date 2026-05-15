import 'package:flutter/material.dart';

TimeOfDay? parseCareScheduledTimeOfDay(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parts = raw.trim().split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final hour = h < 0 ? 0 : (h > 23 ? 23 : h);
  final minute = m < 0 ? 0 : (m > 59 ? 59 : m);
  return TimeOfDay(hour: hour, minute: minute);
}
