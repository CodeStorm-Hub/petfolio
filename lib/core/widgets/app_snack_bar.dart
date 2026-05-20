import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

final GlobalKey<ScaffoldMessengerState> appSnackBarMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppSnackBar {
  AppSnackBar._();

  static void show(String message) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  static void showError(Object error) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    final text = error is AppException ? error.message : error.toString();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  static void showBadgeUnlocked([String badgeType = '7_day_hero']) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;

    final label = _badgeLabel(badgeType);
    final icon  = _badgeIcon(badgeType);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C7C54),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD54F), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label badge unlocked! 🎉',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
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
