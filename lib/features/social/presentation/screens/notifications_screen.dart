import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:petfolio/core/domain/models/app_notification.dart';
import '../controllers/notification_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen notification activity feed.
///
/// Receives a real-time list from [notificationsProvider] and marks
/// all items as read when the screen is opened.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when the user opens this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Activity',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: notificationsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Failed to load activity',
              style: TextStyle(color: const Color(0xFF64748B)),
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _EmptyState(pt: pt);
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: const Color(0xFFE2E8F0), indent: 72),
            itemBuilder: (ctx, i) =>
                _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔔', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When someone likes your post,\nfollows you, or leaves a comment,\nyou'll see it here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: notification.isRead
          ? Colors.transparent
          : pt.pillarSocial.withAlpha(15),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _iconColor(notification.type).withAlpha(30),
          child: Text(
            _emoji(notification.type),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          notification.summary,
          style: tt.bodyMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notification.timeAgo,
          style: tt.labelSmall?.copyWith(color: const Color(0xFF64748B)),
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.coral500,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'like':
        return AppColors.coral500;
      case 'follow':
        return AppColors.meadow500;
      case 'comment':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _emoji(String type) {
    switch (type) {
      case 'like':
        return '🐾';
      case 'follow':
        return '➕';
      case 'comment':
        return '💬';
      default:
        return '🔔';
    }
  }
}
