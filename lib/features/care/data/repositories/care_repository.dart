import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/care_task_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final careRepositoryProvider = Provider<CareRepository>((ref) {
  return CareRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Offline-first care repository
//
// Write path:  SharedPreferences (immediate) → Supabase (background).
// Read path:   SharedPreferences (cold-start) → merge Supabase (background).
//
// Key format:  care_{petId}_{yyyy-MM-dd}_{taskType}  →  bool
// ─────────────────────────────────────────────────────────────────────────────

class CareRepository {
  CareRepository(this._client);

  final SupabaseClient _client;

  // ── Local helpers ───────────────────────────────────────────────────────────

  String _key(String petId, DateTime date, CareTaskType task) =>
      'care_${petId}_${_fmt(date)}_${task.name}';

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime _today() => DateUtils.dateOnly(DateTime.now());

  // ── Read 7-day window from SharedPreferences ────────────────────────────────

  Future<Map<DateTime, Map<CareTaskType, bool>>> loadLocalWeek(
      String petId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <DateTime, Map<CareTaskType, bool>>{};
    final today = _today();

    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final tasks = <CareTaskType, bool>{};
      for (final t in CareTaskType.values) {
        tasks[t] = prefs.getBool(_key(petId, day, t)) ?? false;
      }
      result[day] = tasks;
    }
    return result;
  }

  // ── Toggle a task (offline-first) ──────────────────────────────────────────

  Future<void> toggleTask({
    required String petId,
    required CareTaskType task,
    required bool done,
  }) async {
    final today = _today();
    final prefs = await SharedPreferences.getInstance();

    // 1. Write locally — UI already updated optimistically by the controller.
    await prefs.setBool(_key(petId, today, task), done);

    // 2. Sync to Supabase in background — failures are silent (offline expected).
    unawaited(_syncToRemote(petId: petId, task: task, date: today, done: done));
  }

  // ── Background Supabase sync ────────────────────────────────────────────────

  Future<void> _syncToRemote({
    required String petId,
    required CareTaskType task,
    required DateTime date,
    required bool done,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      if (done) {
        await _client.from('care_logs').upsert(
          {
            'pet_id': petId,
            'user_id': userId,
            'task_type': task.name,
            'logged_date': _fmt(date),
          },
          onConflict: 'pet_id, task_type, logged_date',
        );
      } else {
        await _client
            .from('care_logs')
            .delete()
            .eq('pet_id', petId)
            .eq('task_type', task.name)
            .eq('logged_date', _fmt(date));
      }
    } catch (e) {
      // Expected when offline — local state is source of truth.
      debugPrint('[CareRepository] remote sync failed: $e');
    }
  }

  // ── Merge remote logs into SharedPreferences ────────────────────────────────
  //
  // Called once per screen mount. Remote wins for past days (user may have
  // completed tasks on another device); local wins for today (in-progress).

  Future<void> refreshFromRemote(String petId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final today = _today();
      final weekAgo = today.subtract(const Duration(days: 6));
      final prefs = await SharedPreferences.getInstance();

      final rows = await _client
          .from('care_logs')
          .select('task_type, logged_date')
          .eq('pet_id', petId)
          .eq('user_id', userId)
          .gte('logged_date', _fmt(weekAgo))
          .lte('logged_date', _fmt(today));

      // Mark all past days from remote (don't overwrite today in-progress).
      for (final row in rows) {
        final taskType = _parseTaskType(row['task_type'] as String?);
        final dateStr = row['logged_date'] as String?;
        if (taskType == null || dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final dayOnly = DateUtils.dateOnly(date);

        // Remote wins for all days; today we only mark true (never remove).
        final key = _key(petId, dayOnly, taskType);
        final localVal = prefs.getBool(key) ?? false;
        if (!localVal) {
          await prefs.setBool(key, true);
        }
      }
    } catch (e) {
      debugPrint('[CareRepository] remote refresh failed: $e');
    }
  }

  CareTaskType? _parseTaskType(String? s) {
    if (s == null) return null;
    return CareTaskType.values.where((t) => t.name == s).firstOrNull;
  }
}
