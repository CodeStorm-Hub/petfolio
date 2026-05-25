import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../../data/models/feed_post.dart';
import '../../data/models/story.dart';
import '../controllers/social_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/story_controller.dart';
import 'story_viewer_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet != null) return _SocialView(pet: pet);

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      backgroundColor: pt.surface1,
      body: Center(
        child: petsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const CircularProgressIndicator.adaptive(),
          error: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text('Connection error',
                  style: TextStyle(fontSize: 15, color: pt.ink500)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(petListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
          data: (_) => const CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _SocialView extends ConsumerStatefulWidget {
  const _SocialView({required this.pet});
  final Pet pet;

  @override
  ConsumerState<_SocialView> createState() => _SocialViewState();
}

class _SocialViewState extends ConsumerState<_SocialView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref
          .read(socialControllerProvider(widget.pet.id).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(socialControllerProvider(widget.pet.id));
    final notifier =
        ref.read(socialControllerProvider(widget.pet.id).notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              eyebrow: 'Pack',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              actions: [
                AppHeaderAction(
                  iconKey: const ValueKey<String>('social_action_messages'),
                  icon: Icons.mail_outline_rounded,
                  tooltip: 'Messages',
                  onTap: () => context.push('/matching/inbox'),
                ),
              ],
            ),
            Expanded(
              child: feedAsync.when(
                skipLoadingOnReload: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                      const SizedBox(height: 12),
                      Text('Could not load feed',
                          style: TextStyle(fontSize: 15, color: pt.ink500)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => notifier.refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (feedState) => RefreshIndicator.adaptive(
                  onRefresh: notifier.refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _StoriesRow(pet: widget.pet),
                      ),
                      if (feedState.posts.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No posts yet — be the first to share!',
                              style: TextStyle(color: pt.ink500),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 8),
                          sliver: SliverList.builder(
                            itemCount: feedState.posts.length,
                            itemBuilder: (ctx, i) {
                              final post = feedState.posts[i];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      i == feedState.posts.length - 1 ? 0 : 16,
                                ),
                                child: RepaintBoundary(
                                  child: _RegularPost(
                                    post: post,
                                    onLike: () =>
                                        notifier.toggleLike(post.id),
                                    onTapPost: () => context.push(
                                      '/social/post/${post.id}',
                                      extra: post,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (feedState.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(createPostControllerProvider.notifier).setIsStory(false);
          context.push('/social/create-post');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text(
          'Post',
          style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Sora'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stories row
// ─────────────────────────────────────────────────────────────────────────────

class _StoriesRow extends ConsumerWidget {
  const _StoriesRow({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return storiesAsync.when(
      loading: () => const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (stories) {
        // Group stories by petId
        final grouped = <String, List<Story>>{};
        for (final story in stories) {
          grouped.putIfAbsent(story.petId, () => []).add(story);
        }

        final stacks = grouped.entries.map((e) {
          final first = e.value.first;
          final sortedStories = List<Story>.from(e.value)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return PetStoryStack(
            petId: e.key,
            petName: first.petName,
            petAvatarUrl: first.petAvatarUrl,
            petSpecies: first.petSpecies,
            stories: sortedStories,
          );
        }).toList();

        // Check if active pet has stories
        final activePetStackIdx = stacks.indexWhere((s) => s.petId == pet.id);
        final activePetStack = activePetStackIdx != -1 ? stacks[activePetStackIdx] : null;

        // Other pets' stacks, sorted with unviewed ones first
        final otherStacks = stacks.where((s) => s.petId != pet.id).toList()
          ..sort((a, b) {
            final aUnviewed = a.hasUnviewed(userId);
            final bUnviewed = b.hasUnviewed(userId);
            if (aUnviewed && !bUnviewed) return -1;
            if (!aUnviewed && bUnviewed) return 1;
            final aNewest = a.stories.map((s) => s.createdAt).reduce((v, e) => v.isAfter(e) ? v : e);
            final bNewest = b.stories.map((s) => s.createdAt).reduce((v, e) => v.isAfter(e) ? v : e);
            return bNewest.compareTo(aNewest);
          });

        return SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              // Own Pet Story Item
              if (activePetStack != null)
                _StoryItem(
                  initial: pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                  label: 'Your story',
                  avatarUrl: pet.avatarUrl,
                  ringColors: activePetStack.hasUnviewed(userId)
                      ? const [AppColors.sunset500, AppColors.coral500]
                      : [pt.ink300, pt.ink300],
                  onTap: () => context.push('/social/stories?petId=${pet.id}'),
                  onLongPress: () => _showOwnStoryOptions(context, ref, pet),
                )
              else
                _StoryItem(
                  initial: pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
                  label: 'Your story',
                  avatarUrl: pet.avatarUrl,
                  ringColors: const [AppColors.sunset500, AppColors.coral500],
                  isAdd: true,
                  onTap: () {
                    ref.read(createPostControllerProvider.notifier).setIsStory(true);
                    context.push('/social/create-story');
                  },
                ),

              // Other Pet Story Items
              ...otherStacks.map((stack) {
                final initial = stack.petName.isNotEmpty ? stack.petName[0].toUpperCase() : '?';
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _StoryItem(
                    initial: initial,
                    label: stack.petName,
                    avatarUrl: stack.petAvatarUrl,
                    ringColors: stack.hasUnviewed(userId)
                        ? const [AppColors.sunset500, AppColors.coral500]
                        : [pt.ink300, pt.ink300],
                    onTap: () => context.push('/social/stories?petId=${stack.petId}'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showOwnStoryOptions(BuildContext context, WidgetRef ref, Pet pet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OwnStoryOptionsSheet(pet: pet),
    );
  }
}

class _OwnStoryOptionsSheet extends ConsumerWidget {
  const _OwnStoryOptionsSheet({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${pet.name}\'s Story',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.play_circle_outline_rounded, color: cs.primary),
              title: const Text(
                'View story',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/social/stories?petId=${pet.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.add_photo_alternate_outlined, color: cs.primary),
              title: const Text(
                'Add to story',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(createPostControllerProvider.notifier).setIsStory(true);
                context.push('/social/create-story');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.initial,
    required this.label,
    required this.ringColors,
    this.avatarUrl,
    this.isAdd = false,
    this.onTap,
    this.onLongPress,
  });

  final String initial;
  final String label;
  final List<Color> ringColors;
  final String? avatarUrl;
  final bool isAdd;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ring + avatar
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: ringColors.length >= 2
                        ? ringColors
                        : [ringColors.first, ringColors.first],
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: surface,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: ringColors.first.withAlpha(180),
                    backgroundImage: avatarUrl != null
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            initial,
                            style: tt.titleSmall?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (isAdd)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.sunset500,
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular post
// ─────────────────────────────────────────────────────────────────────────────

class _RegularPost extends StatelessWidget {
  const _RegularPost({
    required this.post,
    required this.onLike,
    required this.onTapPost,
  });
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onTapPost;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface0D : AppColors.surface0,
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        boxShadow: pt.shadowE2,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: post),
          // The PostPhoto handles taps to navigate and double-taps to like.
          _PostPhoto(
            post: post,
            onTap: onTapPost,
            onDoubleTapLike: () {
              if (!post.isLiked) onLike();
            },
          ),
          _RegularFooter(
            post: post,
            onLike: onLike,
            onComment: () => context.push(
              '/social/post/${post.id}?focus=true',
              extra: post,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Memorial post
// ─────────────────────────────────────────────────────────────────────────────


class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final initial =
        post.petName.isNotEmpty ? post.petName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          // Tappable avatar → pet social profile
          GestureDetector(
            onTap: () => context.push('/social/profile/${post.petId}'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: post.accentColor,
              backgroundImage: post.petAvatarUrl != null
                  ? CachedNetworkImageProvider(post.petAvatarUrl!)
                  : null,
              child: post.petAvatarUrl == null
                  ? Text(
                      initial,
                      style: tt.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Tappable pet name + handle + timestamp → pet social profile
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/social/profile/${post.petId}'),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.petName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    post.fuzzyLocation.isEmpty
                        ? '@${post.handle} · ${post.timeAgo}'
                        : '@${post.handle} · ${post.fuzzyLocation} · ${post.timeAgo}',
                    style: tt.labelSmall?.copyWith(color: pt.ink500),
                  ),
                ],
              ),
            ),
          ),
          // More menu
          Icon(Icons.more_horiz_rounded, color: pt.ink500, size: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular post photo area
// ─────────────────────────────────────────────────────────────────────────────

class _PostPhoto extends StatefulWidget {
  const _PostPhoto({
    required this.post,
    required this.onTap,
    required this.onDoubleTapLike,
  });
  final FeedPost post;
  final VoidCallback onTap;
  final VoidCallback onDoubleTapLike;

  @override
  State<_PostPhoto> createState() => _PostPhotoState();
}

class _PostPhotoState extends State<_PostPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartAnim;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _heartAnim.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTapLike();
    setState(() => _showHeart = true);
    _heartAnim.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _heartAnim.reverse().then((_) {
            if (mounted) setState(() => _showHeart = false);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final post = widget.post;
    final colors = post.gradientColors;
    final emoji = switch (post.petSpecies) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      _ => '🐶',
    };

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _handleDoubleTap,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(
            gradient: post.imageUrls.isNotEmpty 
                ? null 
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.length >= 2 ? colors : [colors.first, colors.first],
                  ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Pet blob illustration or Real Image
              if (post.imageUrls.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrls.first,
                    fit: BoxFit.cover,
                    // Optimization: Cap decoded image size in memory.
                    memCacheWidth: 600,
                    maxWidthDiskCache: 1000,
                  ),
                )
              else
                Center(
                  child: Container(
                    width: 150,
                    height: 160,
                    decoration: BoxDecoration(
                      color: post.subjectColor.withAlpha(160),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(90),
                        topRight: Radius.circular(75),
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(100),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 64)),
                  ),
                ),
              // Carousel indicator
              if (post.isCarousel)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      borderRadius: BorderRadius.circular(
                        PetfolioThemeExtension.radiusPill,
                      ),
                    ),
                    child: Text(
                      '1 / 3',
                      style: tt.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Tag badge
              if (post.tag != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(
                        PetfolioThemeExtension.radiusPill,
                      ),
                      border: Border.all(
                        color: Colors.white.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      post.tag!,
                      style: tt.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Big Heart animation overlay
              if (_showHeart)
                Center(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _heartAnim,
                      curve: Curves.easeOutBack,
                      reverseCurve: Curves.easeIn,
                    ),
                    child: Icon(
                      Icons.pets_rounded,
                      size: 100,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular post footer — paw like + comments
// ─────────────────────────────────────────────────────────────────────────────

class _RegularFooter extends StatelessWidget {
  const _RegularFooter({
    required this.post,
    required this.onLike,
    required this.onComment,
  });
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption
          if (post.caption.isNotEmpty)
            Text(
              post.caption,
              style: tt.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          if (post.caption.isNotEmpty) const SizedBox(height: 10),
          // Action row
          Row(
            children: [
              // ── Like ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: onLike,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: PetfolioThemeExtension.durationSm,
                        transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                        child: Icon(
                          post.isLiked
                              ? Icons.pets_rounded
                              : Icons.pets_outlined,
                          key: ValueKey(post.isLiked),
                          color: post.isLiked ? AppColors.coral500 : pt.ink500,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedSwitcher(
                        duration: PetfolioThemeExtension.durationSm,
                        child: Text(
                          '${post.likes}',
                          key: ValueKey(post.likes),
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: post.isLiked ? AppColors.coral500 : pt.ink500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ── Comment ──────────────────────────────────────────────────
              GestureDetector(
                onTap: onComment,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 22,
                        color: pt.ink500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.comments}',
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: pt.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // ── Share ─────────────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  final text =
                      "Check out ${post.petName}'s post on Petfolio! 🐾\nhttps://petfolio.app/social/post/${post.id}";
                  SharePlus.instance.share(ShareParams(text: text));
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Icon(
                    Icons.share_outlined,
                    size: 22,
                    color: pt.ink500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

