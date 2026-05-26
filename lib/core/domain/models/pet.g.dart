// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pet _$PetFromJson(Map<String, dynamic> json) => _Pet(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  name: json['name'] as String,
  species: json['species'] as String,
  breed: json['breed'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  dateOfBirth: json['date_of_birth'] == null
      ? null
      : DateTime.parse(json['date_of_birth'] as String),
  gender: json['gender'] == null
      ? PetGender.unknown
      : const _PetGenderConverter().fromJson(json['gender'] as String?),
  weightKg: (json['weight_kg'] as num?)?.toDouble(),
  activityLevel: json['activity_level'] as String?,
  isPublic: json['is_public'] as bool? ?? true,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  archivedAt: json['archived_at'] == null
      ? null
      : DateTime.parse(json['archived_at'] as String),
  isDiscoverable: json['is_discoverable'] as bool? ?? false,
  handle: json['handle'] as String?,
  accentColor: json['accent_color'] as String?,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PetToJson(_Pet instance) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'species': instance.species,
  'breed': instance.breed,
  'avatar_url': instance.avatarUrl,
  'bio': instance.bio,
  'created_at': instance.createdAt.toIso8601String(),
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'gender': const _PetGenderConverter().toJson(instance.gender),
  'weight_kg': instance.weightKg,
  'activity_level': instance.activityLevel,
  'is_public': instance.isPublic,
  'display_order': instance.displayOrder,
  'archived_at': instance.archivedAt?.toIso8601String(),
  'is_discoverable': instance.isDiscoverable,
  'handle': instance.handle,
  'accent_color': instance.accentColor,
  'updated_at': instance.updatedAt?.toIso8601String(),
};
