import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/app_snack_bar.dart';

import 'package:petfolio/core/domain/controllers/active_pet_controller.dart';
import '../../data/models/medical_record.dart';
import '../../data/repositories/health_repository.dart';

final healthVaultControllerProvider = StreamNotifierProvider<
    HealthVaultController, List<MedicalRecord>>(
  HealthVaultController.new,
);

class HealthVaultController extends StreamNotifier<List<MedicalRecord>> {
  @override
  Stream<List<MedicalRecord>> build() {
    final petId = ref.watch(activePetIdProvider);
    if (petId == null) {
      return Stream.value(<MedicalRecord>[]);
    }
    return Supabase.instance.client
        .from('medical_vault')
        .stream(primaryKey: ['id'])
        .eq('pet_id', petId)
        .map((rows) {
          final records = rows
              .where((r) => r['is_active'] == true)
              .map(MedicalRecord.fromJson)
              .toList()
            ..sort((a, b) {
              final DateTime? keyA = a.nextDueAt ?? a.expiresAt ?? a.administeredAt;
              final DateTime? keyB = b.nextDueAt ?? b.expiresAt ?? b.administeredAt;
              if (keyA == null && keyB == null) return 0;
              if (keyA == null) return 1;
              if (keyB == null) return -1;
              return keyA.compareTo(keyB);
            });
          return records;
        });
  }

  MedicalVaultRepository get _repo => ref.read(medicalVaultRepositoryProvider);

  Future<bool> addRecord(MedicalRecord record) async {
    final prevState = state;

    state = state.whenData((records) => [record, ...records]);

    try {
      final created = await _repo.createRecord(record);
      state = state.whenData((records) => [
            for (final r in records)
              if (r.id == record.id) created else r,
          ]);
      return true;
    } catch (e, st) {
      debugPrint(
          '[HealthVaultController] addRecord failed, reverting: $e\n$st');
      state = prevState;
      AppSnackBar.showError(e);
      return false;
    }
  }

  Future<void> updateRecord(MedicalRecord record) async {
    final prevState = state;

    state = state.whenData((records) => [
          for (final r in records)
            if (r.id == record.id) record else r,
        ]);

    try {
      final updated = await _repo.updateRecord(record);
      state = state.whenData((records) => [
            for (final r in records)
              if (r.id == updated.id) updated else r,
          ]);
    } catch (e, st) {
      debugPrint(
          '[HealthVaultController] updateRecord failed, reverting: $e\n$st');
      state = prevState;
      AppSnackBar.showError(e);
    }
  }

  Future<void> deactivateRecord(String recordId) async {
    final prevState = state;

    state = state.whenData(
      (records) => records.where((r) => r.id != recordId).toList(),
    );

    try {
      await _repo.deactivateRecord(recordId);
    } catch (e, st) {
      debugPrint(
          '[HealthVaultController] deactivateRecord failed, reverting: $e\n$st');
      state = prevState;
      AppSnackBar.showError(e);
    }
  }
}
