import 'package:freezed_annotation/freezed_annotation.dart';

part 'hashtag.freezed.dart';
part 'hashtag.g.dart';

@freezed
abstract class Hashtag with _$Hashtag {
  const factory Hashtag({
    required String tag,
    @JsonKey(name: 'post_count') @Default(0) int postCount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Hashtag;

  factory Hashtag.fromJson(Map<String, dynamic> json) =>
      _$HashtagFromJson(json);
}
