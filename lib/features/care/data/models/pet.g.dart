// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PetImpl _$$PetImplFromJson(Map<String, dynamic> json) => _$PetImpl(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  name: json['name'] as String,
  species: json['species'] as String,
  breed: json['breed'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  activityLevel: $enumDecodeNullable(
    _$ActivityLevelEnumMap,
    json['activity_level'],
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$PetImplToJson(_$PetImpl instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'species': instance.species,
  'breed': instance.breed,
  'avatar_url': instance.avatarUrl,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'activity_level': _$ActivityLevelEnumMap[instance.activityLevel],
  'created_at': instance.createdAt.toIso8601String(),
};

const _$ActivityLevelEnumMap = {
  ActivityLevel.sedentary: 'sedentary',
  ActivityLevel.low: 'low',
  ActivityLevel.moderate: 'moderate',
  ActivityLevel.high: 'high',
  ActivityLevel.veryHigh: 'very_high',
};
