import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_post.freezed.dart';
part 'saved_post.g.dart';

@freezed
abstract class SavedPost with _$SavedPost {
  const factory SavedPost({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _SavedPost;

  factory SavedPost.fromJson(Map<String, dynamic> json) =>
      _$SavedPostFromJson(json);
}
