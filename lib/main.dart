import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'marionette_debug_gate_stub.dart'
    if (dart.library.io) 'marionette_debug_gate_io.dart'
    as marionette_gate;
import 'core/firebase/fcm_service.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'core/platform/platform_notifications.dart';
import 'core/services/stripe_init_service.dart';
import 'core/theme/theme.dart';
import 'core/widgets/app_snack_bar.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

void _assertEnvVars() {
  final missing = <String>[
    if (_supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (_supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    if (_stripePublishableKey.isEmpty) 'STRIPE_PUBLISHABLE_KEY',
  ];
  if (missing.isNotEmpty) {
    throw StateError(
      'Missing required --dart-define variables: ${missing.join(', ')}.\n'
      'Run the app with:\n'
      '  flutter run \\\n'
      '    --dart-define=SUPABASE_URL=<url> \\\n'
      '    --dart-define=SUPABASE_ANON_KEY=<key> \\\n'
      '    --dart-define=STRIPE_PUBLISHABLE_KEY=<key>\n'
      'Or use: flutter run --dart-define-from-file=.env',
    );
  }
}

Future<void> main() async {
  final marionetteEnabled = marionette_gate.marionetteEnabledInThisBuild;
  if (marionetteEnabled) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };

  _assertEnvVars();

  GoogleFonts.config.allowRuntimeFetching = kIsWeb;

  if (!kIsWeb) {
    await ensureStripeReady(publishableKey: _stripePublishableKey);
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  if (!kIsWeb) await PlatformNotifications.instance.initialize();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmService.instance.initialize();

  runApp(const ProviderScope(child: PetfolioApp()));
}

class PetfolioApp extends ConsumerWidget {
  const PetfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    FcmService.instance.updateRouter(router);
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((state) async {
        if (state.session != null) {
          await FcmService.instance.syncToken();
        } else {
          await FcmService.instance.clearTokenForSignOut();
        }
      });
    });

    return MaterialApp.router(
      title: 'PetFolio',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appSnackBarMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
