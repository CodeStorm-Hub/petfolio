import 'package:flutter/material.dart';

import '../errors/app_exception.dart';
import '../theme/app_colors.dart';

final GlobalKey<ScaffoldMessengerState> appSnackBarMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppSnackBar {
  AppSnackBar._();

  static void show(String message, {SnackBarAction? action}) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        action: action,
      ),
    );
  }

  static void showSuccess(String message, {SnackBarAction? action}) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    final context = messenger.context;
    final themeStyle = Theme.of(context).snackBarTheme.contentTextStyle ??
                       Theme.of(context).textTheme.bodyMedium;
    final style = themeStyle?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.white,
    ) ?? const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.white,
    );

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: style,
              ),
            ),
          ],
        ),
        action: action,
      ),
    );
  }

  static void showInfo(String message, {SnackBarAction? action}) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        action: action,
      ),
    );
  }

  static void showError(Object error, {VoidCallback? onRetry}) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    final text = error is AppException ? error.message : error.toString();
    final context = messenger.context;
    final themeStyle = Theme.of(context).snackBarTheme.contentTextStyle ??
                       Theme.of(context).textTheme.bodyMedium;
    final style = themeStyle?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.white,
    ) ?? const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: Colors.white,
    );

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.danger,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: style,
              ),
            ),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static void showBadgeUnlocked([String badgeType = '7_day_hero']) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;

    final label = _badgeLabel(badgeType);
    final icon = _badgeIcon(badgeType);
    final context = messenger.context;
    final themeStyle = Theme.of(context).snackBarTheme.contentTextStyle ??
                       Theme.of(context).textTheme.bodyMedium;
    final style = themeStyle?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: Colors.white,
    ) ?? const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: Colors.white,
    );

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.mint700,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(icon, color: AppColors.sunny, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label badge unlocked! 🎉',
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _badgeLabel(String type) => switch (type) {
    'first_log'      => 'First Care Log 🐾',
    '3_day_streak'   => '3-Day Streak 🔥',
    '7_day_hero'     => '7-Day Hero 🏆',
    'routine_master' => 'Routine Master ⭐',
    '30_day_legend'  => '30-Day Legend 👑',
    'care_champion'  => 'Care Champion 💎',
    _                => 'New Badge',
  };

  static IconData _badgeIcon(String type) => switch (type) {
    'first_log'      => Icons.favorite_rounded,
    '3_day_streak'   => Icons.local_fire_department_rounded,
    '7_day_hero'     => Icons.military_tech_rounded,
    'routine_master' => Icons.star_rounded,
    '30_day_legend'  => Icons.emoji_events_rounded,
    'care_champion'  => Icons.diamond_rounded,
    _                => Icons.military_tech_rounded,
  };
}
