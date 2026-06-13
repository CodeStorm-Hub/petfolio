import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/weight_log.dart';
import '../../data/repositories/vitals_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NutritionState {
  const NutritionState({required this.history});

  final AsyncValue<List<WeightLog>> history;

  NutritionState copyWith({AsyncValue<List<WeightLog>>? history}) =>
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

class NutritionNotifier extends Notifier<NutritionState> {
  NutritionNotifier(this.arg);
  final String arg;

  @override
  NutritionState build() {
    Future.microtask(() => _load(arg));
    return const NutritionState(history: AsyncLoading());
  }

  VitalsRepository get _repo => ref.read(vitalsRepositoryProvider);

  Future<void> _load(String petId) async {
    state = state.copyWith(
      history: await AsyncValue.guard(() async {
        final logs = await _repo.fetchWeightLogs(petId, limit: 90);
        return logs.reversed.toList(); // ascending for chart
      }),
    );
  }

  Future<void> refresh() => _load(arg);

  Future<void> logWeight(
    double kg, {
    String? notes,
    DateTime? date,
  }) async {
    await _repo.addWeightLog(
      petId: arg,
      weightKg: kg,
      recordedAt: date ?? DateTime.now(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
    await _load(arg);
  }
}
