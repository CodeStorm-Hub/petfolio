import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_log.freezed.dart';
part 'health_log.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum HealthLogType {
  symptom,
  weight,
  vetVisit,
  medication,
  allergy,
  injury,
  general,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum HealthSeverity { mild, moderate, severe, critical }

@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class HealthLog with _$HealthLog {
  const HealthLog._();

  const factory HealthLog({
    required String id,
    required String petId,
    required String recordedBy,
    required HealthLogType logType,
    required String title,
    String? description,
    double? weightKg,
    HealthSeverity? severity,
    String? vetName,
    String? vetClinic,
    String? diagnosis,
    String? treatment,
    DateTime? followUpDate,
    required DateTime occurredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _HealthLog;

  factory HealthLog.fromJson(Map<String, dynamic> json) =>
      _$HealthLogFromJson(json);

  bool get isWeightEntry => logType == HealthLogType.weight;

  bool get isVetVisit => logType == HealthLogType.vetVisit;

  bool get hasSeverity => severity != null;

  bool get requiresFollowUp => followUpDate != null;

  bool get followUpOverdue {
    if (followUpDate == null) return false;
    return followUpDate!.isBefore(DateTime.now());
  }

  int get daysUntilFollowUp {
    if (followUpDate == null) return 0;
    return followUpDate!.difference(DateTime.now()).inDays;
  }
}
