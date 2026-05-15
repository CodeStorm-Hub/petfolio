import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the real-time notification list for the active pet.
///
/// Backed by a Supabase Realtime stream, so the list auto-updates
/// whenever a new notification row is inserted.
final notificationsProvider =
    StreamNotifierProvider.autoDispose<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

/// Derived provider: counts unread notifications for the badge.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Streams in-app notifications for the currently active pet.
///
/// Uses [StreamNotifier] so Flutter rebuilds automatically whenever
/// the Supabase Realtime channel receives a new notification row.
class NotificationNotifier
    extends AutoDisposeStreamNotifier<List<AppNotification>> {
  @override
  Stream<List<AppNotification>> build() {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return const Stream.empty();

    return _repo.watchNotifications(activePet.id);
  }

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  // ── Public actions ────────────────────────────────────────────────────────

  /// Marks all unread notifications as read and updates the local state.
  Future<void> markAllRead() async {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return;

    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic update: mark all as read locally.
    state = AsyncData(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      await _repo.markAllRead(activePet.id);
    } catch (_) {
      // On failure, the stream will eventually reconcile the state.
    }
  }
}
