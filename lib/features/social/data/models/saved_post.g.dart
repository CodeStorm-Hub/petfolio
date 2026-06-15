// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedPost _$SavedPostFromJson(Map<String, dynamic> json) => _SavedPost(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  postId: json['post_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SavedPostToJson(_SavedPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'post_id': instance.postId,
      'created_at': instance.createdAt.toIso8601String(),
    };
