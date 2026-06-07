import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/main.dart' as app;

Future<void> _pumpApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 10));
}

Future<bool> _forceLogout(WidgetTester tester) async {
  if (find.text('Welcome back').evaluate().isNotEmpty) return true;

  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    await Supabase.instance.client.auth.signOut();
    await tester.pumpAndSettle(const Duration(seconds: 10));
  }

  return find.text('Welcome back').evaluate().isNotEmpty;
}

Future<bool> _login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  if (find.text('Welcome back').evaluate().isEmpty) return true;

  await tester.enterText(find.byKey(const ValueKey('login_email')), email);
  await tester.enterText(find.byKey(const ValueKey('login_password')), password);
  await tester.tap(find.byKey(const ValueKey('login_cta')));
  await tester.pumpAndSettle(const Duration(seconds: 12));

  return find.text('Welcome back').evaluate().isEmpty;
}

Future<void> _tapNavLabel(WidgetTester tester, String label) async {
  final nav = find.text(label);
  if (nav.evaluate().isNotEmpty) {
    await tester.tap(nav.last);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
  const testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
  final hasCredentials = testEmail.isNotEmpty && testPassword.isNotEmpty;

  group('Synthetic Spring — real-life UI validation', () {
    testWidgets('unauthenticated: login form validation and register navigation',
        (tester) async {
      await _pumpApp(tester);
      final onLogin = await _forceLogout(tester);
      if (!onLogin) {
        expect(find.text('Pets'), findsWidgets);
        return;
      }

      expect(find.text('Welcome back'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('login_cta')));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);

      final registerLink = find.text("Don't have an account?");
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink);
        await tester.pumpAndSettle();
        expect(find.text('Create account'), findsWidgets);
      }
    });

    testWidgets('app shell reachable when session persisted on device', (tester) async {
      await _pumpApp(tester);

      final onLogin = find.text('Welcome back').evaluate().isNotEmpty;
      if (onLogin) {
        expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
        return;
      }

      expect(find.text('Pets'), findsWidgets);
      expect(find.text('Care'), findsWidgets);
      expect(find.text('Social'), findsWidgets);
      expect(find.text('Market'), findsWidgets);
    });

    if (hasCredentials) {
      testWidgets('authenticated: shell tabs load real Supabase-backed screens',
          (tester) async {
        await _pumpApp(tester);
        final onLogin = await _forceLogout(tester);
        if (!onLogin) return;
        final loggedIn = await _login(
          tester,
          email: testEmail,
          password: testPassword,
        );
        expect(loggedIn, isTrue, reason: 'Login failed — check TEST_EMAIL/TEST_PASSWORD');

        expect(find.text('Pets'), findsWidgets);
        expect(find.text('Care'), findsWidgets);
        expect(find.text('Social'), findsWidgets);
        expect(find.text('Match'), findsWidgets);
        expect(find.text('Market'), findsWidgets);

        await _tapNavLabel(tester, 'Care');
        expect(find.byType(CustomScrollView), findsWidgets);

        await _tapNavLabel(tester, 'Social');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);

        await _tapNavLabel(tester, 'Market');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(find.text('Discover'), findsWidgets);

        await _tapNavLabel(tester, 'Match');
        await tester.pumpAndSettle(const Duration(seconds: 4));

        await _tapNavLabel(tester, 'Pets');
        await tester.pumpAndSettle(const Duration(seconds: 3));
      });

      testWidgets('authenticated: marketplace search and cart affordance', (tester) async {
        await _pumpApp(tester);
        if (!await _forceLogout(tester)) return;
        await _login(tester, email: testEmail, password: testPassword);

        await _tapNavLabel(tester, 'Market');
        final search = find.byType(TextField);
        if (search.evaluate().isNotEmpty) {
          await tester.enterText(search.first, 'food');
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        expect(find.byKey(const ValueKey<String>('market_action_cart')), findsOneWidget);
      });

      testWidgets('authenticated: tutorial overlay can be dismissed when shown',
          (tester) async {
        await _pumpApp(tester);
        if (!await _forceLogout(tester)) return;
        await _login(tester, email: testEmail, password: testPassword);

        final gotIt = find.text('Got it');
        if (gotIt.evaluate().isNotEmpty) {
          await tester.tap(gotIt);
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
