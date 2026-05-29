# PetFolio "Social" Feature Architecture & Code Review

This document provides a comprehensive code and architectural review of the **Social** feature in the PetFolio Flutter codebase. The findings and recommendations are structured around the five critical areas requested, referencing the design spec `PetFolio Redesign/social.jsx`, database schema guidelines, and the Supabase UX review.

---

## 1. Architecture & Clean Code

### Findings & Evaluation

- **Layer Separation:** The feature is organized in a feature-first architecture (`lib/features/social/`) with `data/` (models, repositories) and `presentation/` (controllers, screens, widgets) folders. This cleanly separates UI from data-fetching and business logic.
- **Provider Consistency (Manual vs. Generated):** The feature currently defines Riverpod providers manually (e.g., `AsyncNotifierProvider.family`, `Provider.family`) instead of using the `@riverpod` code generation system. This violates the repository standard of using generated notifiers.
- **Import Guidelines:** Imports are generally clean, and there are no circular dependencies (e.g., no screen imports `router.dart` directly; all deep links navigate using path query parameters).

### Recommendations & Refactoring

Migrate manual controllers/providers to use the `riverpod_generator` syntax. Note that under Riverpod 3 (used in `pubspec.yaml`), generated notifier classes omit explicit generic type parameters (`extends _$ClassName`), and we use `.value` instead of `.valueOrNull`.

Here is the refactored, generated version of the `SocialNotifier` in `lib/features/social/presentation/controllers/social_controller.dart`:

```dart
// lib/features/social/presentation/controllers/social_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

part 'social_controller.g.dart';

const int _feedPageSize = 15;

class SocialFeedState {
  const SocialFeedState({
    this.posts = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextOffset = 0,
  });

  final List<FeedPost> posts;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;

  SocialFeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
  }) =>
      SocialFeedState(
        posts: posts ?? this.posts,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        nextOffset: nextOffset ?? this.nextOffset,
      );
}

@riverpod
class SocialNotifier extends _$SocialNotifier {
  @override
  FutureOr<SocialFeedState> build(String petId) async {
    // Register cleanup on dispose
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    final posts = await ref.read(socialRepositoryProvider).fetchFeed(
      activePetId: petId,
      limit: _feedPageSize,
      offset: 0,
    );

    _subscribeToRealtime(petId);

    return SocialFeedState(
      posts: posts,
      hasMore: posts.length >= _feedPageSize,
      nextOffset: posts.length,
    );
  }

  RealtimeChannel? _channel;

  void _subscribeToRealtime(String petId) {
    if (!ref.mounted) return;
    _channel = Supabase.instance.client
        .channel('social_feed_$petId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final newRow = payload.newRecord;
            final postId = newRow['id'] as String?;
            if (postId == null) return;

            final likeCount = newRow['like_count'] as int?;
            final commentCount = newRow['comment_count'] as int?;

            final current = state.value;
            if (current == null) return;

            final idx = current.posts.indexWhere((p) => p.id == postId);
            if (idx == -1) return;

            final updated = List<FeedPost>.from(current.posts)
              ..[idx] = current.posts[idx].copyWithCounts(
                likes: likeCount,
                comments: commentCount,
              );

            state = AsyncData(current.copyWith(posts: updated));
          },
        )
        .subscribe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final posts = await ref.read(socialRepositoryProvider).fetchFeed(
        activePetId: arg,
        limit: _feedPageSize,
        offset: 0,
      );
      state = AsyncData(SocialFeedState(
        posts: posts,
        hasMore: posts.length >= _feedPageSize,
        nextOffset: posts.length,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final more = await ref.read(socialRepositoryProvider).fetchFeed(
        activePetId: arg,
        limit: _feedPageSize,
        offset: current.nextOffset,
      );

      if (!ref.mounted) return;

      final existingIds = current.posts.map((p) => p.id).toSet();
      final newPosts = more.where((p) => !existingIds.contains(p.id)).toList();

      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: more.length >= _feedPageSize,
        nextOffset: current.nextOffset + more.length,
      ));
    } catch (_) {
      if (ref.mounted) {
        final cur = state.value;
        if (cur != null) state = AsyncData(cur.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> toggleLike(String postId) async {
    final current = state.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = current.posts[idx];
    final nowLiked = !post.isLiked;

    final updated = List<FeedPost>.from(current.posts)
      ..[idx] = post.copyWithLike(liked: nowLiked);
    state = AsyncData(current.copyWith(posts: updated));

    try {
      await ref.read(socialRepositoryProvider).toggleLike(
        postId: postId,
        petId: arg,
        liked: nowLiked,
      );
    } catch (e) {
      state = AsyncData(current);
      AppSnackBar.showError(e);
    }
  }
}
```

