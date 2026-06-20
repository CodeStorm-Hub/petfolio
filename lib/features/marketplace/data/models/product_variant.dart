import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/services/currency_formatter.dart';

part 'product_variant.freezed.dart';
part 'product_variant.g.dart';

@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    @JsonKey(name: 'product_id') required String productId,
    String? sku,
    @Default(<String, dynamic>{}) Map<String, dynamic> attributes,
    @JsonKey(name: 'price_cents') required int priceCents,
    @Default(0) int stock,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}

extension ProductVariantX on ProductVariant {
  String get priceFormatted => formatCents(priceCents);

  String get attributeLabel {
    if (attributes.isEmpty) return sku ?? 'Standard';
    return attributes.values.map((v) => v.toString()).join(' / ');
  }
}
