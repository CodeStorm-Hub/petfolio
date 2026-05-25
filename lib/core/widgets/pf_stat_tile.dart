import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PfStatTile
//
// A coloured stat tile used in the Home screen quick-stats trio and elsewhere.
// Matches the design: soft background, icon, large number, small label.
// ─────────────────────────────────────────────────────────────────────────────

class PfStatTile extends StatelessWidget {
  const PfStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final Widget icon;
  final String value;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.white.withAlpha(100),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTheme(
            data: IconThemeData(color: textColor, size: 20),
            child: icon,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.ink950D : AppColors.ink950,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PfBadgeTile
//
// A single badge tile for the trophy room / achievements section.
// Locked badges are greyscale and semi-transparent.
// ─────────────────────────────────────────────────────────────────────────────

class PfBadgeTile extends StatelessWidget {
  const PfBadgeTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    this.owned = true,
  });

  final String emoji;
  final String label;
  final Color color;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget tile = Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: owned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.white, 0.3)!,
                      ],
                    )
                  : null,
              color: owned ? null : (isDark ? AppColors.lineD : AppColors.line),
              boxShadow: owned
                  ? [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(46),
                        blurRadius: 0,
                        offset: const Offset(0, -8),
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha(100),
                        blurRadius: 0,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.ink950D : AppColors.ink950,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (!owned) {
      tile = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: Opacity(opacity: 0.45, child: tile),
      );
    }

    return tile;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PfDailyQuestRow
//
// A compact quest/task row for the Home screen today's quests preview.
// ─────────────────────────────────────────────────────────────────────────────

class PfDailyQuestRow extends StatelessWidget {
  const PfDailyQuestRow({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.xp,
    this.done = false,
    this.due = false,
    this.trailing,
  });

  final String icon;
  final String label;
  final String time;
  final int xp;
  final bool done;
  final bool due;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink950 = isDark ? AppColors.ink950D : AppColors.ink950;
    final ink500 = isDark ? AppColors.ink500D : AppColors.ink500;
    final cream2 = isDark ? AppColors.cream2D : AppColors.cream2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: done
                  ? AppColors.mintSoft
                  : due
                      ? AppColors.poppySoft
                      : cream2,
            ),
            child: Center(
              child: Text(
                done ? '✅' : icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ink950,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  due ? 'Due $time' : time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: due ? AppColors.poppy700 : ink500,
                  ),
                ),
              ],
            ),
          ),

          // XP chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: done ? AppColors.mintSoft : AppColors.sunnySoft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+$xp',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: done ? AppColors.mint700 : AppColors.sunny700,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '⭐',
                  style: TextStyle(
                    fontSize: 11,
                    color: done ? AppColors.mint700 : AppColors.sunny700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
