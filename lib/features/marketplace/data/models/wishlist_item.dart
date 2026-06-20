import 'package:freezed_annotation/freezed_annotation.dart';

part 'wishlist_item.freezed.dart';
part 'wishlist_item.g.dart';

@freezed
abstract class WishlistItem with _$WishlistItem {
  const factory WishlistItem({
    required String id,
    @JsonKey(name: 'wishlist_id') required String wishlistId,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'variant_id') String? variantId,
    @JsonKey(name: 'added_at') required DateTime addedAt,
  }) = _WishlistItem;

  factory WishlistItem.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemFromJson(json);
}
