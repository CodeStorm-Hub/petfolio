// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CareTaskImpl _$$CareTaskImplFromJson(Map<String, dynamic> json) =>
    _$CareTaskImpl(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      taskType: $enumDecode(_$CareTaskTypeEnumMap, json['task_type']),
      title: json['title'] as String,
      frequency: $enumDecode(_$CareFrequencyEnumMap, json['frequency']),
      scheduledTime: json['scheduled_time'] as String?,
      isCompleted: json['is_completed'] as bool,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      gamificationPoints: (json['gamification_points'] as num).toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CareTaskImplToJson(_$CareTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet_id': instance.petId,
      'task_type': _$CareTaskTypeEnumMap[instance.taskType]!,
      'title': instance.title,
      'frequency': _$CareFrequencyEnumMap[instance.frequency]!,
      'scheduled_time': instance.scheduledTime,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt?.toIso8601String(),
      'gamification_points': instance.gamificationPoints,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$CareTaskTypeEnumMap = {
  CareTaskType.feeding: 'feeding',
  CareTaskType.walk: 'walk',
  CareTaskType.grooming: 'grooming',
  CareTaskType.medication: 'medication',
  CareTaskType.vetVisit: 'vet_visit',
  CareTaskType.training: 'training',
  CareTaskType.playtime: 'playtime',
  CareTaskType.dental: 'dental',
  CareTaskType.nailTrim: 'nail_trim',
  CareTaskType.bath: 'bath',
  CareTaskType.other: 'other',
};

const _$CareFrequencyEnumMap = {
  CareFrequency.once: 'once',
  CareFrequency.daily: 'daily',
  CareFrequency.twiceDaily: 'twice_daily',
  CareFrequency.weekly: 'weekly',
  CareFrequency.biweekly: 'biweekly',
  CareFrequency.monthly: 'monthly',
  CareFrequency.asNeeded: 'as_needed',
};
