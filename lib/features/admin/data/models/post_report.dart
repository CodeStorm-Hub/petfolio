class PostReport {
  const PostReport({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.createdAt,
    this.postContent,
  });

  final String id;
  final String postId;
  final String reporterId;
  final String reason;
  final DateTime createdAt;
  final String? postContent;

  factory PostReport.fromJson(Map<String, dynamic> json) {
    final post = json['post'] as Map<String, dynamic>?;
    return PostReport(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      reporterId: json['reporter_id'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      postContent: post?['content'] as String?,
    );
  }
}
