class ProductReview {
  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    required this.createdAt,
    this.body,
    this.isOwn = false,
  });

  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? body;
  final DateTime createdAt;
  final bool isOwn;

  factory ProductReview.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) =>
      ProductReview(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        userId: json['user_id'] as String,
        rating: (json['rating'] as num).toInt(),
        body: json['body'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isOwn: currentUserId != null && json['user_id'] == currentUserId,
      );
}
