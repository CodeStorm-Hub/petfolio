import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/medical_record.dart';
import '../../data/models/medication_log.dart';
import '../../data/repositories/health_repository.dart';

class MedicationAdherence {
  const MedicationAdherence({
    required this.record,
    required this.dosesToday,
    this.lastGivenAt,
  });

  final MedicalRecord record;
  final int dosesToday;
  final DateTime? lastGivenAt;
}

final medicationsControllerProvider = AsyncNotifierProvider.family<
    MedicationsController, List<MedicationAdherence>, String>(
  MedicationsController.new,
);

class MedicationsController
    extends AsyncNotifier<List<MedicationAdherence>> {
  MedicationsController(this.arg);

  final String arg;

  @override
  Future<List<MedicationAdherence>> build() => _load();

  Future<List<MedicationAdherence>> _load() async {
    final vault = ref.read(medicalVaultRepositoryProvider);
    final logs = ref.read(medicationLogRepositoryProvider);

    final records = await vault.fetchRecordsForPet(arg);
    final meds = records
        .where((r) =>
            r.recordType == MedicalRecordType.medication && r.isActive)
        .toList();

    final todayLogs = await logs.fetchTodayLogs(arg);
    final byRecord = <String, List<MedicationLog>>{};
    for (final log in todayLogs) {
      byRecord.putIfAbsent(log.medicalRecordId, () => []).add(log);
    }

    return meds.map((r) {
      final entries = byRecord[r.id] ?? const <MedicationLog>[];
      DateTime? last;
      for (final e in entries) {
        if (last == null || e.givenAt.isAfter(last)) last = e.givenAt;
      }
      return MedicationAdherence(
        record: r,
        dosesToday: entries.length,
        lastGivenAt: last,
      );
    }).toList();
  }

  Future<void> logDose(String medicalRecordId) async {
    await ref
        .read(medicationLogRepositoryProvider)
        .logDose(medicalRecordId: medicalRecordId, petId: arg);
    state = AsyncData(await _load());
  }
}
