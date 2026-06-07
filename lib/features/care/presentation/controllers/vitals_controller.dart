import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/weight_log.dart';
import '../../data/repositories/vitals_repository.dart';

class VitalsNotifier extends AsyncNotifier<List<WeightLog>> {
  @override
  Future<List<WeightLog>> build() async {
    final petId = ref.watch(activePetIdProvider);
    if (petId == null) return const [];
    return ref.read(vitalsRepositoryProvider).fetchWeightLogs(petId);
  }

  Future<void> addLog({
    required String petId,
    required double weightKg,
    DateTime? recordedAt,
    String? notes,
  }) async {
    final repo = ref.read(vitalsRepositoryProvider);
    final log = await repo.addWeightLog(
      petId: petId,
      weightKg: weightKg,
      recordedAt: recordedAt ?? DateTime.now(),
      notes: notes,
    );
    state = state.whenData((logs) => [log, ...logs]);
  }

  Future<void> deleteLog(String id) async {
    final repo = ref.read(vitalsRepositoryProvider);
    await repo.deleteWeightLog(id);
    state = state.whenData((logs) => logs.where((l) => l.id != id).toList());
  }
}

final vitalsNotifierProvider =
    AsyncNotifierProvider.autoDispose<VitalsNotifier, List<WeightLog>>(
  VitalsNotifier.new,
);
