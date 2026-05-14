import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/care_task.dart';
import '../../data/repositories/care_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DailyRoutineState {
  const DailyRoutineState({
    required this.selectedDate,
    required this.tasks,
  });

  final DateTime selectedDate;
  final AsyncValue<List<CareTask>> tasks;

  DailyRoutineState copyWith({
    DateTime? selectedDate,
    AsyncValue<List<CareTask>>? tasks,
  }) =>
      DailyRoutineState(
        selectedDate: selectedDate ?? this.selectedDate,
        tasks: tasks ?? this.tasks,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final careDashboardProvider =
    NotifierProvider.family<CareDashboardNotifier, DailyRoutineState, String>(
  CareDashboardNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class CareDashboardNotifier
    extends FamilyNotifier<DailyRoutineState, String> {
  @override
  DailyRoutineState build(String petId) {
    final today = DateUtils.dateOnly(DateTime.now());
    Future.microtask(() => _load(petId, today));
    return DailyRoutineState(
      selectedDate: today,
      tasks: const AsyncLoading(),
    );
  }

  CareTaskRepository get _repo => ref.read(careTaskRepositoryProvider);

  Future<void> _load(String petId, DateTime date) async {
    state = state.copyWith(tasks: const AsyncLoading());
    state = state.copyWith(
      tasks: await AsyncValue.guard(
        () => _repo.fetchTasksForDate(petId, date),
      ),
    );
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = DateUtils.dateOnly(date);
    if (normalized == state.selectedDate) return;
    state = state.copyWith(
      selectedDate: normalized,
      tasks: const AsyncLoading(),
    );
    await _load(arg, normalized);
  }

  Future<void> refresh() => _load(arg, state.selectedDate);

  Future<void> createTask(CareTask task) async {
    await _repo.createTask(task);
    await _load(arg, state.selectedDate);
  }

  Future<void> toggleTask(String taskId, {required bool isCompleted}) async {
    final prev = state.tasks.valueOrNull;
    if (prev == null) return;

    // Optimistic update
    state = state.copyWith(
      tasks: AsyncData(
        prev
            .map((t) => t.id == taskId
                ? t.copyWith(
                    isCompleted: isCompleted,
                    completedAt: isCompleted ? DateTime.now() : null,
                    updatedAt: DateTime.now(),
                  )
                : t)
            .toList(),
      ),
    );

    try {
      final updated = await _repo.toggleCompletion(
        taskId,
        isCompleted: isCompleted,
      );
      final current = state.tasks.valueOrNull ?? prev;
      state = state.copyWith(
        tasks: AsyncData(
          current.map((t) => t.id == taskId ? updated : t).toList(),
        ),
      );
    } catch (_) {
      state = state.copyWith(tasks: AsyncData(prev));
    }
  }
}
