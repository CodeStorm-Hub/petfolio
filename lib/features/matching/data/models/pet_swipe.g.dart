// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_swipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PetSwipe _$PetSwipeFromJson(Map<String, dynamic> json) => _PetSwipe(
  id: json['id'] as String,
  actorId: json['actor_id'] as String,
  targetId: json['target_id'] as String,
  action: $enumDecode(_$SwipeTableActionEnumMap, json['action']),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PetSwipeToJson(_PetSwipe instance) => <String, dynamic>{
  'id': instance.id,
  'actor_id': instance.actorId,
  'target_id': instance.targetId,
  'action': _$SwipeTableActionEnumMap[instance.action]!,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$SwipeTableActionEnumMap = {
  SwipeTableAction.like: 'LIKE',
  SwipeTableAction.pass: 'PASS',
};
