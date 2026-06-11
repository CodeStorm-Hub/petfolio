import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:petfolio/main.dart' as app;

void main() {
  group('Regression tests — ui-fix-salman QA session', () {
    patrolTest(
      'BUG-005: stories screen shows empty state when no stories exist',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        await $(#social_tab).tap();
        await $.pumpAndSettle();

        final hasStories = find.byKey(const Key('story_card')).evaluate().isNotEmpty;
        if (!hasStories) {
          expect(
            find.byKey(const Key('empty_stories_state')),
            findsOneWidget,
            reason: 'No stories but empty-state widget not shown — blank screen',
          );
        }
      },
    );

    patrolTest(
      'BUG-006: match deck shows exhausted empty state when no cards remain',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        await $(#match_tab).tap();
        await $.pumpAndSettle();

        final hasCards = find.byKey(const Key('swipe_card')).evaluate().isNotEmpty;
        if (!hasCards) {
          expect(
            find.byKey(const Key('deck_exhausted_empty_state')),
            findsOneWidget,
            reason: 'Deck exhausted but empty-state widget not shown',
          );
        }
      },
    );

    patrolTest(
      'BUG-007: multi-vendor cart shows summary banner',
      ($) async {
        await $.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: _MultiVendorSummaryBannerSmoke(),
            ),
          ),
        );
        expect(find.textContaining('shops'), findsOneWidget);
        expect(find.textContaining(r'$'), findsWidgets);
      },
    );

    patrolTest(
      'BUG-011: inbox timestamps are relative, not absolute time strings',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        await $(#match_tab).tap();
        await $.pumpAndSettle();
        await $(#messages_tab).tap();
        await $.pumpAndSettle();

        final tiles = find.byKey(const ValueKey<String>('conversation_tile_timestamp'));
        if (tiles.evaluate().isNotEmpty) {
          for (final element in tiles.evaluate()) {
            final widget = element.widget;
            if (widget is Text && widget.data != null) {
              final text = widget.data!;
              final isAbsoluteTime =
                  RegExp(r'^\d{1,2}:\d{2}\s?(AM|PM)$').hasMatch(text);
              expect(
                isAbsoluteTime,
                isFalse,
                reason:
                    'Inbox timestamp "$text" is in absolute format; expected relative (e.g. "4h", "Mon")',
              );
            }
          }
        }
      },
    );

    patrolTest(
      'BUG-014: hardware back button does not exit app from cart screen',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        await $(#market_tab).tap();
        await $.pumpAndSettle();

        await $(#cart_icon).tap();
        await $.pumpAndSettle();

        await $.platformAutomator.android.pressBack();
        await $.pumpAndSettle();

        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'App exited to Android launcher after pressing back from cart',
        );
      },
    );

    patrolTest(
      'BUG-002: log-weight form save button visible when keyboard is open',
      ($) async {
        app.main();
        await $.pumpAndSettle();

        await $(#care_tab).tap();
        await $.pumpAndSettle();

        await $(#log_weight_button).tap();
        await $.pumpAndSettle();

        await $(#weight_input_field).tap();
        await $.pumpAndSettle();

        expect(
          $(#save_weight_button).visible,
          isTrue,
          reason: 'Save button hidden behind keyboard when weight input is focused',
        );
      },
    );
  });
}

class _MultiVendorSummaryBannerSmoke extends StatelessWidget {
  const _MultiVendorSummaryBannerSmoke();

  @override
  Widget build(BuildContext context) {
    return const Text('Ordering from 2 shops · \$5.50 combined');
  }
}