---

## 2. Supabase Integration

### Critical Bug: Realtime Notification Joins

#### Problematic Code Snippet (`lib/features/social/data/repositories/notification_repository.dart`)

```dart
  Stream<List<AppNotification>> watchNotifications(String recipientPetId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_pet_id', recipientPetId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows
            .map((row) => AppNotification.fromJson(row))
            .toList());
  }
```

#### Diagnostic Analysis
Supabase Realtime `.stream(...)` queries do **not** support relational joins. They return only raw table rows. As a result, the `actor_pet` object is omitted from the stream payloads. When `AppNotification.fromJson` is invoked, the missing relation causes fallback values (`@unknown` and `Unknown`) to be rendered in the UI list whenever a new notification is streamed.

#### Refactored, Production-Ready Solution
Convert `NotificationNotifier` into an `AsyncNotifier` that performs a join query on initialization and listens to realtime insert/update events on the `notifications` table to refresh the dataset.

```dart
// lib/features/social/presentation/controllers/notification_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

part 'notification_controller.g.dart';

@riverpod
class Notifications extends _$Notifications {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<AppNotification>> build() async {
    final activePet = ref.watch(activePetControllerProvider);
    if (activePet == null) return const [];

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    // 1. Initial load utilizing join query
    final notifications = await ref
        .read(notificationRepositoryProvider)
        .fetchNotifications(activePet.id);

    // 2. Setup Postgres Changes subscription to update state on modification
    if (ref.mounted) {
      _channel = Supabase.instance.client
          .channel('notifications_${activePet.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: 'recipient_pet_id=eq.${activePet.id}',
            callback: (payload) async {
              // Re-fetch the full list with joins to avoid missing actor details
              final updated = await ref
                  .read(notificationRepositoryProvider)
                  .fetchNotifications(activePet.id);
              state = AsyncData(updated);
            },
          )
          .subscribe();
    }

    return notifications;
  }

  Future<void> markAllRead() async {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return;

    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());

    try {
      await ref.read(notificationRepositoryProvider).markAllRead(activePet.id);
    } catch (_) {
      // Reconciles on next stream update
    }
  }
}
```

### Performance & DB Optimizations

1. **Row Level Security (RLS) Performance:** 
   Several migrations (e.g., `20260514000002_add_comments_table.sql` and `20260514000000_add_follows_table.sql`) use direct `auth.uid()` calls per row:
   ```sql
   CREATE POLICY "comments: insert own" ON public.comments FOR INSERT WITH CHECK (author_id = auth.uid());
   ```
   **Fix:** Wrap auth checks in a subselect to force Postgres to cache it:
   ```sql
   CREATE POLICY "comments: insert own" ON public.comments FOR INSERT WITH CHECK (author_id = (SELECT auth.uid()));
   ```
2. **Missing Database Indexes:**
   To guarantee rapid query execution as feed volume grows, ensure the following foreign-key and filter indexes exist in the Supabase DB:
   ```sql
   CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
   ```
   ```sql
   CREATE INDEX IF NOT EXISTS idx_post_likes_pet_id ON public.post_likes(pet_id);
   ```
   ```sql
   CREATE INDEX IF NOT EXISTS idx_notifications_actor_pet_id ON public.notifications(actor_pet_id);
   ```

---

## 3. State Management & Performance

### Findings & Problems

- **Rebuilds on Active Pet Metadata changes:**
  `SocialScreen` watches `activePetControllerProvider` which exposes the complete `Pet` object:
  ```dart
  final pet = ref.watch(activePetControllerProvider);
  ```
  If any metadata (such as weight, date of birth) changes on the active pet, the screen will rebuild, recreating the `ScrollController` and triggering a reload.
  **Fix:** Watch `activePetIdProvider` inside `SocialScreen`, and only watch detailed metadata within child components (e.g. `_StoriesRow`) to prevent broad UI resets.
