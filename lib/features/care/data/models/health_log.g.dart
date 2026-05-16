// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthLog _$HealthLogFromJson(Map<String, dynamic> json) => _HealthLog(
  id: json['id'] as String,
  petId: json['pet_id'] as String,
  recordedBy: json['recorded_by'] as String,
  logType: $enumDecode(_$HealthLogTypeEnumMap, json['log_type']),
  title: json['title'] as String,
  description: json['description'] as String?,
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  severity: $enumDecodeNullable(_$HealthSeverityEnumMap, json['severity']),
  vetName: json['vet_name'] as String?,
  vetClinic: json['vet_clinic'] as String?,
  diagnosis: json['diagnosis'] as String?,
  treatment: json['treatment'] as String?,
  followUpDate: json['follow_up_date'] == null
      ? null
      : DateTime.parse(json['follow_up_date'] as String),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$HealthLogToJson(_HealthLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet_id': instance.petId,
      'recorded_by': instance.recordedBy,
      'log_type': _$HealthLogTypeEnumMap[instance.logType]!,
      'title': instance.title,
      'description': instance.description,
      'weight_kg': instance.weightKg,
      'severity': _$HealthSeverityEnumMap[instance.severity],
      'vet_name': instance.vetName,
      'vet_clinic': instance.vetClinic,
      'diagnosis': instance.diagnosis,
      'treatment': instance.treatment,
      'follow_up_date': instance.followUpDate?.toIso8601String(),
      'occurred_at': instance.occurredAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$HealthLogTypeEnumMap = {
  HealthLogType.symptom: 'symptom',
  HealthLogType.weight: 'weight',
  HealthLogType.vetVisit: 'vet_visit',
  HealthLogType.medication: 'medication',
  HealthLogType.allergy: 'allergy',
  HealthLogType.injury: 'injury',
  HealthLogType.general: 'general',
};

const _$HealthSeverityEnumMap = {
  HealthSeverity.mild: 'mild',
  HealthSeverity.moderate: 'moderate',
  HealthSeverity.severe: 'severe',
  HealthSeverity.critical: 'critical',
};
