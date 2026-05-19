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

  static void showBadgeUnlocked() {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C7C54),
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.military_tech_rounded, color: Color(0xFFFFD54F), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '7-day streak hero badge unlocked!',
                style: const TextStyle(
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
}
