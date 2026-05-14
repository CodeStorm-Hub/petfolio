import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/social_profile_controller.dart';

class SocialProfileScreen extends ConsumerWidget {
  const SocialProfileScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, assuming we are viewing the active pet's profile.
    // If viewing another pet in the future, we would look it up from a pet list provider.
    final pet = ref.watch(activePetControllerProvider);
    final postsAsync = ref.watch(socialProfilePostsProvider(petId));
    final statsAsync = ref.watch(petStatsProvider(petId));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    // Handle case where pet is null or doesn't match
    if (pet == null || pet.id != petId) {
      return Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(
          backgroundColor: cs.surface,
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

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
          pet.name,
          style: TextStyle(
            fontFamily: 'Sora',
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
                          image: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(pet.avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: pt.surface2,
                        ),
                        child: pet.avatarUrl == null || pet.avatarUrl!.isEmpty
                            ? Center(
                                child: Text(
                                  pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
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
                            ),
                            _buildStatItem(
                              'Followers',
                              statsAsync.maybeWhen(
                                data: (s) => s.followerCount.toString(),
                                orElse: () => '-',
                              ),
                            ),
                            _buildStatItem(
                              'Following',
                              statsAsync.maybeWhen(
                                data: (s) => s.followingCount.toString(),
                                orElse: () => '-',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bio
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (pet.breed != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        pet.breed!,
                        style: TextStyle(color: pt.ink500, fontSize: 14),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    pet.bio != null && pet.bio!.isNotEmpty
                        ? pet.bio!
                        : 'Living my best ${pet.speciesEnum.name} life. 🐾',
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
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
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                              final text = "Check out ${pet.name}'s profile on Petfolio! 🐾\n"
                                  "https://petfolio.app/social/profile/${pet.id}";
                              Share.share(text);
                            },
                            child: const Text(
                              'Share Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      if (post.imageUrls.isNotEmpty) {
                        return CachedNetworkImage(
                          imageUrl: post.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: pt.surface2),
                          errorWidget: (context, url, error) => Container(
                            color: pt.surface2,
                            child: Icon(Icons.error_outline, color: pt.ink300),
                          ),
                        );
                      } else {
                        // Text post placeholder
                        return Container(
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Sora',
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
