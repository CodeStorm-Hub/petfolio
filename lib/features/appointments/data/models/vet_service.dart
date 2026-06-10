import 'package:freezed_annotation/freezed_annotation.dart';

part 'vet_service.freezed.dart';
part 'vet_service.g.dart';

@freezed
abstract class VetService with _$VetService {
  const VetService._();

  const factory VetService({
    required String id,
    @JsonKey(name: 'clinic_id') required String clinicId,
    required String name,
    String? description,
    @JsonKey(name: 'duration_minutes') required int durationMinutes,
    @JsonKey(name: 'price_cents') required int priceCents,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _VetService;

  factory VetService.fromJson(Map<String, dynamic> json) =>
      _$VetServiceFromJson(json);

  String get formattedPrice {
    if (priceCents == 0) return 'Free';
    final taka = priceCents ~/ 100;
    return '৳$taka';
  }

  String get formattedDuration {
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