- **Scroll Controller Lifecycle:**
  `_SocialViewState` creates `_scrollController` in `initState` but does not reset the offset or fetch states when switching between pets (if `widget.pet.id` updates, `ScrollController` offset is preserved).
- **Custom Reaction & Double-Tap Sync Issues:**
  In `_PostCardState`, custom emoji selections from the picker and double-tap actions display animations locally but **do not write likes to the database**. Moreover, clicking the React button when already liked is ignored (unlike is not supported via direct tap on the card).

### Refactored, Production-Ready Solution

Below is the refactored `_PostCardState` to handle the double-tap location capture, full unliking, and synchronizing custom reaction choices to the repository:

```dart
// lib/features/social/presentation/screens/social_screen.dart -> _PostCardState
class _PostCardState extends State<_PostCard> {
  String? _reacted;
  bool _pickerOpen = false;
  final List<ReactionBurstItem> _bursts = [];
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    if (widget.post.isLiked) {
      _reacted = 'paw';
    }
  }

  @override
  void didUpdateWidget(_PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isLiked != oldWidget.post.isLiked) {
      setState(() {
        _reacted = widget.post.isLiked ? (_reacted ?? 'paw') : null;
      });
    }
  }

  void _fireBurst(String kind, double x, double y) {
    final count = 8 + Random().nextInt(4);
    final newItems = List.generate(count, (i) {
      return ReactionBurstItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        emoji: _emojiForKind(kind),
        dx: x + (Random().nextDouble() - 0.5) * 40,
        dy: y,
      );
    });

    setState(() {
      _bursts.addAll(newItems);
      _reacted = kind;
      _pickerOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() {
          final ids = newItems.map((e) => e.id).toSet();
          _bursts.removeWhere((e) => ids.contains(e.id));
        });
      }
    });
  }

  void _handleReactButtonTap() {
    final isLiked = widget.post.isLiked;
    if (isLiked) {
      // Toggle off / Unlike
      setState(() {
        _reacted = null;
      });
      widget.onLike();
    } else {
      // Toggle on / Like
      _fireBurst('paw', 50, 0);
      widget.onLike();
    }
  }

  void _handlePickerSelection(String kind, double globalX, double globalY) {
    final renderBox = context.findRenderObject() as RenderBox?;
    double localX = 50.0;
    double localY = 0.0;
    if (renderBox != null) {
      final localOffset = renderBox.globalToLocal(Offset(globalX, globalY));
      localX = localOffset.dx;
      localY = localOffset.dy;
    }

    _fireBurst(kind, localX, localY);
    if (!widget.post.isLiked) {
      widget.onLike();
    }
  }

  String _emojiForKind(String kind) {
    switch (kind) {
      case 'paw': return '🐾';
      case 'heart': return '❤️';
      case 'treat': return '🦴';
      case 'star': return '⭐';
      default: return '🐾';
    }
  }

  Color _colorForKind(String kind) {
    switch (kind) {
      case 'paw': return AppColors.tangerine;
      case 'heart': return AppColors.poppy;
      case 'treat': return AppColors.sunny;
      case 'star': return AppColors.lilac;
      default: return AppColors.tangerine;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ink950 = pt.ink950;
    final ink500 = pt.ink500;
    final totalLikes = widget.post.likes + (_reacted != null && !widget.post.isLiked ? 1 : 0);

    return PfCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header ...
              // Photo with double tap tracking
              GestureDetector(
                onTap: widget.onTapPost,
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: () {
                  final details = _doubleTapDetails;
                  double x = 160.0;
                  double y = 200.0;
                  if (details != null) {
                    x = details.localPosition.dx;
                    y = details.localPosition.dy;
                  }
                  _fireBurst('paw', x, y);
                  if (!widget.post.isLiked) {
                    widget.onLike();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.post.subjectColor.withAlpha(50),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: widget.post.imageUrls.isNotEmpty
                          ? CachedNetworkImage(imageUrl: widget.post.imageUrls.first, fit: BoxFit.cover)
                          : const Center(child: Text('🐾', style: TextStyle(fontSize: 64))),
                    ),
                  ),
                ),
              ),
              // Text ...
              // Reaction visualizer ...
              // Actions
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: pt.line))),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleReactButtonTap,
                        onLongPress: () => setState(() => _pickerOpen = !_pickerOpen),
                        child: Container(
                          height: 44,
                          color: Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _reacted != null
                                  ? Text(_emojiForKind(_reacted!), style: const TextStyle(fontSize: 20))
                                  : Icon(Icons.pets, size: 20, color: pt.ink700),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _reacted != null ? '${_reacted![0].toUpperCase()}${_reacted!.substring(1)}' : 'React',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: _reacted != null ? _colorForKind(_reacted!) : pt.ink700,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push('/social/post/${widget.post.id}?focus=true', extra: widget.post),
                        child: const _ActionBtn(icon: Icons.chat_bubble_outline_rounded, label: 'Comment'),
                      ),
                    ),
                    Expanded(child: const _ActionBtn(icon: Icons.ios_share_rounded, label: 'Share')),
                    Expanded(child: const _ActionBtn(icon: Icons.bookmark_border_rounded, label: 'Save')),
                  ],
                ),
              ),
            ],
          ),
          if (_pickerOpen)
            Positioned(
              bottom: 52,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: const Color(0x4D783C14), blurRadius: 32, spreadRadius: -10, offset: const Offset(0, 16)),
                    BorderSide(color: pt.line).toBoxShadow(),
                  ],
                ),
                child: Row(
                  children: [
                    _ReactPickerBtn(emoji: '🐾', kind: 'paw', onTap: (x, y) => _handlePickerSelection('paw', x, y)),
                    _ReactPickerBtn(emoji: '❤️', kind: 'heart', onTap: (x, y) => _handlePickerSelection('heart', x, y)),
                    _ReactPickerBtn(emoji: '🦴', kind: 'treat', onTap: (x, y) => _handlePickerSelection('treat', x, y)),
                    _ReactPickerBtn(emoji: '⭐', kind: 'star', onTap: (x, y) => _handlePickerSelection('star', x, y)),
                  ],
                ),
              ),
            ),
          if (_bursts.isNotEmpty)
            Positioned.fill(
              child: ReactionBurst(items: _bursts),
            ),
        ],
      ),
    );
  }
}
```

