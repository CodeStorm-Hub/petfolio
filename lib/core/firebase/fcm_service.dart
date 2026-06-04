import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_snack_bar.dart';
import 'fcm_background_handler.dart';
import 'fcm_message_router.dart';
import 'fcm_token_repository.dart';
import '../../firebase_options.dart';
import 'firebase_env.dart';

typedef FcmForegroundHandler = void Function(RemoteMessage message);

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  StreamSubscription<String>? _tokenRefreshSub;

  FcmTokenRepository get _tokenRepo =>
      FcmTokenRepository(Supabase.instance.client);
  GoRouter? _router;
  FcmForegroundHandler? _onForeground;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  Future<void> initialize({
    GoRouter? router,
    FcmForegroundHandler? onForeground,
  }) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    _router = router;
    _onForeground = onForeground;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission(messaging);
    await syncToken();

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((token) async {
      await _tokenRepo.upsertToken(
        token: token,
        platform: FirebaseEnv.platformLabel,
      );
    });

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleOpened(initial);
  }

  Future<void> _requestPermission(FirebaseMessaging messaging) async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('[FCM] permission: ${settings.authorizationStatus}');
    }
  }

  Future<bool> syncToken() async {
    if (!isAvailable) return false;
    if (!FirebaseEnv.canRequestWebToken) return false;
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    try {
      final messaging = FirebaseMessaging.instance;
      String? token;
      if (kIsWeb) {
        token = await messaging.getToken(vapidKey: FirebaseEnv.vapidKey);
      } else {
        token = await messaging.getToken();
      }
      if (token == null || token.isEmpty) return false;

      await _tokenRepo.upsertToken(
        token: token,
        platform: FirebaseEnv.platformLabel,
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] syncToken failed: $e');
      return false;
    }
  }

  Future<void> clearTokenForSignOut() async {
    if (!isAvailable) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _tokenRepo.deleteToken(token);
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
  }

  void _handleForeground(RemoteMessage message) {
    final custom = _onForeground;
    if (custom != null) {
      custom(message);
      return;
    }
    final title = message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ?? message.data['body'] as String?;
    if (title != null || body != null) {
      AppSnackBar.show([title, body].whereType<String>().join(': '));
    }
  }

  void _handleOpened(RemoteMessage message) {
    final router = _router;
    if (router == null) return;
    FcmMessageRouter.navigate(router, message.data);
  }

  void updateRouter(GoRouter router) => _router = router;

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }
}
