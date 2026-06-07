import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/marketplace/data/repositories/product_review_repository.dart';
import '../../helpers/fake_supabase_client.dart';

void main() {
  group('ProductReviewRepository', () {
    test('upsertReview throws when user is not signed in', () async {
      final repo = ProductReviewRepository(FakeSupabaseClient());

      expect(
        () => repo.upsertReview(
          productId: 'prod-1',
          rating: 5,
          body: 'Great',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fetchOwnReview returns null when user is not signed in', () async {
      final repo = ProductReviewRepository(FakeSupabaseClient());
      expect(await repo.fetchOwnReview('prod-1'), isNull);
    });
  });
}
