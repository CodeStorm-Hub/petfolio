class MatchInboxItem {
  const MatchInboxItem({
    this.matchId,
    required this.otherPetId,
    required this.otherPetName,
    this.otherPetAvatarUrl,
    this.otherPetBreed,
    required this.matchedAt,
    this.threadId,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.threadType = 'match',
  });

  final String? matchId;
  final String otherPetId;
  final String otherPetName;
  final String? otherPetAvatarUrl;
  final String? otherPetBreed;
  final DateTime matchedAt;
  final String? threadId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String threadType;

  bool get isDm => threadType == 'dm';

  // DM threads are never in the "new match" bubble row.
  bool get isNewMatch => !isDm && lastMessageAt == null;
}
