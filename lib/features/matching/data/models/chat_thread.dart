/// A chat thread created when two pets mutually match.
///
/// Maps to the `chat_threads` table. The Supabase table stores
/// `pet_id_1` / `pet_id_2`; this model resolves which one is "mine"
/// and which is the "other" pet at construction time.
class ChatThread {
  const ChatThread({
    required this.id,
    required this.myPetId,
    required this.otherPetId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  final String id;
  final String myPetId;
  final String otherPetId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  factory ChatThread.fromJson(
    Map<String, dynamic> json, {
    required String myPetId,
  }) {
    final isPet1 = json['pet_id_1'] == myPetId;
    return ChatThread(
      id: json['id'] as String,
      myPetId: myPetId,
      otherPetId: isPet1
          ? json['pet_id_2'] as String
          : json['pet_id_1'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['matched_at'] ?? '') as String) ??
          DateTime.now(),
    );
  }
}
