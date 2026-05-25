/// Immutable data model for a single post comment.
///
/// Constructed from a Supabase row via [fromJson].
/// No business logic lives here — only data shape and serialisation.
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.petId,
    required this.handle,
    required this.petName,
    required this.content,
    required this.createdAt,
    required this.isOwnComment,
    this.avatarUrl,
    this.parentId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String postId;
  final String petId;

  /// The @handle of the pet that wrote this comment (e.g. "@biscuit").
  final String handle;

  /// Display name of the pet (e.g. "Biscuit").
  final String petName;

  final String content;
  final DateTime createdAt;
  final String? avatarUrl;

  /// True when this comment belongs to the currently active pet.
  /// Used by the UI to show a delete affordance.
  final bool isOwnComment;

  final String? parentId;
  final int likeCount;
  final bool isLiked;

  /// Human-readable relative time string (e.g. "2h ago").
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Comment copyWithLike({required bool liked}) => Comment(
        id: id,
        postId: postId,
        petId: petId,
        handle: handle,
        petName: petName,
        content: content,
        createdAt: createdAt,
        isOwnComment: isOwnComment,
        avatarUrl: avatarUrl,
        parentId: parentId,
        likeCount: liked ? likeCount + 1 : (likeCount > 0 ? likeCount - 1 : 0),
        isLiked: liked,
      );

  /// Returns a copy of this comment with [newContent] replacing [content].
  ///
  /// Used by [CommentNotifier.edit] for optimistic UI updates.
  Comment copyWithContent(String newContent) => Comment(
        id: id,
        postId: postId,
        petId: petId,
        handle: handle,
        petName: petName,
        content: newContent,
        createdAt: createdAt,
        isOwnComment: isOwnComment,
        avatarUrl: avatarUrl,
        parentId: parentId,
        likeCount: likeCount,
        isLiked: isLiked,
      );

  factory Comment.fromJson(Map<String, dynamic> json, {
    required String activePetId,
    bool isLiked = false,
  }) {
    final pet = json['pet'] as Map<String, dynamic>? ?? {};
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      petId: json['pet_id'] as String,
      handle: '@${pet['handle'] ?? 'unknown'}',
      petName: pet['name'] as String? ?? 'Unknown',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isOwnComment: json['pet_id'] as String == activePetId,
      avatarUrl: pet['avatar_url'] as String?,
      parentId: json['parent_id'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      isLiked: isLiked,
    );
  }
}
