import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/platform/web_image_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashed_circle_painter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';

import '../../data/models/feed_post.dart';
import '../../data/models/story.dart';
import '../controllers/social_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/story_controller.dart';
import 'story_viewer_screen.dart';
import 'post_detail_screen.dart';
import '../widgets/reaction_burst.dart';
import '../widgets/post_comments_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petId = ref.watch(activePetIdProvider);
    if (petId != null) return _SocialView(key: ValueKey(petId), petId: petId);

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      backgroundColor: pt.surface1,
      body: Center(
        child: petsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const TailWagLoader(),
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
          data: (_) => const TailWagLoader(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _SocialView extends ConsumerStatefulWidget {
  const _SocialView({super.key, required this.petId});
  final String petId;

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
          .read(socialControllerProvider(widget.petId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(socialControllerProvider(widget.petId));
    final notifier = ref.read(socialControllerProvider(widget.petId).notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ResponsiveLayout.mobileMax;
    final activePet = ref.watch(activePetControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color headerColor = AppColors.poppy; // default social accent
    if (activePet != null) {
      headerColor = activePet.speciesEnum.resolvedAccent(isDark);
      final dbAccent = activePet.accentColor;
      if (dbAccent != null && dbAccent.isNotEmpty && dbAccent != '#FF6B9D') {
        headerColor = AppColors.fromHexString(dbAccent, fallback: headerColor);
      }
    }

    final headerHeight = MediaQuery.paddingOf(context).top + 92.0;

    Widget content = Stack(
      children: [
        // Feed scrolls from y=0; top padding reserves space below the wave header.
        feedAsync.when(
          skipLoadingOnReload: true,
          loading: () => Center(
            child: Padding(
              padding: EdgeInsets.only(top: headerHeight),
              child: const TailWagLoader(label: 'Loading feed…'),
            ),
          ),
          error: (_, _) => Center(
            child: Padding(
              padding: EdgeInsets.only(top: headerHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                  const SizedBox(height: 12),
                  Text('Could not load feed', style: TextStyle(fontSize: 15, color: pt.ink500)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => notifier.refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (feedState) => RefreshIndicator.adaptive(
            onRefresh: notifier.refresh,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Push content below the wave header — no white gap.
                  SliverToBoxAdapter(
                    child: SizedBox(height: headerHeight),
                  ),
                  const SliverToBoxAdapter(
                    child: _StoriesRow(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      sliver: SliverList.builder(
                        itemCount: feedState.posts.length,
                        itemBuilder: (ctx, i) {
                          final post = feedState.posts[i];
                          return Padding(
                            padding: EdgeInsets.only(bottom: i == feedState.posts.length - 1 ? 0 : 18),
                            child: RepaintBoundary(
                              child: PostCard(
                                post: post,
                                onLike: () => notifier.toggleLike(post.id),
                                onTapPost: () => context.push('/social/post/${post.id}', extra: post),
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
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      child: Center(
                        child: Text(
                          "You're all caught up 🐾",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Wave header floats on top — waveColor: transparent so the WavePainter
        // draws nothing below the curve; content scrolls through underneath.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: WaveHeader(
            color: headerColor,
            waveColor: Colors.transparent,
            height: MediaQuery.paddingOf(context).top + 100.0,
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );

    if (isWide) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: content,
        ),
      );
    }

    return Scaffold(
      backgroundColor: pt.surface1,
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(createPostControllerProvider.notifier).setIsStory(false);
          context.push('/social/create-post');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: Text(
          'Post',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final defaultBg = pt.surface2;
    final defaultColor = pt.ink950;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: defaultBg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: defaultColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stories row
// ─────────────────────────────────────────────────────────────────────────────

class _StoriesRow extends ConsumerWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet == null) return const SizedBox.shrink();
    final storiesAsync = ref.watch(storiesProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return storiesAsync.when(
      loading: () => SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonLoader(width: 64, height: 64, borderRadius: 999),
              SizedBox(height: 6),
              SkeletonLoader(width: 52, height: 10),
            ],
          ),
        ),
      ),
      error: (err, stack) {
        debugPrint('Stories load failure: $err\n$stack');
        return SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.poppy, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Failed to load stories',
                  style: TextStyle(fontSize: 12, color: pt.ink500),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref.invalidate(storiesProvider),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
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
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
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
      useRootNavigator: true,
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
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.play_circle_outline_rounded, color: cs.primary),
              title: Text('View story',
                  style: Theme.of(context).textTheme.titleSmall),
              onTap: () {
                Navigator.pop(context);
                context.push('/social/stories?petId=${pet.id}');
              },
            ),
            ListTile(
              leading: Icon(Icons.add_photo_alternate_outlined, color: cs.primary),
              title: Text('Add to story',
                  style: Theme.of(context).textTheme.titleSmall),
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
    final surface = Theme.of(context).colorScheme.surface;
    final ink950 = Theme.of(context).extension<PetfolioThemeExtension>()!.ink950;

    if (isAdd) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CustomPaint(
                  painter: DashedCirclePainter(
                    color: AppColors.tangerine,
                    strokeWidth: 2,
                    dashLength: 6,
                    dashSpace: 4,
                  ),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('📸', style: TextStyle(fontSize: 26)),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.tangerine,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cream, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ink950)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: ringColors.length >= 2 ? ringColors : [ringColors.first, ringColors.first],
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: surface),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: ringColors.first.withAlpha(180),
                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(initial,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ink950),
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

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onTapPost,
  });
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onTapPost;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  String? _reacted;
  bool _pickerOpen = false;
  final List<ReactionBurstItem> _bursts = [];
  TapDownDetails? _doubleTapPosition;
  String? _hoveredReaction;

  Timer? _longPressTimer;
  Offset _pointerDownPosition = Offset.zero;
  bool _dragCancelledTap = false;

  late AnimationController _pickerController;
  late Animation<double> _pickerScaleAnimation;
  late Animation<double> _pickerFadeAnimation;

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
    });

    _pickerController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _pickerOpen = false;
        });
      }
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

  void _onPickerSelected(String kind, [Offset? globalPosition]) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && globalPosition != null) {
      final localOffset = renderBox.globalToLocal(globalPosition);
      _fireBurst(kind, localOffset.dx, localOffset.dy);
    } else {
      _fireBurst(kind, 50, 0);
    }
    if (!widget.post.isLiked) {
      widget.onLike();
    }
  }

  void _togglePicker() {
    if (_pickerOpen) {
      _pickerController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _pickerOpen = false;
          });
        }
      });
    } else {
      setState(() {
        _pickerOpen = true;
      });
      _pickerController.forward();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPosition = event.position;
    _dragCancelledTap = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _pickerOpen = true;
          _hoveredReaction = null;
        });
        _pickerController.forward();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pickerOpen) {
      if ((event.position - _pointerDownPosition).distance > 15) {
        _longPressTimer?.cancel();
        _dragCancelledTap = true;
      }
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localOffset = renderBox.globalToLocal(event.position);
      final x = localOffset.dx;
      final y = localOffset.dy;

      final cardHeight = renderBox.size.height;
      final pickerYStart = cardHeight - 140;
      final pickerYEnd = cardHeight - 10;

      if (y >= pickerYStart && y <= pickerYEnd) {
        final relativeX = x - 12 - 6;
        if (relativeX >= 0 && relativeX <= 192) {
          final index = (relativeX / 48.0).floor().clamp(0, 3);
          final kinds = ['paw', 'heart', 'treat', 'star'];
          final nextHover = kinds[index];
          if (_hoveredReaction != nextHover) {
            setState(() {
              _hoveredReaction = nextHover;
            });
          }
        } else {
          if (_hoveredReaction != null) {
            setState(() {
              _hoveredReaction = null;
            });
          }
        }
      } else {
        if (_hoveredReaction != null) {
          setState(() {
            _hoveredReaction = null;
          });
        }
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    if (_pickerOpen) {
      if (_hoveredReaction != null) {
        final selected = _hoveredReaction!;
        setState(() {
          _hoveredReaction = null;
        });
        _onPickerSelected(selected, event.position);
      } else {
        _togglePicker();
      }
    } else {
      if (!_dragCancelledTap) {
        _handleShortTap();
      }
    }
  }

  void _handleShortTap() {
    if (_reacted == null) {
      _fireBurst('paw', 50, 0);
      widget.onLike();
    } else {
      setState(() {
        _reacted = null;
      });
      widget.onLike();
    }
  }

  String _emojiForKind(String kind) {
    switch(kind) {
      case 'paw': return '🐾';
      case 'heart': return '❤️';
      case 'treat': return '🦴';
      case 'star': return '⭐';
      default: return '🐾';
    }
  }
  
  Color _colorForKind(String kind) {
    switch(kind) {
      case 'paw': return AppColors.tangerine;
      case 'heart': return AppColors.poppy;
      case 'treat': return AppColors.sunny;
      case 'star': return AppColors.lilac;
      default: return AppColors.tangerine;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.post.isLiked) {
      _reacted = 'paw';
    }
    _pickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pickerScaleAnimation = CurvedAnimation(
      parent: _pickerController,
      curve: Curves.easeOutBack,
    );
    _pickerFadeAnimation = CurvedAnimation(
      parent: _pickerController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _pickerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.isLiked != oldWidget.post.isLiked) {
      setState(() {
        if (widget.post.isLiked) {
          _reacted ??= 'paw';
        } else {
          _reacted = null;
        }
      });
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
      squircle: true,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/social/profile/${widget.post.petId}'),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          gradient: SweepGradient(
                            startAngle: 3.84,
                            endAngle: 3.84 + pi * 2,
                            colors: const [
                              AppColors.tangerine,
                              AppColors.poppy,
                              AppColors.sunny,
                              AppColors.mint,
                              AppColors.tangerine,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: CircleAvatar(
                            backgroundColor: widget.post.accentColor,
                            backgroundImage: widget.post.petAvatarUrl != null
                                ? CachedNetworkImageProvider(widget.post.petAvatarUrl!)
                                : null,
                            child: widget.post.petAvatarUrl == null
                                ? Text(
                                    widget.post.petName.isNotEmpty ? widget.post.petName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push('/social/profile/${widget.post.petId}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.petName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: ink950)),
                            Text(
                              widget.post.fuzzyLocation.isEmpty
                                  ? '@${widget.post.handle} · ${widget.post.timeAgo}'
                                  : '@${widget.post.handle} · ${widget.post.fuzzyLocation} · ${widget.post.timeAgo}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ink500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _IconBtn(
                      icon: Icons.more_horiz,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => PostOptionsSheet(post: widget.post),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Photo
              GestureDetector(
                onTap: widget.onTapPost,
                onDoubleTapDown: (details) {
                  _doubleTapPosition = details;
                },
                onDoubleTap: () {
                  if (_doubleTapPosition != null) {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final localOffset = renderBox.globalToLocal(_doubleTapPosition!.globalPosition);
                      _fireBurst('paw', localOffset.dx, localOffset.dy);
                    } else {
                      _fireBurst('paw', (context.size?.width ?? 320) / 2, 100);
                    }
                  } else {
                    _fireBurst('paw', (context.size?.width ?? 320) / 2, 100);
                  }
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
                        ? CachedNetworkImage(
                            imageUrl: widget.post.imageUrls.first,
                            fit: BoxFit.cover,
                            memCacheWidth: networkImageMemCacheWidth(
                              context,
                              MediaQuery.sizeOf(context).width - 28,
                              maxPixels: webNetworkImageMemCacheFeed,
                            ),
                            maxWidthDiskCache: networkImageMaxDiskCacheWidth(
                              context,
                              MediaQuery.sizeOf(context).width - 28,
                              maxPixels: webNetworkImageMemCacheFeed,
                            ),
                          )
                        : Center(
                            child: Container(
                              width: 150,
                              height: 160,
                              decoration: BoxDecoration(
                                color: widget.post.subjectColor.withAlpha(160),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(90),
                                  topRight: Radius.circular(75),
                                  bottomLeft: Radius.circular(60),
                                  bottomRight: Radius.circular(100),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text('🐾', style: TextStyle(fontSize: 64)),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              
              // Text
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(widget.post.caption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ink950,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        )),
              ),
              
              // Reaction stack visualizer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    // Overlapping emoji circles — fixed width prevents overflow
                    SizedBox(
                      width: 24 + 18 + 18, // 3 circles × 24px, overlapping by 6px each
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned(left: 0,  child: _EmojiCircle(emoji: '🐾', color: AppColors.tangerine, index: 0)),
                          const Positioned(left: 18, child: _EmojiCircle(emoji: '❤️', color: AppColors.poppy,     index: 0)),
                          const Positioned(left: 36, child: _EmojiCircle(emoji: '🦴', color: AppColors.sunny,     index: 0)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$totalLikes reacted · ${widget.post.comments} comments',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pt.ink700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).extension<PetfolioThemeExtension>()!.line)),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Listener(
                        onPointerDown: _onPointerDown,
                        onPointerMove: _onPointerMove,
                        onPointerUp: _onPointerUp,
                        onPointerCancel: (event) => _longPressTimer?.cancel(),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
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
                    ),
                    Expanded(
                      child: _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Comment',
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useRootNavigator: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => PostCommentsBottomSheet(
                              postId: widget.post.id,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(child: const _ActionBtn(icon: Icons.ios_share_rounded, label: 'Share')),
                    Expanded(child: const _ActionBtn(icon: Icons.bookmark_border_rounded, label: 'Save')),
                  ],
                ),
              ),
            ],
          ),
          
          // Picker
          if (_pickerOpen)
            Positioned(
              bottom: 52,
              left: 12,
              child: FadeTransition(
                opacity: _pickerFadeAnimation,
                child: ScaleTransition(
                  scale: _pickerScaleAnimation,
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(color: Color(0x4D783C14), blurRadius: 32, spreadRadius: -10, offset: const Offset(0, 16)),
                        BorderSide(color: Theme.of(context).extension<PetfolioThemeExtension>()!.line).toBoxShadow()
                      ],
                    ),
                    child: Row(
                      children: [
                        _ReactPickerBtn(emoji: '🐾', kind: 'paw', onTap: (details) => _onPickerSelected('paw', details.globalPosition), isHovered: _hoveredReaction == 'paw'),
                        _ReactPickerBtn(emoji: '❤️', kind: 'heart', onTap: (details) => _onPickerSelected('heart', details.globalPosition), isHovered: _hoveredReaction == 'heart'),
                        _ReactPickerBtn(emoji: '🦴', kind: 'treat', onTap: (details) => _onPickerSelected('treat', details.globalPosition), isHovered: _hoveredReaction == 'treat'),
                        _ReactPickerBtn(emoji: '⭐', kind: 'star', onTap: (details) => _onPickerSelected('star', details.globalPosition), isHovered: _hoveredReaction == 'star'),
                      ],
                    ),
                  ),
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

class _EmojiCircle extends StatelessWidget {
  const _EmojiCircle({required this.emoji, required this.color, required this.index});
  final String emoji;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final circle = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
    if (index == 0) return circle;
    return Transform.translate(
      offset: Offset(-6.0 * index, 0),
      child: circle,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: pt.ink700);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: pt.ink700),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactPickerBtn extends StatelessWidget {
  const _ReactPickerBtn({
    required this.emoji,
    required this.kind,
    required this.onTap,
    required this.isHovered,
  });
  final String emoji;
  final String kind;
  final Function(TapDownDetails) onTap;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return GestureDetector(
      onTapDown: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isHovered ? 48 : 42,
        height: isHovered ? 48 : 42,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isHovered ? pt.cream : pt.surface2,
          shape: BoxShape.circle,
          border: isHovered ? Border.all(color: AppColors.tangerine, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isHovered ? 1.25 : 1.0,
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

extension on BorderSide {
  BoxShadow toBoxShadow() => BoxShadow(color: color, blurRadius: 0, spreadRadius: width);
}
