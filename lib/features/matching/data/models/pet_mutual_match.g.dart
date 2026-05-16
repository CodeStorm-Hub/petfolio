// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_mutual_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PetMutualMatch _$PetMutualMatchFromJson(Map<String, dynamic> json) =>
    _PetMutualMatch(
      id: json['id'] as String,
      petAId: json['pet_a_id'] as String,
      petBId: json['pet_b_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PetMutualMatchToJson(_PetMutualMatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pet_a_id': instance.petAId,
      'pet_b_id': instance.petBId,
      'created_at': instance.createdAt.toIso8601String(),
    };
