import 'package:freezed_annotation/freezed_annotation.dart';

part 'pet_mutual_match.freezed.dart';
part 'pet_mutual_match.g.dart';

@freezed
abstract class PetMutualMatch with _$PetMutualMatch {
  const factory PetMutualMatch({
    required String id,
    required String petAId,
    required String petBId,
    required DateTime createdAt,
  }) = _PetMutualMatch;

  factory PetMutualMatch.fromJson(Map<String, dynamic> json) =>
      _$PetMutualMatchFromJson(json);
}
