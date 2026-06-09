import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/main.dart' as app;

bool _appLaunched = false;

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  final end = DateTime.now().add(total);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (condition()) return;
  }
}

Future<void> _pumpApp(WidgetTester tester) async {
  if (!_appLaunched) {
    app.main();
    _appLaunched = true;
    await _waitUntil(
      tester,
      () =>
          _onLoginScreen() ||
          _inAppShell() ||
          find.byKey(const ValueKey('app_tutorial_skip')).evaluate().isNotEmpty,
    );
  }
}

bool _onLoginScreen() => find.text('Welcome back').evaluate().isNotEmpty;

bool _inAppShell() =>
    find.text('Care').evaluate().isNotEmpty ||
    find.text('Social').evaluate().isNotEmpty;

Future<bool> _forceLogout(WidgetTester tester) async {
  if (_onLoginScreen()) return true;

  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    await Supabase.instance.client.auth.signOut();
    await _waitUntil(tester, () => _onLoginScreen());
  }

  return _onLoginScreen();
}

Future<bool> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  if (!_onLoginScreen()) return true;

  await tester.enterText(find.byKey(const ValueKey('login_email')), email);
  await tester.enterText(find.byKey(const ValueKey('login_password')), password);
  await tester.tap(find.byKey(const ValueKey('login_cta')));
  await _waitUntil(
    tester,
    () =>
        _inAppShell() ||
        find.byKey(const ValueKey('app_tutorial_skip')).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 45),
  );

  final skip = find.byKey(const ValueKey('app_tutorial_skip'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await _pumpFor(tester, const Duration(seconds: 2));
  }

  return _inAppShell();
}

Future<void> _tapNavLabel(WidgetTester tester, String label) async {
  final key = ValueKey('nav_${label.toLowerCase()}');
  if (find.byKey(key).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(key));
    await _pumpFor(tester, const Duration(seconds: 4));
    return;
  }
  final bar = find.byType(NavigationBar);
  if (bar.evaluate().isNotEmpty) {
    final nav = find.descendant(of: bar, matching: find.text(label));
    if (nav.evaluate().isNotEmpty) {
      await tester.tap(nav.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 4));
      return;
    }
  }
  final rail = find.byType(NavigationRail);
  if (rail.evaluate().isNotEmpty) {
    final nav = find.descendant(of: rail, matching: find.text(label));
    if (nav.evaluate().isNotEmpty) {
      await tester.tap(nav.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 4));
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  const testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
  const testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
  final hasCredentials = testEmail.isNotEmpty && testPassword.isNotEmpty;

  group('Synthetic Spring — real-life UI validation', () {
    testWidgets('full authenticated journey against live Supabase', (tester) async {
      if (!hasCredentials) return;

      await _pumpApp(tester);

      if (_onLoginScreen()) {
        expect(
          await _login(tester, email: testEmail, password: testPassword),
          isTrue,
          reason: 'Login failed',
        );
      } else {
        expect(_inAppShell(), isTrue);
      }

      expect(find.text('Care'), findsWidgets);
      expect(find.text('Social'), findsWidgets);
      expect(find.text('Market'), findsWidgets);

      await _tapNavLabel(tester, 'Care');
      expect(tester.takeException(), isNull);

      await _tapNavLabel(tester, 'Social');
      await _pumpFor(tester, const Duration(seconds: 5));
      expect(tester.takeException(), isNull);

      await _tapNavLabel(tester, 'Market');
      await _pumpFor(tester, const Duration(seconds: 6));
      expect(find.byKey(const ValueKey<String>('market_action_cart')), findsOneWidget);

      await _tapNavLabel(tester, 'Match');
      await _pumpFor(tester, const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('login validation when logged out', (tester) async {
      await _pumpApp(tester);
      if (!await _forceLogout(tester)) {
        return;
      }

      await tester.tap(find.byKey(const ValueKey('login_cta')));
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.text('Email is required'), findsOneWidget);
    });
  });
}
