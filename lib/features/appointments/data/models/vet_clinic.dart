import 'package:freezed_annotation/freezed_annotation.dart';

part 'vet_clinic.freezed.dart';
part 'vet_clinic.g.dart';

@freezed
abstract class VetClinic with _$VetClinic {
  const factory VetClinic({
    required String id,
    required String name,
    String? tagline,
    required String address,
    required String city,
    String? phone,
    String? email,
    String? website,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(fromJson: _ratingFromJson) required double rating,
    @JsonKey(name: 'review_count') required int reviewCount,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _VetClinic;

  factory VetClinic.fromJson(Map<String, dynamic> json) =>
      _$VetClinicFromJson(json);
}

double _ratingFromJson(dynamic v) =>
    v is num ? v.toDouble() : double.parse(v.toString());
