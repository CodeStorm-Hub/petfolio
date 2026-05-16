class MatchInboxItem {
  const MatchInboxItem({
    required this.matchId,
    required this.otherPetId,
    required this.otherPetName,
    this.otherPetAvatarUrl,
    this.otherPetBreed,
    required this.matchedAt,
    this.threadId,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  final String matchId;
  final String otherPetId;
  final String otherPetName;
  final String? otherPetAvatarUrl;
  final String? otherPetBreed;
  final DateTime matchedAt;
  final String? threadId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  bool get isNewMatch => lastMessageAt == null;
}
