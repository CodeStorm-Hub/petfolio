import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../marketplace/data/models/promo.dart';
import '../../../marketplace/presentation/controllers/promo_controller.dart';
import '../../data/models/app_notification.dart';
import '../controllers/notification_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationsScreen — Phase 5: Pathao-style segmented Updates / Promotions
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key, this.showHeader = true});

  final bool showHeader;

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

    final updates = allNotifs
        .where((n) => const {'like', 'comment', 'follow'}.contains(n.type))
        .toList();
    final unreadCount = updates.where((n) => !n.isRead).length;

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        top: widget.showHeader,
        bottom: false,
        child: Column(
          children: [
            // ── Header (push-mode only) ────────────────────────────────────
            if (widget.showHeader)
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
              )
            else
              SizedBox(height: topPad + 76),

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
                    _PromotionsTab(pt: pt),
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
      itemBuilder: (_, i) => _NotificationTile(
        notification: notifications[i],
        pt: pt,
      )
          .animate(delay: Duration(milliseconds: 30 * i))
          .fadeIn(duration: 200.ms)
          .slideX(begin: -0.04, end: 0, duration: 240.ms, curve: Curves.easeOutCubic),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promotions tab — marketplace deals from promoListProvider
// ─────────────────────────────────────────────────────────────────────────────

class _PromotionsTab extends ConsumerWidget {
  const _PromotionsTab({required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promosAsync = ref.watch(promoListProvider);

    return promosAsync.when(
      loading: () => const Center(child: TailWagLoader()),
      error: (_, _) => const PetfolioEmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No promotions yet',
        subtitle:
            "Exclusive deals and offers from\nthe Petfolio marketplace will\nappear here.",
      ),
      data: (promos) {
        if (promos.isEmpty) {
          return const PetfolioEmptyState(
            icon: Icons.local_offer_outlined,
            title: 'No promotions yet',
            subtitle:
                "Exclusive deals and offers from\nthe Petfolio marketplace will\nappear here.",
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.paddingOf(context).bottom + 24,
          ),
          itemCount: promos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _PromoNotifCard(
            promo: promos[i],
            isDark: isDark,
            pt: pt,
          )
              .animate(delay: Duration(milliseconds: 40 * i))
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.08, end: 0, duration: 280.ms, curve: Curves.easeOutCubic),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Promo deal card shown in the Promotions tab
// ─────────────────────────────────────────────────────────────────────────────

class _PromoNotifCard extends StatelessWidget {
  const _PromoNotifCard({
    required this.promo,
    required this.isDark,
    required this.pt,
  });

  final Promo promo;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? pt.surface2 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.poppy.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_offer_rounded,
                    size: 18, color: AppColors.poppy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  promo.code,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: pt.ink950,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tangerine.withAlpha(22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.discountLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tangerine,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promo.description,
            style: TextStyle(fontSize: 13, color: pt.ink500, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: pt.ink300),
              const SizedBox(width: 4),
              Text(
                promo.validUntilFormatted,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: pt.ink500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.poppy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Copy code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
