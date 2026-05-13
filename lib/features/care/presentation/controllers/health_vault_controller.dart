import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/medical_record.dart';
import '../../data/repositories/health_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final healthVaultControllerProvider = StreamNotifierProvider.family<
    HealthVaultController, List<MedicalRecord>, String>(
  HealthVaultController.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class HealthVaultController
    extends FamilyStreamNotifier<List<MedicalRecord>, String> {
  /// Opens a Supabase realtime subscription for the active pet's medical vault.
  ///
  /// Emits whenever a row is inserted, updated, or deleted in `medical_vault`
  /// for this pet (requires Supabase Realtime to be enabled for the table).
  /// Active records are filtered client-side and sorted by next due date so
  /// overdue items surface at the top.
  @override
  Stream<List<MedicalRecord>> build(String petId) {
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
              if (a.nextDueAt == null) return 1;
              if (b.nextDueAt == null) return -1;
              return a.nextDueAt!.compareTo(b.nextDueAt!);
            });
          return records;
        });
  }

  MedicalVaultRepository get _repo => ref.read(medicalVaultRepositoryProvider);

  // ── Add ─────────────────────────────────────────────────────────────────────

  /// Optimistically prepends [record] then awaits the Supabase insert.
  ///
  /// On success the optimistic entry is replaced with the server-authoritative
  /// row (which carries the DB-assigned id and timestamps). On failure the
  /// previous state is restored. The realtime stream will auto-reconcile if the
  /// insert succeeded before the error surface reached the UI.
  Future<void> addRecord(MedicalRecord record) async {
    final prevState = state;

    state = state.whenData((records) => [record, ...records]);

    try {
      final created = await _repo.createRecord(record);
      state = state.whenData((records) => [
            for (final r in records)
              if (r.id == record.id) created else r,
          ]);
    } catch (e, st) {
      debugPrint(
          '[HealthVaultController] addRecord failed, reverting: $e\n$st');
      state = prevState;
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

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
    }
  }

  // ── Deactivate (soft delete) ─────────────────────────────────────────────────

  /// Soft-deletes by setting `is_active = false`.
  ///
  /// Optimistically removes the record from the active list immediately.
  /// The realtime stream will not re-emit the deactivated row because it is
  /// filtered out by `is_active == true` in [build]. On failure the record is
  /// restored to the list at its original position.
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
    }
  }
}
