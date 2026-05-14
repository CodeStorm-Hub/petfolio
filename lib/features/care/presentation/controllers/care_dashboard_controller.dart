import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/care_streak.dart';
import '../../data/models/care_task.dart';
import '../../data/repositories/care_repository.dart';
import 'care_streak_stream_provider.dart';

class DailyRoutineState {
  const DailyRoutineState({
    required this.selectedDate,
    required this.tasks,
    required this.todayTasks,
    required this.streak,
    required this.weekGoalHit,
    required this.badgeTypes,
  });

  final DateTime selectedDate;
  final AsyncValue<List<CareTask>> tasks;
  final AsyncValue<List<CareTask>> todayTasks;
  final AsyncValue<CareStreak> streak;
  final AsyncValue<List<bool>> weekGoalHit;
  final Set<String> badgeTypes;

  DailyRoutineState copyWith({
    DateTime? selectedDate,
    AsyncValue<List<CareTask>>? tasks,
    AsyncValue<List<CareTask>>? todayTasks,
    AsyncValue<CareStreak>? streak,
    AsyncValue<List<bool>>? weekGoalHit,
    Set<String>? badgeTypes,
  }) =>
      DailyRoutineState(
        selectedDate: selectedDate ?? this.selectedDate,
        tasks: tasks ?? this.tasks,
        todayTasks: todayTasks ?? this.todayTasks,
        streak: streak ?? this.streak,
        weekGoalHit: weekGoalHit ?? this.weekGoalHit,
        badgeTypes: badgeTypes ?? this.badgeTypes,
      );
}

final careDashboardProvider =
    NotifierProvider<CareDashboardNotifier, DailyRoutineState>(
  CareDashboardNotifier.new,
);

class CareDashboardNotifier extends Notifier<DailyRoutineState> {
  String? _syncedPetId;
  DateTime? _lastSelectedDate;
  Set<String> _badgeBaseline = {};
  final Set<String> _hydratedBadgePets = {};

  DailyRoutineState _routine = DailyRoutineState(
    selectedDate: DateUtils.dateOnly(DateTime.now()),
    tasks: const AsyncData([]),
    todayTasks: const AsyncData([]),
    streak: const AsyncLoading(),
    weekGoalHit: const AsyncLoading(),
    badgeTypes: {},
  );

