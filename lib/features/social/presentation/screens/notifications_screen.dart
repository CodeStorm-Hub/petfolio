import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/app_notification.dart';
import '../controllers/notification_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsScreen — Phase 5: Pathao-style segmented Updates / Promotions
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);

    final allNotifs = notificationsAsync.value ?? [];

    // Updates = social activity; Promotions = deals/offers (future type)
    final updates = allNotifs
        .where((n) => const {'like', 'comment', 'follow'}.contains(n.type))
        .toList();
    final promotions = allNotifs
        .where((n) => !const {'like', 'comment', 'follow'}.contains(n.type))
        .toList();
    final unreadCount = updates.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.ink950,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Notifications',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.ink950,
                    ),
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () =>
                          ref.read(notificationsProvider.notifier).markAllRead(),
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.poppy,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Pathao-style flat tab bar ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(16)
                        : AppColors.line,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.poppy, width: 3),
                  insets: EdgeInsets.zero,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.poppy,
                unselectedLabelColor: AppColors.ink500,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Updates'),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.poppy,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Promotions'),
                ],
              ),
            ),

            // ── Tab views ─────────────────────────────────────────────────
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: TailWagLoader()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load notifications',
                    style: TextStyle(color: pt.ink500),
                  ),
                ),
                data: (_) => TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _UpdatesTab(notifications: updates, pt: pt),
                    _PromotionsTab(notifications: promotions, pt: pt),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Updates tab — social activity (likes, comments, follows)
// ─────────────────────────────────────────────────────────────────────────────

class _UpdatesTab extends StatelessWidget {
  const _UpdatesTab({
    required this.notifications,
    required this.pt,
  });

  final List<AppNotification> notifications;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const PetfolioEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'No activity yet',
        subtitle:
            "When someone likes your post,\nfollows you, or leaves a comment,\nyou'll see it here.",
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: pt.line, indent: 72),
      itemBuilder: (_, i) =>
          _NotificationTile(notification: notifications[i], pt: pt),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promotions tab — marketplace deals and offers
// ─────────────────────────────────────────────────────────────────────────────

class _PromotionsTab extends StatelessWidget {
  const _PromotionsTab({
    required this.notifications,
    required this.pt,
  });

  final List<AppNotification> notifications;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const PetfolioEmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No promotions yet',
        subtitle:
            "Exclusive deals and offers from\nthe Petfolio marketplace will\nappear here.",
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      itemCount: notifications.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: pt.line, indent: 72),
      itemBuilder: (_, i) =>
          _NotificationTile(notification: notifications[i], pt: pt),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.pt,
  });

  final AppNotification notification;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      color: notification.isRead
          ? Colors.transparent
          : AppColors.poppy.withAlpha(12),
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
            fontWeight:
                notification.isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          notification.timeAgo,
          style: tt.labelSmall?.copyWith(color: pt.ink500),
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.poppy,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Color _iconColor(String type) => switch (type) {
        'like' => AppColors.poppy,
        'follow' => AppColors.mint,
        'comment' => AppColors.sky,
        'deal' || 'promo' => AppColors.tangerine,
        _ => AppColors.ink500,
      };

  String _emoji(String type) => switch (type) {
        'like' => '🐾',
        'follow' => '➕',
        'comment' => '💬',
        'deal' || 'promo' => '🏷️',
        _ => '🔔',
      };
}
