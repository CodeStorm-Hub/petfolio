import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

part 'notification_controller.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers & Notifiers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class Notifications extends _$Notifications {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<AppNotification>> build() async {
    final activePet = ref.watch(activePetControllerProvider);
    if (activePet == null) return const [];

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    final repo = ref.read(notificationRepositoryProvider);

    // Initial load utilizing join query
    final notifications = await repo.fetchNotifications(activePet.id);

    // Setup Postgres Changes subscription to update state on modification
    if (ref.mounted) {
      _channel = Supabase.instance.client
          .channel('notifications_${activePet.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'recipient_pet_id',
              value: activePet.id,
            ),
            callback: (payload) async {
              try {
                // Re-fetch the full list with joins to avoid missing actor details
                final updated = await ref
                    .read(notificationRepositoryProvider)
                    .fetchNotifications(activePet.id);
                state = AsyncData(updated);
              } catch (_) {
                // Ignore transient failures in realtime syncing
              }
            },
          )
          .subscribe();
    }

    return notifications;
  }

  /// Marks all unread notifications as read and updates the local state.
  Future<void> markAllRead() async {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return;

    final current = state.value;
    if (current == null) return;

    // Optimistic update: mark all as read locally.
    state = AsyncData(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      await ref.read(notificationRepositoryProvider).markAllRead(activePet.id);
    } catch (_) {
      // Reconciles on next event or manual refresh
    }
  }
}

/// Derived provider: counts unread notifications for the badge.
@riverpod
int unreadCount(Ref ref) {
  return ref
          .watch(notificationsProvider)
          .value
          ?.where((n) => !n.isRead)
          .length ??
      0;
}


