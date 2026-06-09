import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/core/widgets/app_shell.dart';

void main() {
  testWidgets('AppShell renders bottom nav labels on mobile', (tester) async {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('home body')),
            ),
          ],
        ),
      ],
      initialLocation: '/home',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pets'), findsOneWidget);
    expect(find.text('Care'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('home body'), findsOneWidget);
  });
}
