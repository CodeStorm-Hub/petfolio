import 'package:flutter/material.dart';

/// Immutable model for a social feed post.
///
/// The like state is kept local in Riverpod; Supabase is the
/// eventual-consistency remote via optimistic writes in [SocialNotifier].
class FeedPost {
  const FeedPost({
    required this.id,
    required this.petId,
    required this.handle,
    required this.petName,
    required this.petSpecies,
    required this.accentColor,
    required this.fuzzyLocation,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.isLiked,
    required this.gradientColors,
    required this.subjectColor,
    this.tag,
    this.isCarousel = false,
    this.isMemorial = false,
    this.tributes = 0,
    this.breed,
    this.imageUrls = const [],
    this.petAvatarUrl,
    this.videoUrl,
  });

  final String id;

  /// The ID of the pet that authored this post.
  /// Used to determine ownership so the UI can show edit/delete options.
  final String petId;

  final String handle;
  final String petName;
  final String petSpecies;
  final Color accentColor;
  final String fuzzyLocation;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;

  /// Whether the active pet has liked this post.
  final bool isLiked;

  /// Three colours [start, mid, end] for the photo gradient.
  final List<Color> gradientColors;

  /// Base colour for the pet illustration blob.
  final Color subjectColor;

  final String? tag;
  final bool isCarousel;
  final bool isMemorial;
  final int tributes;
  final String? breed;

  final List<String> imageUrls;
  final String? petAvatarUrl;

  /// Remote URL of a video attachment. Null for image-only or text posts.
  final String? videoUrl;

  // ── Optimistic copy helpers ───────────────────────────────────────────────

  FeedPost copyWithLike({required bool liked}) => _copy(
    isLiked: liked,
    likes: liked ? likes + 1 : (likes > 0 ? likes - 1 : 0),
  );

  /// Returns a copy with an updated caption (used for optimistic edit UI).
  FeedPost copyWithCaption(String newCaption) => _copy(caption: newCaption);

  /// Returns a copy with updated counts from a realtime subscription.
  FeedPost copyWithCounts({int? likes, int? comments}) => _copy(
    likes: likes,
    comments: comments,
  );

  /// Returns a copy with incremented comment count (used for optimistic UI).
  FeedPost copyWithIncrementedComment() => _copy(comments: comments + 1);

  /// Returns a copy with decremented comment count (used for optimistic UI).
  FeedPost copyWithDecrementedComment() =>
      _copy(comments: comments > 0 ? comments - 1 : 0);

  FeedPost _copy({
    bool? isLiked,
    int? likes,
    String? caption,
    int? comments,
  }) => FeedPost(
    id: id,
    petId: petId,
    handle: handle,
    petName: petName,
    petSpecies: petSpecies,
    accentColor: accentColor,
    fuzzyLocation: fuzzyLocation,
    caption: caption ?? this.caption,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    timeAgo: timeAgo,
    isLiked: isLiked ?? this.isLiked,
    gradientColors: gradientColors,
    subjectColor: subjectColor,
    tag: tag,
    isCarousel: isCarousel,
    isMemorial: isMemorial,
    tributes: tributes,
    breed: breed,
    imageUrls: imageUrls,
    petAvatarUrl: petAvatarUrl,
    videoUrl: videoUrl,
  );
}
