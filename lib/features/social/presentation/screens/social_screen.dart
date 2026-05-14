import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../data/models/feed_post.dart';
import '../controllers/social_controller.dart';

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

class _SocialView extends ConsumerWidget {
  const _SocialView({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(socialControllerProvider(pet.id));
    final notifier = ref.read(socialControllerProvider(pet.id).notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        // bottom: false — the shell scaffold's BottomNavigationBar already
        // insets the body; adding another safe-area bottom pad would create
        // a double gap above the home indicator.
        bottom: false,
        child: Column(
          children: [
            _SocialHeader(pet: pet),
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
                data: (posts) => RefreshIndicator.adaptive(
                  onRefresh: notifier.refresh,
                  child: CustomScrollView(
                    // Keep scroll physics active even when posts is empty so
                    // RefreshIndicator still works.
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _StoriesRow(posts: posts, pet: pet),
                      ),
                      if (posts.isEmpty)
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
                          padding: const EdgeInsets.only(top: 8, bottom: 32),
                          // SliverList.builder lazily builds children as they
                          // scroll into view — optimal for long feeds.
                          sliver: SliverList.builder(
                            itemCount: posts.length,
                            itemBuilder: (ctx, i) {
                              final post = posts[i];
                              final card = _RegularPost(
                                post: post,
                                onLike: () => notifier.toggleLike(post.id),
                              );
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == posts.length - 1 ? 0 : 16,
                                ),
                                child: card,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/social/create'),
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
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _SocialHeader extends StatelessWidget {
  const _SocialHeader({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final initial =
        pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          // Active pet avatar
          GestureDetector(
            onTap: () => context.push('/social/profile/${pet.id}'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.sunset500,
              child: Text(
                initial,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text('Pack', style: tt.headlineMedium),
          const Spacer(),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: pt.pillarSocial,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            onPressed: () => context.push('/social/create'),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.mail_outline_rounded, color: pt.ink500),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stories row
// ─────────────────────────────────────────────────────────────────────────────

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.posts, required this.pet});
  final List<FeedPost> posts;
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        // 1 "Your story" item + one per post
        itemCount: 1 + posts.length,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            final initial =
                pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?';
            return _StoryItem(
              initial: initial,
              label: 'Your story',
              ringColors: const [AppColors.sunset500, AppColors.coral500],
              isAdd: true,
              onTap: () => context.push('/social/create'),
            );
          }
          final post = posts[i - 1];
          final initial =
              post.petName.isNotEmpty ? post.petName[0].toUpperCase() : '?';
          return _StoryItem(
            initial: initial,
            label: post.petName,
            ringColors: [post.accentColor, post.gradientColors.last],
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.initial,
    required this.label,
    required this.ringColors,
    this.isAdd = false,
    this.onTap,
  });
  final String initial;
  final String label;
  final List<Color> ringColors;
  final bool isAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final avatarBg = ringColors.isNotEmpty ? ringColors[0].withAlpha(180) : AppColors.blue500;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ring + avatar
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
                backgroundColor: avatarBg,
                child: isAdd
                    ? const Icon(Icons.add, color: Colors.white, size: 20)
                    : Text(
                        initial,
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: GoogleFonts.inter(
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
  const _RegularPost({required this.post, required this.onLike});
  final FeedPost post;
  final VoidCallback onLike;

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
          _PostPhoto(post: post),
          _RegularFooter(post: post, onLike: onLike),
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
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: post.accentColor,
            child: Text(
              initial,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Handle + location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.handle,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  post.fuzzyLocation.isEmpty
                      ? post.timeAgo
                      : '${post.fuzzyLocation} · ${post.timeAgo}',
                  style: tt.labelMedium?.copyWith(color: pt.ink500),
                ),
              ],
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

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final colors = post.gradientColors;
    final emoji = switch (post.petSpecies) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      _ => '🐶',
    };

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Regular post footer — paw like + comments
// ─────────────────────────────────────────────────────────────────────────────

class _RegularFooter extends StatelessWidget {
  const _RegularFooter({required this.post, required this.onLike});
  final FeedPost post;
  final VoidCallback onLike;

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
          Text(
            post.caption,
            style: tt.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          // Action row
          Row(
            children: [
              // Heart like button — instantly red on tap via optimistic update
              GestureDetector(
                onTap: onLike,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedSwitcher(
                    duration: PetfolioThemeExtension.durationSm,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(post.isLiked),
                      color: post.isLiked
                          ? AppColors.coral500
                          : pt.ink500,
                      size: 24,
                    ),
                  ),
                ),
              ),
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
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 22, color: pt.ink500),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: pt.ink500,
                ),
              ),
              const Spacer(),
              Icon(Icons.share_outlined, size: 20, color: pt.ink500),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