---

## 4. UI/UX Fidelity

### Evaluation against React Design (`social.jsx`)

1. **Unresponsive Comment Button:**
   In `social.jsx`, clicking comment opens the detailed comment sheet/context. In Flutter, the comment action button was a static `_ActionBtn` with no callback. Wrapping it in a `GestureDetector` that routes to `/social/post/:postId?focus=true` matches design expectations.
2. **Dashed Stories Add Button:**
   The design file outlines a custom dashed story circle for adding a story. The current Flutter implementation uses `CustomPaint` with a `DashedCirclePainter` and overlayed badge. This correctly mirrors the spec.
3. **Harmonious Theme & Accent Gradients:**
   `social.jsx` specifies color schemes like `var(--mint)` and `var(--sky)`. The Flutter implementation maps these correctly using a deterministic `_paletteFor(species)` helper in the repository to load mulberry/meadow/blue theme tokens depending on whether the post pet is a cat, rabbit, or dog.

---

## 5. Testing

### Missing Test Assessment

The `test/` directory contains no test files for the social feature. To align with our `dart-add-unit-test` and `flutter-add-integration-test` guidelines, we must add unit and widget test cases.

### Test Implementations

#### A. Unit Test for `SocialNotifier`

This unit test ensures that liking/unliking a post optimistically updates state, handles repository successes, and rolls back gracefully on network errors.

