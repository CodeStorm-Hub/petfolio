import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/health_log.dart';
import '../../data/repositories/health_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NutritionState {
  const NutritionState({required this.history});

  final AsyncValue<List<HealthLog>> history;

  NutritionState copyWith({AsyncValue<List<HealthLog>>? history}) =>
      NutritionState(history: history ?? this.history);
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final nutritionProvider =
    NotifierProvider.family<NutritionNotifier, NutritionState, String>(
  NutritionNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NutritionNotifier extends FamilyNotifier<NutritionState, String> {
  @override
  NutritionState build(String petId) {
    Future.microtask(() => _load(petId));
    return const NutritionState(history: AsyncLoading());
  }

  HealthRepository get _repo => ref.read(healthRepositoryProvider);

  Future<void> _load(String petId) async {
    state = state.copyWith(history: const AsyncLoading());
    state = state.copyWith(
      history: await AsyncValue.guard(
        () => _repo.fetchWeightHistory(petId),
      ),
    );
  }

  Future<void> refresh() => _load(arg);

  Future<void> logWeight(
    double kg, {
    String? notes,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();
    final trimmedNotes = notes?.trim();
    final log = HealthLog(
      id: '',
      petId: arg,
      recordedBy: '',
      logType: HealthLogType.weight,
      title: 'Weight log',
      description: (trimmedNotes?.isEmpty ?? true) ? null : trimmedNotes,
      weightKg: kg,
      occurredAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.createLog(log);
    await _load(arg);
  }
}
