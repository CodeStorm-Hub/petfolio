import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_swipe.freezed.dart';
part 'pet_swipe.g.dart';

@JsonEnum(alwaysCreate: true)
enum SwipeTableAction {
  @JsonValue('LIKE')
  like,
  @JsonValue('PASS')
  pass,
}

@freezed
abstract class PetSwipe with _$PetSwipe {
  const factory PetSwipe({
    required String id,
    required String actorId,
    required String targetId,
    required SwipeTableAction action,
    required DateTime createdAt,
  }) = _PetSwipe;

  factory PetSwipe.fromJson(Map<String, dynamic> json) =>
      _$PetSwipeFromJson(json);
}
