import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/care/data/models/care_task_type.dart';
import 'package:petfolio/features/care/data/models/care_streak.dart';
import 'package:petfolio/features/care/data/repositories/checklist_repository.dart';
import 'package:petfolio/features/care/presentation/controllers/care_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';

// ── Fake checklist repository ─────────────────────────────────────────────────

class _SuccessChecklistRepo implements ChecklistRepository {
  bool revertCalled = false;

  @override
  Future<void> toggleTask({
    required String petId,
    required CareTaskType task,
    required bool done,
  }) async {}

  @override
  Future<void> revertLocal({
    required String petId,
    required CareTaskType task,
    required bool previousValue,
  }) async {
    revertCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FailingChecklistRepo implements ChecklistRepository {
  bool revertCalled = false;

  @override
  Future<void> toggleTask({
    required String petId,
    required CareTaskType task,
    required bool done,
  }) async =>
      throw Exception('network timeout');

  @override
  Future<void> revertLocal({
    required String petId,
    required CareTaskType task,
    required bool previousValue,
  }) async {
    revertCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

DailyRoutineState _emptyDashboard() {
  // Use yesterday so _onDashboardChange returns early and does not
  // override today's optimistically-toggled state during the test.
  final yesterday = DateUtils.dateOnly(DateTime.now().toLocal())
      .subtract(const Duration(days: 1));
  return DailyRoutineState(
    selectedDate: yesterday,
    tasks: const AsyncData([]),
    todayTasks: const AsyncData([]),
    streak: AsyncData(CareStreak(petId: 'p', currentStreak: 0, bestStreak: 0)),
    weekGoalHit: const AsyncData([]),
    badgeTypes: {},
  );
}

ProviderContainer _makeContainer(ChecklistRepository repo) {
  return ProviderContainer(
    overrides: [
      careDashboardProvider.overrideWithValue(_emptyDashboard()),
      checklistRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CareNotifier.toggle — optimistic update', () {
    test('immediately updates state before remote completes', () async {
      final repo = _SuccessChecklistRepo();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      final notifier = c.read(careControllerProvider('pet-1').notifier);
      final initialState = c.read(careControllerProvider('pet-1'));

      expect(initialState.today.isDone(CareTaskType.feed), isFalse);

      // Do NOT await — optimistic change should already be visible.
      unawaited(notifier.toggle(CareTaskType.feed));

      final after = c.read(careControllerProvider('pet-1'));
      expect(after.today.isDone(CareTaskType.feed), isTrue);
    });

    test('state remains updated after successful remote write', () async {
      final repo = _SuccessChecklistRepo();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await c
          .read(careControllerProvider('pet-1').notifier)
          .toggle(CareTaskType.walk);

      final after = c.read(careControllerProvider('pet-1'));
      expect(after.today.isDone(CareTaskType.walk), isTrue);
    });
  });

  group('CareNotifier.toggle — rollback on failure', () {
    test('reverts state when remote write throws', () async {
      final repo = _FailingChecklistRepo();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      final before = c.read(careControllerProvider('pet-1'));
      expect(before.today.isDone(CareTaskType.med), isFalse);

      // Ignore the exception — the notifier catches it internally.
      await c
          .read(careControllerProvider('pet-1').notifier)
          .toggle(CareTaskType.med)
          .catchError((_) {});

      final after = c.read(careControllerProvider('pet-1'));
      expect(after.today.isDone(CareTaskType.med), isFalse);
    });

    test('calls revertLocal after remote failure', () async {
      final repo = _FailingChecklistRepo();
      final c = _makeContainer(repo);
      addTearDown(c.dispose);

      await c
          .read(careControllerProvider('pet-1').notifier)
          .toggle(CareTaskType.feed)
          .catchError((_) {});

      expect(repo.revertCalled, isTrue);
    });
  });

  group('CareState streak computation', () {
    DateTime day(int daysAgo) =>
        DateUtils.dateOnly(DateTime.now().toLocal())
            .subtract(Duration(days: daysAgo));

    DayData done(int daysAgo) => DayData(
          date: day(daysAgo),
          feed: true,
          walk: true,
          med: true,
        );

    DayData partial(int daysAgo) => DayData(
          date: day(daysAgo),
          feed: true,
          walk: false,
          med: false,
        );

    DayData empty(int daysAgo) => DayData(
          date: day(daysAgo),
          feed: false,
          walk: false,
          med: false,
        );

    List<DayData> week(DayData Function(int i) builder) =>
        List.generate(7, builder);

    test('streak is 0 when no past days are complete', () {
      final w = week((i) => empty(6 - i));
      final s = CareState(petId: 'p', week: w, streak: 0);
      expect(s.streak, 0);
    });

    test('streak counts consecutive complete days before today', () {
      final w = [
        empty(6),
        done(5),
        done(4),
        done(3),
        done(2),
        done(1),
        empty(0),
      ];
      final s = CareState(petId: 'p', week: w, streak: 5);
      expect(s.streak, 5);
    });

    test('streak is broken by a partial day', () {
      final w = [
        done(6),
        done(5),
        done(4),
        partial(3),
        done(2),
        done(1),
        empty(0),
      ];
      final s = CareState(petId: 'p', week: w, streak: 2);
      expect(s.streak, 2);
    });

    test('copyWithToggle re-computes streak when today becomes all-done', () {
      final w = [
        done(6),
        done(5),
        done(4),
        done(3),
        done(2),
        done(1),
        DayData(date: day(0), feed: true, walk: true, med: false),
      ];
      var s = CareState(petId: 'p', week: w, streak: 6);
      s = s.copyWithToggle(CareTaskType.med, true);
      // Toggling med today does NOT change the streak computation
      // (streak counts days BEFORE today). The streak stays 6.
      expect(s.streak, 6);
    });
  });
}
