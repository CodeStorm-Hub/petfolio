class ChatThread {
  const ChatThread({
    required this.id,
    this.matchRequestId,
    this.mutualMatchId,
    required this.myUserId,
    required this.otherUserId,
    required this.activePetId,
    this.lastMessageAt,
    required this.createdAt,
  });

  final String id;
  final String? matchRequestId;
  final String? mutualMatchId;
  final String myUserId;
  final String otherUserId;
  final String activePetId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  factory ChatThread.fromJson(
    Map<String, dynamic> json, {
    required String myUserId,
    required String activePetId,
  }) {
    final p1 = json['participant_1_id'] as String;
    final p2 = json['participant_2_id'] as String;
    final other = p1 == myUserId ? p2 : p1;
    return ChatThread(
      id: json['id'] as String,
      matchRequestId: json['match_request_id'] as String?,
      mutualMatchId: json['mutual_match_id'] as String?,
      myUserId: myUserId,
      otherUserId: other,
      activePetId: activePetId,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
