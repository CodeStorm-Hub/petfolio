import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/app_snack_bar.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/medical_record.dart';
import '../../data/repositories/health_repository.dart';

final healthVaultControllerProvider =
    StreamNotifierProvider.autoDispose<HealthVaultController, List<MedicalRecord>>(
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
        .limit(100)
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
          _syncMedicationReminders(records);
          return records;
        });
  }

  void _syncMedicationReminders(List<MedicalRecord> records) {
    final svc = NotificationService.instance;
    for (final r in records) {
      if (r.reminderEnabled && r.nextDueAt != null) {
        svc
            .scheduleMedicationDueReminder(
              recordId: r.id,
              medicationName: r.name,
              nextDue: r.nextDueAt!,
            )
            .ignore();
      } else {
        svc.cancelMedicationReminder(r.id).ignore();
      }
    }
  }

  MedicalVaultRepository get _repo => ref.read(medicalVaultRepositoryProvider);

  Future<bool> addRecord(MedicalRecord record) async {
    // Use a sentinel ID so the replacement loop can find the optimistic entry
    // even after the realtime stream delivers the real row.
    const sentinelId = '_tmp_optimistic_';
    final optimistic = record.copyWith(id: sentinelId);
    final prevState = state;

    state = state.whenData((records) => [optimistic, ...records]);

    try {
      final created = await _repo.createRecord(record);
      // Replace the sentinel with the server-assigned record. If the realtime
      // stream already delivered the real row before we get here, the sentinel
      // will be gone and the loop is a no-op — the stream's state wins.
      state = state.whenData((records) {
        final hasSentinel = records.any((r) => r.id == sentinelId);
        if (!hasSentinel) return records; // stream already applied the real row
        return [
          for (final r in records)
            if (r.id == sentinelId) created else r,
        ];
      });
      return true;
    } catch (e, st) {
      debugPrint('[HealthVaultController] addRecord failed: $e\n$st');
      // Only roll back if the sentinel is still present (stream hasn't
      // overwritten state with a partial result).
      state = state.whenData((records) {
        final hasSentinel = records.any((r) => r.id == sentinelId);
        if (hasSentinel) return prevState.value ?? records;
        return records;
      });
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