  List<DateTime> _weekEndingToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  }

  AsyncValue<CareStreak> _streakAsync(AsyncValue<CareStreak> raw) =>
      raw.when(
        data: AsyncData.new,
        loading: () => const AsyncLoading<CareStreak>(),
        error: AsyncError.new,
      );

  @override
  DailyRoutineState build() {
    final petId = ref.watch(activePetIdProvider);
    final today = DateUtils.dateOnly(DateTime.now());

    if (petId == null) {
      _syncedPetId = null;
      _lastSelectedDate = today;
      _badgeBaseline = {};
      _hydratedBadgePets.clear();
      _routine = DailyRoutineState(
        selectedDate: today,
        tasks: const AsyncData([]),
        todayTasks: const AsyncData([]),
        streak: const AsyncLoading(),
        weekGoalHit: const AsyncLoading(),
        badgeTypes: {},
      );
      return _routine;
    }

    final streakState =
        _streakAsync(ref.watch(careStreakRealtimeProvider(petId)));

    if (petId != _syncedPetId) {
      final previousPet = _syncedPetId;
      _syncedPetId = petId;
      final selectedDate =
          previousPet == null ? today : (_lastSelectedDate ?? today);
      _lastSelectedDate = selectedDate;
      _routine = DailyRoutineState(
        selectedDate: selectedDate,
        tasks: const AsyncLoading(),
        todayTasks: const AsyncLoading(),
        streak: streakState,
        weekGoalHit: const AsyncLoading(),
        badgeTypes: {},
      );
      Future.microtask(() => _load(petId, selectedDate));
      return _routine;
    }

    _routine = _routine.copyWith(streak: streakState);
    return _routine;
  }

  CareTaskRepository get _repo => ref.read(careTaskRepositoryProvider);

  void _applyBadgeDelta(String petId, Set<String> next) {
    if (!_hydratedBadgePets.contains(petId)) {
      _hydratedBadgePets.add(petId);
      _badgeBaseline = Set<String>.from(next);
      return;
    }
    final newlyHasHero =
        next.contains('7_day_hero') && !_badgeBaseline.contains('7_day_hero');
    if (newlyHasHero) {
      AppSnackBar.showBadgeUnlocked();
    }
    _badgeBaseline = Set<String>.from(next);
  }

  Future<void> _load(String petId, DateTime date) async {
    if (ref.read(activePetIdProvider) != petId) return;
    _routine = _routine.copyWith(
      tasks: const AsyncLoading(),
      todayTasks: const AsyncLoading(),
      weekGoalHit: const AsyncLoading(),
    );
    state = _routine;
    final weekDates = _weekEndingToday();
    final dSel = DateUtils.dateOnly(date);
    final dToday = DateUtils.dateOnly(DateTime.now());
    final tasksFuture = _repo.fetchTasksForDate(petId, dSel);
    final todayTasksFuture = dSel == dToday
        ? tasksFuture
        : _repo.fetchTasksForDate(petId, dToday);
    final badgesFuture = _repo.fetchPetBadgeTypes(petId);
    final weekFuture = _repo.fetchDailyGoalsHitForDates(petId, weekDates);

    final tasks = await AsyncValue.guard(() => tasksFuture);
    if (ref.read(activePetIdProvider) != petId) return;

    final todayTasks = dSel == dToday
        ? tasks
        : await AsyncValue.guard(() => todayTasksFuture);

    Set<String> badges = {};
    try {
      badges = await badgesFuture;
    } catch (_) {}

    List<bool> weekHit = List.filled(7, false);
    try {
      final raw = await weekFuture;
      weekHit = List<bool>.generate(
        7,
        (i) => i < raw.length ? raw[i] : false,
      );
    } catch (_) {}

    _applyBadgeDelta(petId, badges);

    _routine = _routine.copyWith(
      tasks: tasks,
      todayTasks: todayTasks,
      weekGoalHit: AsyncData(weekHit),
      badgeTypes: badges,
    );
    state = _routine;
    _lastSelectedDate = _routine.selectedDate;
  }

  Future<void> selectDate(DateTime date) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final normalized = DateUtils.dateOnly(date);
    if (normalized == _routine.selectedDate) return;
    _routine = _routine.copyWith(
      selectedDate: normalized,
      tasks: const AsyncLoading(),
      todayTasks: const AsyncLoading(),
    );
    state = _routine;
    _lastSelectedDate = normalized;
    await _load(petId, normalized);
  }

  Future<void> refresh() async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    await _load(petId, _routine.selectedDate);
  }

  Future<void> createTask(CareTask task) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    await _repo.createTask(task);
    if (ref.read(activePetIdProvider) != petId) return;
    await _load(petId, _routine.selectedDate);
  }

  Future<void> toggleTaskCompletion(
    String taskId, {
    required bool isCompleted,
  }) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final prev = _routine.tasks.valueOrNull;
    if (prev == null) return;

    final nextList = prev
        .map((t) => t.id == taskId
            ? t.copyWith(
                isCompleted: isCompleted,
                completedAt: isCompleted ? DateTime.now() : null,
                updatedAt: DateTime.now(),
              )
            : t)
        .toList();
    final today = DateUtils.dateOnly(DateTime.now());
    _routine = _routine.copyWith(
      tasks: AsyncData(nextList),
      todayTasks: _routine.selectedDate == today
          ? AsyncData(nextList)
          : _routine.todayTasks,
    );
    state = _routine;

    try {
      final outcome = await _repo.toggleCompletion(
        taskId,
        isCompleted: isCompleted,
        petId: petId,
        forDay: _routine.selectedDate,
      );
      if (ref.read(activePetIdProvider) != petId) return;
      final current = _routine.tasks.valueOrNull ?? prev;
      final nextAfter = current
          .map((t) => t.id == taskId ? outcome.task : t)
          .toList();
      _routine = _routine.copyWith(
        tasks: AsyncData(nextAfter),
        todayTasks: _routine.selectedDate == today
            ? AsyncData(nextAfter)
            : _routine.todayTasks,
      );
      state = _routine;
      if (outcome.badgeUnlocked) {
        AppSnackBar.showBadgeUnlocked();
        _badgeBaseline = {..._badgeBaseline, '7_day_hero'};
      }
      await _load(petId, _routine.selectedDate);
    } catch (e) {
      if (ref.read(activePetIdProvider) == petId) {
        _routine = _routine.copyWith(
          tasks: AsyncData(prev),
          todayTasks: _routine.selectedDate == DateUtils.dateOnly(DateTime.now())
              ? AsyncData(prev)
              : _routine.todayTasks,
        );
        state = _routine;
        AppSnackBar.showError(e);
      }
    }
  }
}
