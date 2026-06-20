import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_log.freezed.dart';
part 'medication_log.g.dart';

@freezed
abstract class MedicationLog with _$MedicationLog {
  const factory MedicationLog({
    required String id,
    required String medicalRecordId,
    required String petId,
    required DateTime givenAt,
    String? notes,
  }) = _MedicationLog;

  factory MedicationLog.fromJson(Map<String, dynamic> json) =>
      _$MedicationLogFromJson(json);
}
