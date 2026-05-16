// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_discovery_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchingDiscoveryOwner _$MatchingDiscoveryOwnerFromJson(
  Map<String, dynamic> json,
) => _MatchingDiscoveryOwner(
  id: json['id'] as String,
  username: json['username'] as String?,
  displayName: json['display_name'] as String?,
);

Map<String, dynamic> _$MatchingDiscoveryOwnerToJson(
  _MatchingDiscoveryOwner instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'display_name': instance.displayName,
};

_MatchingDiscoveryRow _$MatchingDiscoveryRowFromJson(
  Map<String, dynamic> json,
) => _MatchingDiscoveryRow(
  id: json['id'] as String,
  ownerId: json['owner_id'] as String,
  name: json['name'] as String,
  species: json['species'] as String,
  breed: json['breed'] as String?,
  dateOfBirth: _dateTimeFromJson(json['date_of_birth']),
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  distanceMeters: _numToDouble(json['distance_meters']),
  owner: json['owner'] == null
      ? null
      : MatchingDiscoveryOwner.fromJson(json['owner'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MatchingDiscoveryRowToJson(
  _MatchingDiscoveryRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'owner_id': instance.ownerId,
  'name': instance.name,
  'species': instance.species,
  'breed': instance.breed,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'avatar_url': instance.avatarUrl,
  'bio': instance.bio,
  'distance_meters': instance.distanceMeters,
  'owner': instance.owner,
};
