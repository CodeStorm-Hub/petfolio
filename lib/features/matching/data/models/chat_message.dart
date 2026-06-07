class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['thread_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );

  ChatMessage copyWith({bool? isRead}) => ChatMessage(
        id: id,
        threadId: threadId,
        senderId: senderId,
        content: content,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}
