import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../appointments/data/models/appointment.dart';
import '../../../appointments/presentation/controllers/appointment_controller.dart';
import '../../../marketplace/data/models/marketplace_order.dart';
import '../../../marketplace/presentation/controllers/buyer_orders_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unified activity / history screen — Phase 5
// Combines marketplace orders + appointments into a date-grouped timeline.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final appointmentsAsync = ref.watch(appointmentControllerProvider);

    final isLoading =
        ordersAsync.isLoading || appointmentsAsync.isLoading;
    final hasError =
        ordersAsync.hasError || appointmentsAsync.hasError;

    final orders = ordersAsync.value ?? [];
    final appointments = appointmentsAsync.value ?? [];

    final allItems = _buildItems(orders, appointments);
    final filtered = _applyFilter(allItems, _filter);
    final grouped = _groupByDate(filtered);

    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: isDark ? pt.surface1 : AppColors.surface3,
      body: SafeArea(
        top: widget.showHeader,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (push-mode only) ────────────────────────────────────
            if (widget.showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink950,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Activity',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.ink950,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: topPad + 76),

            // ── Filter chips ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _Filter.values.map((f) {
                    final active = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: f.label,
                        emoji: f.emoji,
                        active: active,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filter = f);
                        },
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: isLoading
                  ? const Center(child: TailWagLoader())
                  : hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: pt.ink300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load activity',
                                style: TextStyle(color: pt.ink500),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  ref.invalidate(buyerOrdersProvider);
                                  ref.invalidate(
                                      appointmentControllerProvider);
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? PetfolioEmptyState(
                              icon: Icons.history_rounded,
                              title: 'No ${_filter == _Filter.all ? 'activity' : _filter.label.toLowerCase()} yet',
                              subtitle: _filter == _Filter.orders
                                  ? 'Your marketplace orders will appear here.'
                                  : _filter == _Filter.appointments
                                      ? 'Your vet appointments will appear here.'
                                      : 'Your orders and appointments will appear here.',
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16, 0, 16,
                                32 + MediaQuery.paddingOf(context).bottom,
                              ),
                              itemCount: grouped.length,
                              itemBuilder: (_, i) {
                                final group = grouped[i];
                                return _DateGroup(
                                  label: group.label,
                                  items: group.items,
                                  isDark: isDark,
                                  pt: pt,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ActivityItem> _buildItems(
    List<MarketplaceOrder> orders,
    List<Appointment> appointments,
  ) {
    final items = <_ActivityItem>[];
    for (final o in orders) {
      items.add(_ActivityItem.fromOrder(o));
    }
    for (final a in appointments) {
      items.add(_ActivityItem.fromAppointment(a));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<_ActivityItem> _applyFilter(
      List<_ActivityItem> items, _Filter filter) {
    return switch (filter) {
      _Filter.all => items,
      _Filter.orders => items.where((i) => i.isOrder).toList(),
      _Filter.appointments =>
        items.where((i) => i.isAppointment).toList(),
    };
  }

  List<_DateGroupData> _groupByDate(List<_ActivityItem> items) {
    final map = <String, List<_ActivityItem>>{};
    for (final item in items) {
      final label = _dateGroupLabel(item.date);
      map.putIfAbsent(label, () => []).add(item);
    }
    // Preserve order (LinkedHashMap insertion order = newest-first via sorted input)
    return map.entries
        .map((e) => _DateGroupData(label: e.key, items: e.value))
        .toList();
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _dateGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter enum
// ─────────────────────────────────────────────────────────────────────────────

enum _Filter { all, orders, appointments }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.orders => 'Orders',
        _Filter.appointments => 'Appointments',
      };

  String get emoji => switch (this) {
        _Filter.all => '⚡',
        _Filter.orders => '🛍️',
        _Filter.appointments => '🏥',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified activity item
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityItem {
  const _ActivityItem._({
    required this.date,
    required this.isOrder,
    required this.title,
    required this.subtitle,
    required this.trailingValue,
    required this.statusColor,
    required this.statusLabel,
    required this.emoji,
    required this.actionLabel,
    required this.actionRoute,
    this.isAppointment = false,
  });

  factory _ActivityItem.fromOrder(MarketplaceOrder o) => _ActivityItem._(
        date: o.createdAt,
        isOrder: true,
        title: o.title,
        subtitle: '${o.lineItems.length} item${o.lineItems.length == 1 ? '' : 's'}',
        trailingValue: o.amountFormatted,
        statusColor: switch (o.status) {
          OrderStatus.pending || OrderStatus.processing => AppColors.tangerine,
          OrderStatus.shipped => AppColors.sky,
          OrderStatus.delivered => AppColors.mint,
          OrderStatus.cancelled => AppColors.poppy,
        },
        statusLabel: o.status.label,
        emoji: '🛍️',
        actionLabel: o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled
            ? 'Reorder'
            : 'Track Order',
        actionRoute: '/marketplace/order/${o.id}',
      );

  factory _ActivityItem.fromAppointment(Appointment a) {
    final now = DateTime.now();
    final missed = !a.isCompleted && a.scheduledAt.isBefore(now);
    return _ActivityItem._(
      date: a.scheduledAt,
      isOrder: false,
      isAppointment: true,
      title: a.title,
      subtitle: [
        if (a.vetName != null) a.vetName!,
        if (a.clinicName != null) a.clinicName!,
      ].join(' · '),
      trailingValue: _shortDate(a.scheduledAt),
      statusColor: a.isCompleted
          ? AppColors.mint
          : missed
              ? AppColors.poppy
              : AppColors.tangerine,
      statusLabel: a.isCompleted
          ? 'Completed'
          : missed
              ? 'Missed'
              : 'Upcoming',
      emoji: '🏥',
      actionLabel: a.isCompleted ? 'Book Again' : 'View Details',
      actionRoute: '/appointments',
    );
  }

  final DateTime date;
  final bool isOrder;
  final bool isAppointment;
  final String title;
  final String subtitle;
  final String trailingValue;
  final Color statusColor;
  final String statusLabel;
  final String emoji;
  final String actionLabel;
  final String actionRoute;

  static const _mo = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(DateTime dt) =>
      '${_mo[dt.month - 1]} ${dt.day}';
}

class _DateGroupData {
  const _DateGroupData({required this.label, required this.items});
  final String label;
  final List<_ActivityItem> items;
}

// ─────────────────────────────────────────────────────────────────────────────
// Date group header + cards
// ─────────────────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.label,
    required this.items,
    required this.isDark,
    required this.pt,
  });

  final String label;
  final List<_ActivityItem> items;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: pt.ink500,
            ),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityCard(item: item, isDark: isDark, pt: pt),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity card — Pathao timeline card style
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.item,
    required this.isDark,
    required this.pt,
  });

  final _ActivityItem item;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? AppColors.surface0D : Colors.white,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadowE3L,
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                  spreadRadius: -2,
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status dot + emoji icon ──────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.statusColor.withAlpha(isDark ? 50 : 28),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.statusColor,
                          border: Border.all(
                            color: isDark
                                ? AppColors.surface0D
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // ── Title + subtitle ─────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: pt.ink950,
                          height: 1.3,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: pt.ink500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Trailing value + status ──────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.trailingValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: pt.ink950,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.statusColor.withAlpha(isDark ? 50 : 25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Action row ───────────────────────────────────────────────
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDark ? Colors.white.withAlpha(12) : AppColors.line,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push(item.actionRoute);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.poppy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  child: Text(item.actionLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip — matches marketplace _DealChip style
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final String emoji;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label${active ? ", selected" : ""}',
      selected: active,
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? AppColors.poppy
              : (isDark ? AppColors.surface0D : Colors.white),
          border: Border.all(
            color: active
                ? AppColors.poppy
                : (isDark ? Colors.white.withAlpha(20) : AppColors.line),
            width: active ? 0 : 1,
          ),
          boxShadow: active || isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.shadowE3L,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.ink700),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
