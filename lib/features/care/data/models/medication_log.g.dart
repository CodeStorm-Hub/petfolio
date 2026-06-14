// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MedicationLog _$MedicationLogFromJson(Map<String, dynamic> json) =>
    _MedicationLog(
      id: json['id'] as String,
      medicalRecordId: json['medical_record_id'] as String,
      petId: json['pet_id'] as String,
      givenAt: DateTime.parse(json['given_at'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$MedicationLogToJson(_MedicationLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'medical_record_id': instance.medicalRecordId,
      'pet_id': instance.petId,
      'given_at': instance.givenAt.toIso8601String(),
      'notes': instance.notes,
    };
