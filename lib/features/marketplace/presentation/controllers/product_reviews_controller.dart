import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_review.dart';
import '../../data/repositories/product_review_repository.dart';
import 'product_list_controller.dart';

final productReviewsProvider = AsyncNotifierProvider.family<
    ProductReviewsNotifier, List<ProductReview>, String>(
  ProductReviewsNotifier.new,
);

final ownProductReviewProvider = FutureProvider.family<ProductReview?, String>(
  (ref, productId) =>
      ref.read(productReviewRepositoryProvider).fetchOwnReview(productId),
);

class ProductReviewsNotifier extends AsyncNotifier<List<ProductReview>> {
  ProductReviewsNotifier(this.productId);

  final String productId;

  @override
  Future<List<ProductReview>> build() =>
      ref.read(productReviewRepositoryProvider).fetchReviews(productId);

  Future<void> submitReview({required int rating, String? body}) async {
    final review = await ref.read(productReviewRepositoryProvider).upsertReview(
          productId: productId,
          rating: rating,
          body: body,
        );

    final current = state.value ?? [];
    final withoutOwn =
        current.where((r) => r.userId != review.userId).toList();
    state = AsyncData([review, ...withoutOwn]);

    ref.invalidate(productListProvider);
    ref.invalidate(ownProductReviewProvider(productId));
  }
}
