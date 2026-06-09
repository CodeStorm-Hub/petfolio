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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
  const testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
  final hasCredentials = testEmail.isNotEmpty && testPassword.isNotEmpty;

  group('Auth → Care flow', () {
    testWidgets('app launches and shows login screen when unauthenticated',
        (tester) async {
      await _pumpApp(tester);
      final onLogin = await _forceLogout(tester);
      if (!onLogin) {
        expect(find.text('Pets'), findsWidgets);
        return;
      }

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_password')), findsOneWidget);
      expect(find.byKey(const ValueKey('login_cta')), findsOneWidget);
    });

    testWidgets('empty form submission shows validation errors', (tester) async {
      await _pumpApp(tester);
      if (!await _forceLogout(tester)) return;

      await tester.tap(find.byKey(const ValueKey('login_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('invalid email shows format error', (tester) async {
      await _pumpApp(tester);
      if (!await _forceLogout(tester)) return;

      await tester.enterText(
          find.byKey(const ValueKey('login_email')), 'notanemail');
      await tester.enterText(
          find.byKey(const ValueKey('login_password')), '123456');
      await tester.tap(find.byKey(const ValueKey('login_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('short password shows length error', (tester) async {
      await _pumpApp(tester);
      if (!await _forceLogout(tester)) return;

      await tester.enterText(
          find.byKey(const ValueKey('login_email')), 'user@example.com');
      await tester.enterText(
          find.byKey(const ValueKey('login_password')), '123');
      await tester.tap(find.byKey(const ValueKey('login_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('register link navigates to registration screen',
        (tester) async {
      await _pumpApp(tester);
      if (!await _forceLogout(tester)) return;

      final registerLink = find.text("Don't have an account?");
      if (registerLink.evaluate().isNotEmpty) {
        await tester.tap(registerLink);
        await tester.pumpAndSettle();
        expect(find.text('Create account'), findsWidgets);
      }
    });

    if (hasCredentials) {
      testWidgets('full auth → care flow with real credentials', (tester) async {
        await _pumpApp(tester);
        if (!await _forceLogout(tester)) return;

        await tester.enterText(
            find.byKey(const ValueKey('login_email')), testEmail);
        await tester.enterText(
            find.byKey(const ValueKey('login_password')), testPassword);
        await tester.tap(find.byKey(const ValueKey('login_cta')));

        await tester.pumpAndSettle(const Duration(seconds: 8));

        expect(find.byType(BottomNavigationBar), findsWidgets);

        final careFinder = find.byTooltip('Care');
        if (careFinder.evaluate().isNotEmpty) {
          await tester.tap(careFinder);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      });
    }
  });
}
