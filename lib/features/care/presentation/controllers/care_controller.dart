import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/care_task_type.dart';
import '../../data/repositories/care_repository.dart';

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
    // Seed with empty week — screen triggers loadLocal() on first frame.
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

  CareRepository get _repo => ref.read(careRepositoryProvider);

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
    state = CareState(
      petId: arg,
      week: week,
      streak: CareState._computeStreak(week),
    );
  }

  /// Optimistically toggle a task, then sync to Supabase in background.
  Future<void> toggle(CareTaskType task) async {
    final currentlyDone = state.today.isDone(task);
    final newDone = !currentlyDone;

    // 1. Optimistic UI update.
    state = state.copyWithToggle(task, newDone);

    // 2. Write locally + background remote sync.
    await _repo.toggleTask(petId: arg, task: task, done: newDone);
  }
}