```dart
// test/features/social/presentation/controllers/social_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/features/social/data/repositories/social_repository.dart';
import 'package:petfolio/features/social/presentation/controllers/social_controller.dart';
import 'package:petfolio/features/social/data/models/feed_post.dart';

import 'social_controller_test.mocks.dart';

@GenerateMocks([SocialRepository])
void main() {
  late MockSocialRepository mockRepo;
  late ProviderContainer container;

  final dummyPost = FeedPost(
    id: 'p1',
    petId: 'pet1',
    handle: 'tester',
    petName: 'Testy',
    petSpecies: 'dog',
    accentColor: Colors.blue,
    fuzzyLocation: 'Lab',
    caption: 'Liking this post',
    likes: 5,
    comments: 2,
    timeAgo: '2h',
    isLiked: false,
    gradientColors: [Colors.blue, Colors.white],
    subjectColor: Colors.blue,
    imageUrls: [],
  );

  setUp(() {
    mockRepo = MockSocialRepository();
    container = ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('toggleLike optimistically likes, calls repo, and updates state', () async {
    when(mockRepo.fetchFeed(activePetId: anyNamed('activePetId'), limit: anyNamed('limit'), offset: anyNamed('offset')))
        .thenAnswer((_) async => [dummyPost]);
    when(mockRepo.toggleLike(postId: 'p1', petId: 'pet1', liked: true))
        .thenAnswer((_) async => {});

    final notifier = container.read(socialControllerProvider('pet1').notifier);
    await container.read(socialControllerProvider('pet1').future);

    // Act
    await notifier.toggleLike('p1');

    // Assert
    final state = container.read(socialControllerProvider('pet1')).value;
    expect(state!.posts.first.isLiked, isTrue);
    expect(state.posts.first.likes, 6);
    verify(mockRepo.toggleLike(postId: 'p1', petId: 'pet1', liked: true)).called(1);
  });

  test('toggleLike rolls back state on repository failure', () async {
    when(mockRepo.fetchFeed(activePetId: anyNamed('activePetId'), limit: anyNamed('limit'), offset: anyNamed('offset')))
        .thenAnswer((_) async => [dummyPost]);
    when(mockRepo.toggleLike(postId: 'p1', petId: 'pet1', liked: true))
        .thenThrow(Exception('Network error'));

    final notifier = container.read(socialControllerProvider('pet1').notifier);
    await container.read(socialControllerProvider('pet1').future);

    // Act
    await notifier.toggleLike('p1');

    // Assert
    final state = container.read(socialControllerProvider('pet1')).value;
    expect(state!.posts.first.isLiked, isFalse);
    expect(state.posts.first.likes, 5);
  });
}
```

#### B. Widget Test for `_PostCard` Reaction Picker

Ensure the reaction picker opens upon long-press and fires the custom emoji selection correctly.

```dart
// test/features/social/presentation/screens/post_card_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/features/social/data/models/feed_post.dart';
import 'package:petfolio/features/social/presentation/screens/social_screen.dart';

void main() {
  final dummyPost = FeedPost(
    id: 'p1',
    petId: 'pet1',
    handle: 'tester',
    petName: 'Testy',
    petSpecies: 'dog',
    accentColor: Colors.blue,
    fuzzyLocation: 'Lab',
    caption: 'Widget test post',
    likes: 5,
    comments: 2,
    timeAgo: '2h',
    isLiked: false,
    gradientColors: [Colors.blue, Colors.white],
    subjectColor: Colors.blue,
    imageUrls: [],
  );

  testWidgets('Long press on React button reveals the reaction picker', (WidgetTester tester) async {
    bool likeToggled = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _PostCard(
                post: dummyPost,
                onLike: () {
                  likeToggled = true;
                },
                onTapPost: () {},
              ),
            ),
          ),
        ),
      ),
    );

    // Find the React button
    final reactBtn = find.text('React');
    expect(reactBtn, findsOneWidget);

    // Perform long press
    await tester.longPress(reactBtn);
    await tester.pumpAndSettle();

    // Verify reaction picker is open (checking for presence of emojis)
    expect(find.text('🐾'), findsWidgets); // Overlap between stack and picker
    expect(find.text('❤️'), findsWidgets);
    expect(find.text('🦴'), findsWidgets);
    expect(find.text('⭐'), findsWidgets);

    // Tap on heart emoji
    await tester.tap(find.text('❤️').last);
    await tester.pumpAndSettle();

    // Verify it called onLike
    expect(likeToggled, isTrue);
    
    // Verify picker was closed
    expect(find.text('⭐'), findsNothing);
  });
}
```
