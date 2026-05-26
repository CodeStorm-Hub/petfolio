import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/core/domain/models/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(Supabase.instance.client),
);

/// Repository for the in-app notifications feature.
///
/// [watchNotifications] exposes a real-time [Stream] powered by Supabase
/// Realtime. The [NotificationNotifier] subscribes to this stream so the
/// UI badge and list update automatically as new events arrive.
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Fetches the most recent 50 notifications for [recipientPetId].
  Future<List<AppNotification>> fetchNotifications(String recipientPetId) async {
    final rows = await _client
        .from('notifications')
        .select('''
          id, type, post_id, is_read, created_at,
          actor_pet:pets!notifications_actor_pet_id_fkey(handle, name)
        ''')
        .eq('recipient_pet_id', recipientPetId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) => AppNotification.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Provides a real-time [Stream] of notifications for [recipientPetId].
  ///
  /// Emits a fresh list every time a new notification row is inserted.
  Stream<List<AppNotification>> watchNotifications(String recipientPetId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_pet_id', recipientPetId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows
            .map((row) => AppNotification.fromJson(row))
            .toList());
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Marks all unread notifications for [recipientPetId] as read.
  Future<void> markAllRead(String recipientPetId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_pet_id', recipientPetId)
        .eq('is_read', false);
  }

  /// Inserts a single notification event into the database.
  ///
  /// Called from [SocialRepository] when a like, comment, or follow occurs.
  Future<void> insertNotification({
    required String recipientPetId,
    required String actorPetId,
    required String type, // 'like' | 'comment' | 'follow'
    String? postId,
  }) async {
    // Do not notify a pet about their own actions.
    if (recipientPetId == actorPetId) return;

    await _client.from('notifications').insert({
      'recipient_pet_id': recipientPetId,
      'actor_pet_id': actorPetId,
      'type': type,
      'post_id': postId,
    });
  }
}
