import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/theme/app_theme.dart';
import 'package:petfolio/features/social/data/models/comment.dart';
import 'package:petfolio/features/social/data/models/feed_post.dart';
import 'package:petfolio/features/social/data/repositories/comment_repository.dart';
import 'package:petfolio/features/social/presentation/screens/social_screen.dart';
import 'package:petfolio/features/social/presentation/widgets/post_comments_bottom_sheet.dart';

class MockCommentRepository implements CommentRepository {
  @override
  Future<List<Comment>> fetchComments({
    required String postId,
    required String activePetId,
  }) async {
    return [
      Comment(
        id: 'comment-1',
        postId: postId,
        petId: 'other-pet',
        petName: 'Buddy',
        avatarUrl: null,
        handle: 'buddy',
        content: 'Cute post!',
        createdAt: DateTime.now(),
        likeCount: 1,
        isLiked: false,
        parentId: null,
        isOwnComment: false,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PostCard Widget Tests', () {
    late FeedPost testPost;
    late bool likeCalled;

    setUp(() {
      likeCalled = false;
      testPost = const FeedPost(
        id: 'post-1',
        petId: 'pet-owner',
        handle: 'owner_handle',
        petName: 'Rex',
        petSpecies: 'dog',
        accentColor: Colors.blue,
        fuzzyLocation: 'New York',
        caption: 'Hello World',
        likes: 5,
        comments: 2,
        timeAgo: '1h',
        isLiked: false,
        gradientColors: [Colors.blue, Colors.green],
        subjectColor: Colors.blue,
      );
    });

    Widget buildTestWidget() {
      return ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(MockCommentRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: SingleChildScrollView(
                  child: PostCard(
                    post: testPost,
                    onLike: () {
                      likeCalled = true;
                    },
                    onTapPost: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders basic post card details', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('Hello World'), findsOneWidget);
      expect(find.textContaining('5 reacted'), findsOneWidget);
      expect(find.textContaining('2 comments'), findsOneWidget);
    });

    testWidgets('long press and drag to treat emoji selects it and calls onLike', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final reactFinder = find.text('React');
      expect(reactFinder, findsOneWidget);

      // Start press and hold gesture
      final gesture = await tester.startGesture(tester.getCenter(reactFinder));
      // Pump 300ms to trigger the long press timer
      await tester.pump(const Duration(milliseconds: 300));
      // Let scale animation complete
      await tester.pumpAndSettle();

      // Find the specific treat emoji '🦴' inside the picker (with font size 24)
      final treatPickerEmojiFinder = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == '🦴' && widget.style?.fontSize == 24.0,
      );
      expect(treatPickerEmojiFinder, findsOneWidget);



      // Drag finger over the treat emoji
      await gesture.moveTo(tester.getCenter(treatPickerEmojiFinder));
      await tester.pumpAndSettle();

      // Lift finger to release
      await gesture.up();
      await tester.pumpAndSettle();

      expect(likeCalled, isTrue);
      expect(treatPickerEmojiFinder, findsNothing);

      // Advance time by 2 seconds to dispose of the delayed burst cleanup timer
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('short tap on React button toggles like status', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final reactFinder = find.text('React');
      expect(reactFinder, findsOneWidget);

      await tester.tap(reactFinder);
      await tester.pumpAndSettle();

      expect(likeCalled, isTrue);

      // Advance time to clear burst timer
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('double tap on image triggers onLike', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final imageFinder = find.byType(AspectRatio);
      expect(imageFinder, findsOneWidget);

      // Perform a double tap gesture sequence
      await tester.tap(imageFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(imageFinder);
      await tester.pumpAndSettle();

      expect(likeCalled, isTrue);

      // Advance time by 2 seconds to dispose of the delayed burst cleanup timer
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tapping Comment button opens PostCommentsBottomSheet', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final commentFinder = find.text('Comment');
      expect(commentFinder, findsOneWidget);

      await tester.tap(commentFinder);
      await tester.pumpAndSettle();

      expect(find.byType(PostCommentsBottomSheet), findsOneWidget);
    });
  });
}
