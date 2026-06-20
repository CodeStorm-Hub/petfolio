import 'package:freezed_annotation/freezed_annotation.dart';

part 'promo.freezed.dart';
part 'promo.g.dart';

@JsonEnum()
enum PromoDiscountType { percent, flat }

@freezed
abstract class Promo with _$Promo {
  const Promo._();

  const factory Promo({
    required String id,
    required String code,
    required String description,
    @JsonKey(name: 'discount_type') required PromoDiscountType discountType,
    @JsonKey(name: 'discount_value') required int discountValue,
    @JsonKey(name: 'min_order_cents') required int minOrderCents,
    @JsonKey(name: 'max_discount_cents') int? maxDiscountCents,
    required String category,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'valid_until') DateTime? validUntil,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'shop_id') String? shopId,
  }) = _Promo;

  factory Promo.fromJson(Map<String, dynamic> json) => _$PromoFromJson(json);

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  String get validUntilFormatted {
    if (validUntil == null) return 'No expiry';
    final d = validUntil!;
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return 'Valid till ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String get discountLabel => discountType == PromoDiscountType.percent
      ? '$discountValue% OFF'
      : '\$${(discountValue / 100).toStringAsFixed(0)} OFF';
}
