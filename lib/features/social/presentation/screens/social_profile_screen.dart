import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/follow_controller.dart';
import '../controllers/social_profile_controller.dart';

class SocialProfileScreen extends ConsumerWidget {
  const SocialProfileScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final postsAsync = ref.watch(socialProfilePostsProvider(petId));
    final statsAsync = ref.watch(petStatsProvider(petId));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Determine if this profile belongs to the active pet (own profile)
    // or to another pet (public profile).
    final isOwnProfile = activePet?.id == petId;

    // For own profile, we use the activePet data directly.
    // For other profiles, we would need a separate pet-lookup provider.
    // For now, we gracefully handle the case where active pet is null.
    if (activePet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(backgroundColor: cs.surface, leading: const BackButton()),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    // Use activePet for own profile; for other profiles,
    // fall back to a placeholder until a pet-lookup provider is added.
    final profilePetName = isOwnProfile ? activePet.name : 'Pet Profile';
    final profilePetBreed = isOwnProfile ? activePet.breed : null;
    final profilePetBio = isOwnProfile
        ? (activePet.bio != null && activePet.bio!.isNotEmpty
            ? activePet.bio!
            : 'Living my best ${activePet.speciesEnum.name} life. 🐾')
        : '';
    final profileAvatarUrl = isOwnProfile ? activePet.avatarUrl : null;

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          profilePetName,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Profile Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: pt.line200, width: 1.5),
                          image: profileAvatarUrl != null && profileAvatarUrl.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(profileAvatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: pt.surface2,
                        ),
                        child: profileAvatarUrl == null || profileAvatarUrl.isEmpty
                            ? Center(
                                child: Text(
                                  profilePetName.isNotEmpty ? profilePetName[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: pt.ink500,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              'Posts',
                              statsAsync.maybeWhen(
                                data: (s) => s.postCount.toString(),
                                orElse: () => postsAsync.valueOrNull?.length.toString() ?? '-',
                              ),
                              tt,
                            ),
                            _buildStatItem(
                              'Followers',
                              statsAsync.maybeWhen(
                                data: (s) => s.followerCount.toString(),
                                orElse: () => '-',
                              ),
                              tt,
                            ),
                            _buildStatItem(
                              'Following',
                              statsAsync.maybeWhen(
                                data: (s) => s.followingCount.toString(),
                                orElse: () => '-',
                              ),
                              tt,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profilePetName,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (profilePetBreed != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        profilePetBreed,
                        style: TextStyle(color: pt.ink500, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    profilePetBio,
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons: show Edit+Share for own profile,
                  // or Follow+Share for other pets.
                  if (isOwnProfile)
                    _OwnProfileButtons(pet: activePet, pt: pt, cs: cs)
                  else
                    _OtherProfileButtons(petId: petId, pt: pt, cs: cs),
                ],
              ),
            ),
          ),

          // ── Grid View ───────────────────────────────────────────────
          postsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Failed to load posts', style: TextStyle(color: pt.ink500)),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 48, color: pt.ink300),
                        const SizedBox(height: 12),
                        Text('No Posts Yet', style: TextStyle(fontSize: 16, color: pt.ink500)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 2),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      Widget child;
                      if (post.imageUrls.isNotEmpty) {
                        child = CachedNetworkImage(
                          imageUrl: post.imageUrls.first,
                          fit: BoxFit.cover,
                          memCacheWidth: 400, // Small grid thumbnails
                          maxWidthDiskCache: 800,
                          placeholder: (context, url) =>
                              Container(color: pt.surface2),
                          errorWidget: (context, url, error) => Container(
                            color: pt.surface2,
                            child: Icon(Icons.error_outline, color: pt.ink300),
                          ),
                        );
                      } else {
                        // Text post placeholder
                        child = Container(
                          color: post.accentColor.withAlpha(50),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              post.caption,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: post.accentColor,
                              ),
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () => context.push(
                          '/social/post/${post.id}',
                          extra: post,
                        ),
                        child: child,
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, TextTheme tt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Own-profile action buttons (Edit Profile + Share Profile)
// ─────────────────────────────────────────────────────────────────────────────

class _OwnProfileButtons extends StatelessWidget {
  const _OwnProfileButtons({
    required this.pet,
    required this.pt,
    required this.cs,
  });

  final Pet pet;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: pt.line200),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => context.push('/pet/${pet.id}/edit'),
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: pt.line200),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final text =
                    "Check out ${pet.name}'s profile on Petfolio! 🐾\n"
                    "https://petfolio.app/social/profile/${pet.id}";
                SharePlus.instance.share(ShareParams(text: text));
              },
              child: const Text(
                'Share Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Other-pet profile action buttons (Follow / Unfollow + Share)
// ─────────────────────────────────────────────────────────────────────────────

class _OtherProfileButtons extends ConsumerWidget {
  const _OtherProfileButtons({
    required this.petId,
    required this.pt,
    required this.cs,
  });

  final String petId;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(followStatusProvider(petId));
    final isFollowing = followAsync.valueOrNull ?? false;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: followAsync.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton(
                      key: ValueKey(isFollowing),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isFollowing ? Colors.transparent : cs.primary,
                        foregroundColor:
                            isFollowing ? cs.onSurface : Colors.white,
                        side: isFollowing
                            ? BorderSide(color: pt.line200)
                            : null,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          ref.read(followStatusProvider(petId).notifier).toggle(),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: pt.line200),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final text =
                    "Check out this pet's profile on Petfolio! 🐾\n"
                    "https://petfolio.app/social/profile/$petId";
                SharePlus.instance.share(ShareParams(text: text));
              },
              child: const Text(
                'Share Profile',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
