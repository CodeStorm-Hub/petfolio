import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/care_task.dart';
import '../../data/repositories/care_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final careDashboardControllerProvider = AsyncNotifierProvider.family<
    CareDashboardController, List<CareTask>, String>(
  CareDashboardController.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CareDashboardController
    extends FamilyAsyncNotifier<List<CareTask>, String> {
  @override
  Future<List<CareTask>> build(String petId) => _repo.fetchTasksForDate(
        petId,
        DateUtils.dateOnly(DateTime.now()),
      );

  CareTaskRepository get _repo => ref.read(careTaskRepositoryProvider);

  /// Optimistically marks a task complete or incomplete, then syncs to Supabase.
  ///
  /// Steps:
  ///   1. Patch state immediately so the UI reflects the change on the next frame.
  ///   2. Await the remote toggle; on success, replace the optimistic row with
  ///      the DB-authoritative version (server-assigned timestamps).
  ///   3. On any failure, restore the previous state so no phantom change remains.
  Future<void> toggleCompletion(
    String taskId, {
    required bool isCompleted,
  }) async {
    final prevState = state;

    state = state.whenData((tasks) => [
          for (final t in tasks)
            if (t.id == taskId)
              isCompleted ? t.markCompleted() : t.reset()
            else
              t,
        ]);

    try {
      final updated =
          await _repo.toggleCompletion(taskId, isCompleted: isCompleted);

      state = state.whenData((tasks) => [
            for (final t in tasks)
              if (t.id == updated.id) updated else t,
          ]);
    } catch (e, st) {
      debugPrint(
          '[CareDashboardController] toggleCompletion failed, reverting: $e\n$st');
      state = prevState;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.fetchTasksForDate(arg, DateUtils.dateOnly(DateTime.now())),
    );
  }
}
