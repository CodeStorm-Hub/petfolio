import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/features/marketplace/data/models/product_review.dart';

void main() {
  test('ProductReview.fromJson maps fields and isOwn', () {
    final json = {
      'id': 'rev-1',
      'product_id': 'prod-1',
      'user_id': 'user-1',
      'rating': 4,
      'body': 'Great treats',
      'created_at': '2026-06-08T12:00:00.000Z',
    };

    final review = ProductReview.fromJson(json, currentUserId: 'user-1');
    expect(review.id, 'rev-1');
    expect(review.rating, 4);
    expect(review.body, 'Great treats');
    expect(review.isOwn, isTrue);
  });
}
