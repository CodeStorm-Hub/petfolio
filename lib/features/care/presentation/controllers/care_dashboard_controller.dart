import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/care_streak.dart';
import '../../data/models/care_task.dart';
import '../../data/repositories/care_repository.dart';
import 'care_streak_stream_provider.dart';
import 'pet_awards_provider.dart';

part 'care_dashboard_controller.g.dart';

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

const _kCompletionCountKey = 'care_completion_count';
const _kReviewRequestedKey = 'care_review_requested';
const _kReviewThreshold = 3;

@Riverpod(keepAlive: true)
class CareDashboard extends _$CareDashboard {
  String? _syncedPetId;
  DateTime? _lastSelectedDate;
  Set<String> _badgeBaseline = {};
  final Set<String> _hydratedBadgePets = {};

  DailyRoutineState _routine = DailyRoutineState(
    selectedDate: DateUtils.dateOnly(DateTime.now().toLocal()),
    tasks: const AsyncData([]),
    todayTasks: const AsyncData([]),
    streak: const AsyncLoading(),
    weekGoalHit: const AsyncLoading(),
    badgeTypes: {},
  );

  List<DateTime> _weekEndingOn(DateTime endDay) {
    final end = DateUtils.dateOnly(endDay);
    return List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
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
    final today = DateUtils.dateOnly(DateTime.now().toLocal());

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
    final newBadges = next.difference(_badgeBaseline);
    _badgeBaseline = Set<String>.from(next);

    if (newBadges.isEmpty) return;

    if (!_hydratedBadgePets.contains(petId)) {
      // First load for this pet in this session: coalesce all new badges into
      // a single notification to avoid a storm of snackbars on cold start.
      _hydratedBadgePets.add(petId);
      if (newBadges.length == 1) {
        AppSnackBar.showBadgeUnlocked(newBadges.first);
      } else {
        AppSnackBar.show('${newBadges.length} badges unlocked! 🏆');
      }
      return;
    }

    // Subsequent loads: show each badge individually (incremental unlock).
    for (final badge in newBadges) {
      AppSnackBar.showBadgeUnlocked(badge);
    }
  }

  Future<void> _load(String petId, DateTime date) async {
    if (ref.read(activePetIdProvider) != petId) return;
    _routine = _routine.copyWith(
      tasks: const AsyncLoading(),
      todayTasks: const AsyncLoading(),
      weekGoalHit: const AsyncLoading(),
    );
    state = _routine;

    final dSel = DateUtils.dateOnly(date);
    final weekDates = _weekEndingOn(dSel);

    try {
      final snapshot = await _repo.fetchDashboardSnapshot(
        petId: petId,
        selectedDate: dSel,
        weekDates: weekDates,
      );
      if (ref.read(activePetIdProvider) != petId) return;

      _applyBadgeDelta(petId, snapshot.badgeTypes);

      _routine = _routine.copyWith(
        tasks: AsyncData(snapshot.tasks),
        todayTasks: AsyncData(snapshot.todayTasks),
        weekGoalHit: AsyncData(snapshot.weekGoalHit),
        badgeTypes: snapshot.badgeTypes,
      );
      state = _routine;
      _lastSelectedDate = _routine.selectedDate;
    } catch (e, st) {
      debugPrint('[CareDashboard] snapshot fetch failed: $e');
      if (ref.read(activePetIdProvider) != petId) return;
      _routine = _routine.copyWith(
        tasks: AsyncError(e, st),
        todayTasks: AsyncError(e, st),
        weekGoalHit: AsyncError(e, st),
      );
      state = _routine;
      AppSnackBar.showError(e);
    }
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

  Future<void> bulkCreateTasks(
    List<CareTask> tasks, {
    bool isAiSuggested = false,
  }) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null || tasks.isEmpty) return;
    await _repo.bulkCreateTasks(tasks, isAiSuggested: isAiSuggested);
    if (ref.read(activePetIdProvider) != petId) return;
    await _load(petId, _routine.selectedDate);
  }

  Future<void> updateTask(CareTask task) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null || task.petId != petId) return;
    await _repo.updateTask(task);
    if (ref.read(activePetIdProvider) != petId) return;
    await _load(petId, _routine.selectedDate);
  }

  Future<void> deleteTask(String taskId) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    await _repo.deleteTask(taskId);
    if (ref.read(activePetIdProvider) != petId) return;
    await _load(petId, _routine.selectedDate);
  }

  Future<void> toggleTaskCompletion(
    String taskId, {
    required bool isCompleted,
  }) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final prev = _routine.tasks.value;
    if (prev == null) return;

    final localTask = prev.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw StateError('Task $taskId not in dashboard state'),
    );
    final careType = _repo.taskTypeToCareType(localTask.taskType);

    final nextList = prev
        .map((t) => t.id == taskId
            ? t.copyWith(
                isCompleted: isCompleted,
                completedAt: isCompleted ? DateTime.now() : null,
                updatedAt: DateTime.now(),
              )
            : t)
        .toList();
    final today = DateUtils.dateOnly(DateTime.now().toLocal());
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
        careType: careType,
        forDay: _routine.selectedDate,
        localTask: localTask,
      );
      if (ref.read(activePetIdProvider) != petId) return;
      final current = _routine.tasks.value ?? prev;
      final nextAfter = current
          .map((t) => t.id == taskId ? outcome.task : t)
          .toList();
      _routine = _routine.copyWith(
        tasks: AsyncData(nextAfter),
        todayTasks: _routine.selectedDate == today
            ? AsyncData(nextAfter)
            : _routine.todayTasks,
        badgeTypes: _badgeBaseline,
      );
      state = _routine;
      if (isCompleted) {
        ref.invalidate(petAwardsSummaryProvider(petId));
        _maybeRequestReview();
      }
      if (outcome.badgeUnlocked && outcome.unlockedBadges.isNotEmpty) {
        for (final badge in outcome.unlockedBadges) {
          AppSnackBar.showBadgeUnlocked(badge);
        }
        _badgeBaseline = {..._badgeBaseline, ...outcome.unlockedBadges};
        _routine = _routine.copyWith(badgeTypes: _badgeBaseline);
        state = _routine;
      } else if (outcome.badgeUnlocked) {
        AppSnackBar.showBadgeUnlocked();
        _badgeBaseline = {..._badgeBaseline, '7_day_hero'};
        _routine = _routine.copyWith(badgeTypes: _badgeBaseline);
        state = _routine;
      }
          // State is already correctly synced from outcome.task above.
      // Streak updates arrive via careStreakRealtimeProvider.
      // A full _load() reload is intentionally skipped here to avoid
      // wiping and re-fetching the entire dashboard on every tap.
    } catch (e) {
      if (ref.read(activePetIdProvider) == petId) {
        _routine = _routine.copyWith(
          tasks: AsyncData(prev),
          todayTasks: _routine.selectedDate == DateUtils.dateOnly(DateTime.now().toLocal())
              ? AsyncData(prev)
              : _routine.todayTasks,
        );
        state = _routine;
        AppSnackBar.showError(e);
      }
    }
  }

  Future<void> _maybeRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_kReviewRequestedKey) ?? false;
    if (alreadyRequested) return;

    final count = (prefs.getInt(_kCompletionCountKey) ?? 0) + 1;
    await prefs.setInt(_kCompletionCountKey, count);

    if (count >= _kReviewThreshold) {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
        await prefs.setBool(_kReviewRequestedKey, true);
      }
    }
  }
}
