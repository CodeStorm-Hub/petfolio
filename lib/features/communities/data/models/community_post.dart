class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorPetId,
    required this.content,
    this.imageUrl,
    required this.likeCount,
    required this.createdAt,
    this.authorPetName,
    this.authorAvatarUrl,
    this.isLiked = false,
  });

  final String id;
  final String communityId;
  final String authorPetId;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final DateTime createdAt;
  final String? authorPetName;
  final String? authorAvatarUrl;
  final bool isLiked;

  factory CommunityPost.fromJson(Map<String, dynamic> j,
      {bool isLiked = false}) {
    final pet = j['pets'] as Map<String, dynamic>?;
    return CommunityPost(
      id: j['id'] as String,
      communityId: j['community_id'] as String,
      authorPetId: j['author_pet_id'] as String,
      content: j['content'] as String,
      imageUrl: j['image_url'] as String?,
      likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
      authorPetName: pet?['name'] as String?,
      authorAvatarUrl: pet?['avatar_url'] as String?,
      isLiked: isLiked,
    );
  }

  CommunityPost copyWith({int? likeCount, bool? isLiked}) => CommunityPost(
        id: id,
        communityId: communityId,
        authorPetId: authorPetId,
        content: content,
        imageUrl: imageUrl,
        likeCount: likeCount ?? this.likeCount,
        createdAt: createdAt,
        authorPetName: authorPetName,
        authorAvatarUrl: authorAvatarUrl,
        isLiked: isLiked ?? this.isLiked,
      );
}
