// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashtag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Hashtag _$HashtagFromJson(Map<String, dynamic> json) => _Hashtag(
  tag: json['tag'] as String,
  postCount: (json['post_count'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$HashtagToJson(_Hashtag instance) => <String, dynamic>{
  'tag': instance.tag,
  'post_count': instance.postCount,
  'created_at': instance.createdAt.toIso8601String(),
};
