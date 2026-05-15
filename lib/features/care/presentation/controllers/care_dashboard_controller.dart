import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/care_task.dart';
import '../../data/repositories/care_repository.dart';

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

final careDashboardProvider =
    NotifierProvider<CareDashboardNotifier, DailyRoutineState>(
  CareDashboardNotifier.new,
);

class CareDashboardNotifier extends Notifier<DailyRoutineState> {
  String? _syncedPetId;
  DateTime? _lastSelectedDate;

  @override
  DailyRoutineState build() {
    final petId = ref.watch(activePetIdProvider);
    final today = DateUtils.dateOnly(DateTime.now());

    if (petId == null) {
      _syncedPetId = null;
      _lastSelectedDate = today;
      return DailyRoutineState(
        selectedDate: today,
        tasks: const AsyncData([]),
      );
    }

    if (petId != _syncedPetId) {
      final previousPet = _syncedPetId;
      _syncedPetId = petId;
      final selectedDate =
          previousPet == null ? today : (_lastSelectedDate ?? today);
      _lastSelectedDate = selectedDate;
      Future.microtask(() => _load(petId, selectedDate));
      return DailyRoutineState(
        selectedDate: selectedDate,
        tasks: const AsyncLoading(),
      );
    }

    return state;
  }

  CareTaskRepository get _repo => ref.read(careTaskRepositoryProvider);

  Future<void> _load(String petId, DateTime date) async {
    if (ref.read(activePetIdProvider) != petId) return;
    state = state.copyWith(tasks: const AsyncLoading());
    final tasks = await AsyncValue.guard(
      () => _repo.fetchTasksForDate(petId, date),
    );
    if (ref.read(activePetIdProvider) != petId) return;
    state = state.copyWith(tasks: tasks);
    _lastSelectedDate = state.selectedDate;
  }

  Future<void> selectDate(DateTime date) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final normalized = DateUtils.dateOnly(date);
    if (normalized == state.selectedDate) return;
    state = state.copyWith(
      selectedDate: normalized,
      tasks: const AsyncLoading(),
    );
    _lastSelectedDate = normalized;
    await _load(petId, normalized);
  }

  Future<void> refresh() async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    await _load(petId, state.selectedDate);
  }

  Future<void> createTask(CareTask task) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    await _repo.createTask(task);
    if (ref.read(activePetIdProvider) != petId) return;
    await _load(petId, state.selectedDate);
  }

  Future<void> toggleTaskCompletion(
    String taskId, {
    required bool isCompleted,
  }) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final prev = state.tasks.valueOrNull;
    if (prev == null) return;

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
      if (ref.read(activePetIdProvider) != petId) return;
      final current = state.tasks.valueOrNull ?? prev;
      state = state.copyWith(
        tasks: AsyncData(
          current.map((t) => t.id == taskId ? updated : t).toList(),
        ),
      );
    } catch (e) {
      if (ref.read(activePetIdProvider) == petId) {
        state = state.copyWith(tasks: AsyncData(prev));
        AppSnackBar.showError(e);
      }
    }
  }
}
