import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/care_task.dart' as dbtask;
import '../../data/models/care_task_type.dart';
import '../../data/repositories/checklist_repository.dart';
import 'care_dashboard_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class CareState {
  const CareState({
    required this.petId,
    required this.week,
    required this.streak,
  });

  /// The pet this state belongs to.
  final String petId;

  /// 7-day window: index 0 = 6 days ago, index 6 = today.
  final List<DayData> week;

  /// Consecutive past days (before today) where all 3 tasks were done.
  final int streak;

  DayData get today => week.last;

  int get todayCount =>
      CareTaskType.values.where((t) => today.isDone(t)).length;

  CareState copyWithToggle(CareTaskType task, bool done) {
    final newWeek = List<DayData>.from(week);
    newWeek[6] = today.copyWith(task, done);
    return CareState(
      petId: petId,
      week: newWeek,
      streak: _computeStreak(newWeek),
    );
  }

  static int _computeStreak(List<DayData> week) {
    int streak = 0;
    // Walk backwards from yesterday (index 5).
    for (var i = 5; i >= 0; i--) {
      if (week[i].allDone) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class DayData {
  const DayData({
    required this.date,
    required this.feed,
    required this.walk,
    required this.med,
  });

  final DateTime date;
  final bool feed;
  final bool walk;
  final bool med;

  bool isDone(CareTaskType t) {
    switch (t) {
      case CareTaskType.feed: return feed;
      case CareTaskType.walk: return walk;
      case CareTaskType.med:  return med;
    }
  }

  bool get allDone => feed && walk && med;

  DayData copyWith(CareTaskType task, bool done) => DayData(
        date: date,
        feed: task == CareTaskType.feed ? done : feed,
        walk: task == CareTaskType.walk ? done : walk,
        med:  task == CareTaskType.med  ? done : med,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final careControllerProvider =
    NotifierProvider.family<CareNotifier, CareState, String>(
  CareNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CareNotifier extends FamilyNotifier<CareState, String> {
  @override
  CareState build(String petId) {
    // React to dashboard state changes → sync today's task completions into streak
    ref.listen<DailyRoutineState>(careDashboardProvider(petId), (_, next) {
      _onDashboardChange(next);
    });
    // Sync once after build in case the dashboard is already loaded (revisit scenario)
    Future.microtask(() => _onDashboardChange(ref.read(careDashboardProvider(petId))));

    final today = DateUtils.dateOnly(DateTime.now());
    final emptyWeek = List.generate(
      7,
      (i) => DayData(
        date: today.subtract(Duration(days: 6 - i)),
        feed: false,
        walk: false,
        med: false,
      ),
    );
    return CareState(petId: petId, week: emptyWeek, streak: 0);
  }

  // Maps the loaded care_tasks for today onto today's DayData in the streak week.
  void _onDashboardChange(DailyRoutineState dashboard) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.dateOnly(dashboard.selectedDate) != today) return;
    final tasks = dashboard.tasks.valueOrNull;
    if (tasks == null) return;
    _overrideTodayFromTasks(tasks, today);
  }

  void _overrideTodayFromTasks(List<dbtask.CareTask> tasks, DateTime today) {
    final feed = tasks.any(
        (t) => t.taskType == dbtask.CareTaskType.feeding && t.isCompleted);
    final walk = tasks.any(
        (t) => t.taskType == dbtask.CareTaskType.walk && t.isCompleted);
    final med = tasks.any(
        (t) => t.taskType == dbtask.CareTaskType.medication && t.isCompleted);

    final newWeek = List<DayData>.from(state.week);
    newWeek[6] = DayData(date: today, feed: feed, walk: walk, med: med);
    state = CareState(
      petId: arg,
      week: newWeek,
      streak: CareState._computeStreak(newWeek),
    );
  }

  ChecklistRepository get _repo => ref.read(checklistRepositoryProvider);

  /// Load local SharedPreferences state immediately — no network.
  Future<void> loadLocal() async {
    final rawWeek = await _repo.loadLocalWeek(arg);
    _applyWeek(rawWeek);
  }

  /// Refresh from Supabase and re-read local state (called once per mount).
  Future<void> refresh() async {
    await _repo.refreshFromRemote(arg);
    final rawWeek = await _repo.loadLocalWeek(arg);
    _applyWeek(rawWeek);
  }

  void _applyWeek(Map<DateTime, Map<CareTaskType, bool>> rawWeek) {
    final days = rawWeek.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final week = days.map((e) => DayData(
          date: e.key,
          feed: e.value[CareTaskType.feed] ?? false,
          walk: e.value[CareTaskType.walk] ?? false,
          med:  e.value[CareTaskType.med]  ?? false,
        )).toList();

    // Overlay today from care_tasks (new task system takes precedence over care_logs)
    final today = DateUtils.dateOnly(DateTime.now());
    final dashboard = ref.read(careDashboardProvider(arg));
    if (DateUtils.dateOnly(dashboard.selectedDate) == today && week.isNotEmpty) {
      final tasks = dashboard.tasks.valueOrNull;
      if (tasks != null) {
        week[week.length - 1] = DayData(
          date: today,
          feed: tasks.any((t) => t.taskType == dbtask.CareTaskType.feeding && t.isCompleted),
          walk: tasks.any((t) => t.taskType == dbtask.CareTaskType.walk && t.isCompleted),
          med:  tasks.any((t) => t.taskType == dbtask.CareTaskType.medication && t.isCompleted),
        );
      }
    }

    state = CareState(
      petId: arg,
      week: week,
      streak: CareState._computeStreak(week),
    );
  }

  /// Optimistically toggle a task, persist locally, and sync to Supabase.
  ///
  /// If the remote write fails the UI state **and** the SharedPreferences
  /// entry are both reverted so the user sees no phantom change.
  Future<void> toggle(CareTaskType task) async {
    final prevState = state;
    final previousDone = state.today.isDone(task);
    final newDone = !previousDone;

    // 1. Optimistic UI update — feels instant for the user.
    state = state.copyWithToggle(task, newDone);

    try {
      // 2. Write to local prefs + await remote sync (throws on network failure).
      await _repo.toggleTask(petId: arg, task: task, done: newDone);
    } catch (e, st) {
      // 3. Remote sync failed — roll back UI and local prefs.
      debugPrint('[CareNotifier] toggle failed, reverting: $e\n$st');
      state = prevState;
      await _repo.revertLocal(petId: arg, task: task, previousValue: previousDone);
    }
  }
}
