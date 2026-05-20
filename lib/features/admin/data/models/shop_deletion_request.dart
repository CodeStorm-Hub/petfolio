class ShopDeletionRequest {
  const ShopDeletionRequest({
    required this.id,
    required this.shopId,
    required this.ownerId,
    required this.shopName,
    required this.status,
    required this.requestedAt,
    this.reason,
    this.rejectionNote,
    this.resolvedAt,
  });

  final String id;
  final String shopId;
  final String ownerId;
  final String shopName;
  final String status;
  final DateTime requestedAt;
  final String? reason;
  final String? rejectionNote;
  final DateTime? resolvedAt;

  bool get isPending  => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory ShopDeletionRequest.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    return ShopDeletionRequest(
      id:            json['id'] as String,
      shopId:        json['shop_id'] as String,
      ownerId:       json['owner_id'] as String,
      shopName:      (shop?['shop_name'] as String?) ?? '',
      status:        json['status'] as String,
      requestedAt:   DateTime.parse(json['requested_at'] as String),
      reason:        json['reason'] as String?,
      rejectionNote: json['rejection_note'] as String?,
      resolvedAt:    json['resolved_at'] != null
                         ? DateTime.parse(json['resolved_at'] as String)
                         : null,
    );
  }
}
