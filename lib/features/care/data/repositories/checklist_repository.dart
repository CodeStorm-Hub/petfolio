import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/care_task_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(Supabase.instance.client);
});

// ─────────────────────────────────────────────────────────────────────────────
// Offline-first checklist repository
//
// Write path:  SharedPreferences (immediate) → Supabase (background).
// Read path:   SharedPreferences (cold-start) → merge Supabase (background).
//
// Key format:  care_{petId}_{yyyy-MM-dd}_{taskType}  →  bool
// ─────────────────────────────────────────────────────────────────────────────

class ChecklistRepository {
  ChecklistRepository(this._client);

  final SupabaseClient _client;

  // ── Local helpers ───────────────────────────────────────────────────────────

  String _key(String petId, DateTime date, CareTaskType task) =>
      'care_${petId}_${_fmt(date)}_${task.name}';

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime _today() => DateUtils.dateOnly(DateTime.now().toLocal());

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
  //
  // Writes locally first, then awaits the remote sync.
  // Throws if the remote call fails so the controller can revert both
  // the UI state and the local SharedPreferences entry.

  Future<void> toggleTask({
    required String petId,
    required CareTaskType task,
    required bool done,
  }) async {
    final today = _today();
    final prefs = await SharedPreferences.getInstance();

    // 1. Write locally — UI already updated optimistically by the controller.
    await prefs.setBool(_key(petId, today, task), done);

    // 2. Sync to Supabase — propagates on failure so the controller can revert.
    await _syncToRemote(petId: petId, task: task, date: today, done: done);
  }

  Future<void> revertLocal({
    required String petId,
    required CareTaskType task,
    required bool previousValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(petId, _today(), task), previousValue);
  }

  // ── Supabase sync ───────────────────────────────────────────────────────────

  Future<void> _syncToRemote({
    required String petId,
    required CareTaskType task,
    required DateTime date,
    required bool done,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (done) {
      await _client.from('care_logs').upsert(
        {
          'pet_id':      petId,
          'logged_by':   userId,
          'care_type':   _dbCareType(task),
          'logged_date': _fmt(date),
          'occurred_at': '${_fmt(date)}T00:00:00.000Z',
        },
        onConflict: 'pet_id, care_type, logged_date',
      );
    } else {
      await _client
          .from('care_logs')
          .delete()
          .eq('pet_id', petId)
          .eq('care_type', _dbCareType(task))
          .eq('logged_date', _fmt(date));
    }
  }

  // ── Merge remote logs into SharedPreferences ────────────────────────────────

  Future<void> refreshFromRemote(String petId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final today = _today();
      final weekAgo = today.subtract(const Duration(days: 6));
      final prefs = await SharedPreferences.getInstance();

      final rows = await _client
          .from('care_logs')
          .select('care_type, logged_date')
          .eq('pet_id', petId)
          .eq('logged_by', userId)
          .gte('logged_date', _fmt(weekAgo))
          .lte('logged_date', _fmt(today));

      for (final row in rows) {
        final taskType = _parseTaskType(row['care_type'] as String?);
        final dateStr = row['logged_date'] as String?;
        if (taskType == null || dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final dayOnly = DateUtils.dateOnly(date);

        final key = _key(petId, dayOnly, taskType);
        final localVal = prefs.getBool(key) ?? false;
        if (!localVal) {
          await prefs.setBool(key, true);
        }
      }
    } catch (e) {
      debugPrint('[ChecklistRepository] remote refresh failed: $e');
    }
  }

  static String _dbCareType(CareTaskType t) => switch (t) {
        CareTaskType.feed => 'feeding',
        CareTaskType.walk => 'walk',
        CareTaskType.med  => 'medication',
      };

  CareTaskType? _parseTaskType(String? s) => switch (s) {
        'feeding'    => CareTaskType.feed,
        'walk'       => CareTaskType.walk,
        'medication' => CareTaskType.med,
        _            => null,
      };
}
