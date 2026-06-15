// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WishlistItem _$WishlistItemFromJson(Map<String, dynamic> json) =>
    _WishlistItem(
      id: json['id'] as String,
      wishlistId: json['wishlist_id'] as String,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );

Map<String, dynamic> _$WishlistItemToJson(_WishlistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wishlist_id': instance.wishlistId,
      'product_id': instance.productId,
      'variant_id': instance.variantId,
      'added_at': instance.addedAt.toIso8601String(),
    };
