// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MedicalRecord _$MedicalRecordFromJson(Map<String, dynamic> json) =>
    _MedicalRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      recordType: $enumDecode(_$MedicalRecordTypeEnumMap, json['record_type']),
      name: json['name'] as String,
      description: json['description'] as String?,
      administeredBy: json['administered_by'] as String?,
      administeredAt: json['administered_at'] == null
          ? null
          : DateTime.parse(json['administered_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      nextDueAt: json['next_due_at'] == null
          ? null
          : DateTime.parse(json['next_due_at'] as String),
      batchNumber: json['batch_number'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      isActive: json['is_active'] as bool,
      reminderEnabled: json['reminder_enabled'] as bool,
      documentUrl: json['document_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MedicalRecordToJson(_MedicalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet_id': instance.petId,
      'record_type': _$MedicalRecordTypeEnumMap[instance.recordType]!,
      'name': instance.name,
      'description': instance.description,
      'administered_by': instance.administeredBy,
      'administered_at': instance.administeredAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'next_due_at': instance.nextDueAt?.toIso8601String(),
      'batch_number': instance.batchNumber,
      'dosage': instance.dosage,
      'frequency': instance.frequency,
      'is_active': instance.isActive,
      'reminder_enabled': instance.reminderEnabled,
      'document_url': instance.documentUrl,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$MedicalRecordTypeEnumMap = {
  MedicalRecordType.vaccine: 'vaccine',
  MedicalRecordType.medication: 'medication',
  MedicalRecordType.allergy: 'allergy',
  MedicalRecordType.surgery: 'surgery',
  MedicalRecordType.parasitePrevention: 'parasite_prevention',
  MedicalRecordType.other: 'other',
};
