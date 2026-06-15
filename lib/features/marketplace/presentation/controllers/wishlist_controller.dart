import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/wishlist_repository.dart';

part 'wishlist_controller.g.dart';

@riverpod
class WishlistItems extends _$WishlistItems {
  @override
  Future<List<WishlistProduct>> build() =>
      ref.read(wishlistRepositoryProvider).fetchWishlistProducts();

  Future<void> toggle(String productId, {String? variantId}) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final isIn = await repo.isInWishlist(productId, variantId: variantId);
    if (isIn) {
      await repo.removeFromWishlist(productId, variantId: variantId);
    } else {
      await repo.addToWishlist(productId, variantId: variantId);
    }
    ref.invalidate(isWishlistedProvider(productId));
    ref.invalidateSelf();
  }
}

@riverpod
Future<bool> isWishlisted(Ref ref, String productId) =>
    ref.read(wishlistRepositoryProvider).isInWishlist(productId);
