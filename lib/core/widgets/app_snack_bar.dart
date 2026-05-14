import 'package:flutter/material.dart';

import '../errors/app_exception.dart';

final GlobalKey<ScaffoldMessengerState> appSnackBarMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppSnackBar {
  AppSnackBar._();

  static void showError(Object error) {
    final messenger = appSnackBarMessengerKey.currentState;
    if (messenger == null) return;
    final text = error is AppException ? error.message : error.toString();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }
}
