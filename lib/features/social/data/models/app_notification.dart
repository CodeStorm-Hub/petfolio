import '../../../../core/utils/time_ago.dart';

/// Immutable data model for an in-app notification event.
///
/// Represents one row from the `notifications` Supabase table.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorHandle,
    required this.actorPetName,
    required this.isRead,
    required this.createdAt,
    this.postId,
  });

  final String id;

  /// One of: 'like' | 'comment' | 'follow'
  final String type;

  /// The @handle of the pet that triggered this notification.
  final String actorHandle;

  /// The display name of the pet that triggered this notification.
  final String actorPetName;

  final bool isRead;
  final DateTime createdAt;

  /// Present for 'like' and 'comment' notifications; null for 'follow'.
  final String? postId;

  /// Human-readable summary string shown in the notification list.
  String get summary {
    switch (type) {
      case 'like':
        return '$actorHandle liked your post.';
      case 'comment':
        return '$actorHandle commented on your post.';
      case 'follow':
        return '$actorHandle started following you.';
      default:
        return '$actorHandle interacted with you.';
    }
  }

  String get timeAgo => formatTimeAgo(createdAt);

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actor = json['actor_pet'] as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      actorHandle: '@${actor['handle'] ?? 'unknown'}',
      actorPetName: actor['name'] as String? ?? 'Unknown',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      postId: json['post_id'] as String?,
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    actorHandle: actorHandle,
    actorPetName: actorPetName,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    postId: postId,
  );
}
