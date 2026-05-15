import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/app_snack_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Google Fonts ──────────────────────────────────────────────────────────
  // Disable the runtime CDN fetch.  When the device has no network / DNS
  // (common on freshly-booted Android emulators) `google_fonts` would
  // otherwise throw an UNHANDLED `ClientException: Failed host lookup
  // 'fonts.gstatic.com'` for every TextStyle rebuild — flooding the log and
  // breaking hot reload.  With `allowRuntimeFetching = false` the package
  // silently falls back to the platform default font instead.
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── Stripe ────────────────────────────────────────────────────────────────
  // Publishable key is injected at build time:
  //   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51TQvlrPcVRApxzIxJ8RmKYA1WEw7k8zubumbIfsDjRSGgDyAcSU22RhsZRtKIP1lAZ0wtGjpLfzjI4fozMZxGSlo006zuZrbon',
  );
  Stripe.merchantIdentifier = 'merchant.com.petfolio';
  await Stripe.instance.applySettings();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://jqyjvhwlcqcsuwcqgcwf.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxeWp2aHdsY3Fjc3V3Y3FnY3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1MjI4MjgsImV4cCI6MjA5NDA5ODgyOH0.3bF68bNG0IwAc50YbOC3sem4k8O-d1vkvNNqBt1HbRw',
    ),
  );

  runApp(const ProviderScope(child: PetfolioApp()));
}

class PetfolioApp extends ConsumerWidget {
  const PetfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Petfolio',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appSnackBarMessengerKey,

      // ── Design system themes ─────────────────────────────────────────────
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      routerConfig: router,
    );
  }
}
