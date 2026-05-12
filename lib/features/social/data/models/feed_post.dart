import 'package:flutter/material.dart';

/// Immutable model for a social feed post — regular or memorial variant.
///
/// The like/candle states are kept local in Riverpod; Supabase is the
/// eventual-consistency remote via optimistic writes in [SocialNotifier].
class FeedPost {
  const FeedPost({
    required this.id,
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
    this.isMemorial = false,
    this.tag,
    this.isCarousel = false,
    this.memorialDates,
    this.candles = 0,
    this.tributes = 0,
    this.breed,
    this.isCandleLit = false,
  });

  final String id;
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

  final bool isMemorial;
  final String? tag;
  final bool isCarousel;
  final String? memorialDates;
  final int candles;
  final int tributes;
  final String? breed;

  /// Whether the active pet has lit a candle on this memorial.
  final bool isCandleLit;

  // ── Optimistic copy helpers ───────────────────────────────────────────────

  FeedPost copyWithLike({required bool liked}) => _copy(
        isLiked: liked,
        likes: liked ? likes + 1 : (likes > 0 ? likes - 1 : 0),
      );

  FeedPost copyWithCandle({required bool lit}) => _copy(
        isCandleLit: lit,
        candles: lit ? candles + 1 : (candles > 0 ? candles - 1 : 0),
      );

  FeedPost _copy({
    bool? isLiked,
    int? likes,
    bool? isCandleLit,
    int? candles,
  }) =>
      FeedPost(
        id: id,
        handle: handle,
        petName: petName,
        petSpecies: petSpecies,
        accentColor: accentColor,
        fuzzyLocation: fuzzyLocation,
        caption: caption,
        likes: likes ?? this.likes,
        comments: comments,
        timeAgo: timeAgo,
        isLiked: isLiked ?? this.isLiked,
        gradientColors: gradientColors,
        subjectColor: subjectColor,
        isMemorial: isMemorial,
        tag: tag,
        isCarousel: isCarousel,
        memorialDates: memorialDates,
        candles: candles ?? this.candles,
        tributes: tributes,
        breed: breed,
        isCandleLit: isCandleLit ?? this.isCandleLit,
      );
}
