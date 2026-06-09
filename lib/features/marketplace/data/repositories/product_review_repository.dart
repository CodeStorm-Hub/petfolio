import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_review.dart';

final productReviewRepositoryProvider = Provider<ProductReviewRepository>(
  (_) => ProductReviewRepository(Supabase.instance.client),
);

class ProductReviewRepository {
  ProductReviewRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<ProductReview>> fetchReviews(String productId) async {
    final uid = _userId;
    final rows = await _client
        .from('product_reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(50);

    return [
      for (final r in rows)
        ProductReview.fromJson(
          Map<String, dynamic>.from(r as Map),
          currentUserId: uid,
        ),
    ];
  }

  Future<ProductReview?> fetchOwnReview(String productId) async {
    final uid = _userId;
    if (uid == null) return null;

    final row = await _client
        .from('product_reviews')
        .select()
        .eq('product_id', productId)
        .eq('user_id', uid)
        .maybeSingle();

    if (row == null) return null;
    return ProductReview.fromJson(
      Map<String, dynamic>.from(row),
      currentUserId: uid,
    );
  }

  Future<ProductReview> upsertReview({
    required String productId,
    required int rating,
    String? body,
  }) async {
    final uid = _userId;
    if (uid == null) {
      throw StateError('Sign in to leave a review');
    }

    final row = await _client
        .from('product_reviews')
        .upsert({
          'product_id': productId,
          'user_id': uid,
          'rating': rating,
          if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'product_id,user_id')
        .select()
        .single();

    return ProductReview.fromJson(
      Map<String, dynamic>.from(row),
      currentUserId: uid,
    );
  }
}
