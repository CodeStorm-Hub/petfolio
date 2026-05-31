import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/theme.dart';
import '../../../care/data/models/pet_awards_summary.dart';
import '../../../care/presentation/controllers/pet_awards_provider.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/follow_controller.dart';
import '../controllers/social_profile_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SocialProfileScreen extends ConsumerWidget {
  const SocialProfileScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final petAsync = ref.watch(petByIdProvider(petId));
    final postsAsync = ref.watch(socialProfilePostsProvider(petId));
    final statsAsync = ref.watch(petStatsProvider(petId));
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final isOwnProfile = activePet?.id == petId;

    return petAsync.when(
      loading: () => Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(backgroundColor: cs.surface, leading: BackButton(color: cs.onSurface)),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(backgroundColor: cs.surface, leading: BackButton(color: cs.onSurface)),
        body: Center(child: Text('Could not load profile', style: TextStyle(color: pt.ink500))),
      ),
      data: (pet) {
        final resolvedPet = pet ?? (isOwnProfile ? activePet : null);
        final petName = resolvedPet?.name ?? 'Pet Profile';
        final petBreed = resolvedPet?.breed;
        final petBio = resolvedPet?.bio?.isNotEmpty == true
            ? resolvedPet!.bio!
            : (resolvedPet != null
                ? 'Living my best ${resolvedPet.speciesEnum.name} life. 🐾'
                : '');
        final avatarUrl = resolvedPet?.avatarUrl;

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
              petName,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            centerTitle: true,
          ),
          body: CustomScrollView(
            slivers: [
              // ── Profile header card ───────────────────────────────────
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  petName: petName,
                  petBreed: petBreed,
                  petBio: petBio,
                  avatarUrl: avatarUrl,
                  postCount: statsAsync.maybeWhen(
                    data: (s) => s.postCount,
                    orElse: () => postsAsync.value?.length,
                  ),
                  followerCount: statsAsync.maybeWhen(data: (s) => s.followerCount, orElse: () => null),
                  followingCount: statsAsync.maybeWhen(data: (s) => s.followingCount, orElse: () => null),
                  isOwnProfile: isOwnProfile,
                  resolvedPet: resolvedPet,
                  petId: petId,
                  pt: pt,
                ),
              ),

              // ── Care & achievements ───────────────────────────────────
              SliverToBoxAdapter(
                child: awardsAsync.when(
                  loading: () => const _AwardsSkeleton(),
                  error: (e, st) {
                    debugPrint('Awards load failure: $e\n$st');
                    return Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
                        border: Border.all(color: pt.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.poppy, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Failed to load achievements',
                            style: TextStyle(fontSize: 12, color: pt.ink500),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(petAwardsSummaryProvider(petId)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  data: (awards) {
                    if (awards.logsCount == 0 && awards.unlockedBadges.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _AwardsSection(awards: awards, pt: pt);
                  },
                ),
              ),

              // ── Posts grid separator ──────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: cs.surface,
                  child: Divider(height: 1, thickness: 0.5, color: pt.line),
                ),
              ),

              // ── Posts grid ────────────────────────────────────────────
              postsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                error: (e, st) => SliverFillRemaining(
                  child: Center(child: Text('Failed to load posts', style: TextStyle(color: pt.ink500))),
                ),
                data: (posts) {
                  if (posts.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 52, color: pt.ink300),
                            const SizedBox(height: 12),
                            Text('No Posts Yet', style: tt.titleSmall?.copyWith(color: pt.ink500)),
                            const SizedBox(height: 4),
                            Text('Photos will appear here', style: tt.bodySmall?.copyWith(color: pt.ink300)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 1),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 1.5,
                        crossAxisSpacing: 1.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          Widget child;
                          if (post.imageUrls.isNotEmpty) {
                            child = Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: post.imageUrls.first,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  maxWidthDiskCache: 800,
                                  placeholder: (ctx, url) => Container(color: pt.surface2),
                                  errorWidget: (ctx, url, err) => Container(
                                    color: pt.surface2,
                                    child: Icon(Icons.error_outline, color: pt.ink300),
                                  ),
                                ),
                                if (post.imageUrls.length > 1)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Icon(Icons.collections_rounded, size: 14, color: Colors.white.withAlpha(220)),
                                  ),
                              ],
                            );
                          } else {
                            child = Container(
                              color: post.accentColor.withAlpha(40),
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: Text(
                                  post.caption,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: post.accentColor),
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () => context.push('/social/post/${post.id}', extra: post),
                            child: child,
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.petName,
    required this.petBio,
    required this.avatarUrl,
    required this.isOwnProfile,
    required this.petId,
    required this.pt,
    this.petBreed,
    this.postCount,
    this.followerCount,
    this.followingCount,
    this.resolvedPet,
  });

  final String petName;
  final String? petBreed;
  final String petBio;
  final String? avatarUrl;
  final int? postCount;
  final int? followerCount;
  final int? followingCount;
  final bool isOwnProfile;
  final Pet? resolvedPet;
  final String petId;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + stats row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(name: petName, avatarUrl: avatarUrl, pt: pt),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStatColumn(value: postCount?.toString() ?? '-', label: 'Posts'),
                    _ProfileStatColumn(value: followerCount?.toString() ?? '-', label: 'Followers'),
                    _ProfileStatColumn(value: followingCount?.toString() ?? '-', label: 'Following'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Name + breed + bio
          Text(petName, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
          if (petBreed != null) ...[
            const SizedBox(height: 2),
            Text(petBreed!, style: TextStyle(color: pt.ink500, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
          if (petBio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(petBio, style: TextStyle(color: cs.onSurface.withAlpha(200), fontSize: 13.5, height: 1.4)),
          ],

          const SizedBox(height: 14),

          // Action buttons
          if (isOwnProfile && resolvedPet != null)
            _OwnProfileButtons(pet: resolvedPet!, pt: pt, cs: cs)
          else
            _OtherProfileButtons(petId: petId, pt: pt, cs: cs),
        ],
      ),
    );
  }
}

// Circular avatar with subtle gradient ring when it has an image
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.avatarUrl, required this.pt});

  final String name;
  final String? avatarUrl;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF9800), Color(0xFF7B61FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasImage ? null : pt.surface2,
      ),
      padding: hasImage ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pt.surface2,
          image: hasImage
              ? DecorationImage(image: CachedNetworkImageProvider(avatarUrl!), fit: BoxFit.cover)
              : null,
          border: Border.all(color: cs.surface, width: hasImage ? 1.5 : 0),
        ),
        child: !hasImage
            ? Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: pt.ink500),
                ),
              )
            : null,
      ),
    );
  }
}

// Single stat column (number + label)
class _ProfileStatColumn extends StatelessWidget {
  const _ProfileStatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.1),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withAlpha(160)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Awards & achievements section
// ─────────────────────────────────────────────────────────────────────────────

class _AwardsSection extends StatelessWidget {
  const _AwardsSection({required this.awards, required this.pt});

  final PetAwardsSummary awards;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  'Care & Achievements',
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: pt.ink500,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Divider(height: 1, color: pt.line2)),
              ],
            ),
          ),

          // Stat cards row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _CareStatCard(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF6B35),
                    bgColor: const Color(0xFFFF6B35),
                    value: '${awards.currentStreak}',
                    label: 'Day streak',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CareStatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFFB300),
                    bgColor: const Color(0xFFFFB300),
                    value: '${awards.totalXp}',
                    label: 'XP earned',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CareStatCard(
                    icon: Icons.checklist_rounded,
                    iconColor: const Color(0xFF7B61FF),
                    bgColor: const Color(0xFF7B61FF),
                    value: '${awards.logsCount}',
                    label: 'Care logs',
                  ),
                ),
              ],
            ),
          ),

          // Badges strip (only if any earned)
          if (awards.unlockedBadges.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: awards.unlockedBadges.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < awards.unlockedBadges.length - 1 ? 14 : 0),
                    child: _BadgeHighlight(badgeType: awards.unlockedBadges[i].badgeType),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Individual care stat card — bold number, icon, subtle tinted bg
class _CareStatCard extends StatelessWidget {
  const _CareStatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(isDark ? 30 : 18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withAlpha(isDark ? 60 : 40), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }
}

// Instagram-style highlights badge — circle icon + label below
class _BadgeHighlight extends StatelessWidget {
  const _BadgeHighlight({required this.badgeType});
  final String badgeType;

  static const _catalog = <String, (String, IconData, Color)>{
    'first_log':      ('First Log',      Icons.flag_rounded,               Color(0xFF4CAF50)),
    '3_day_streak':   ('3-Day',          Icons.local_fire_department_rounded, Color(0xFFFF9800)),
    '7_day_hero':     ('7-Day Hero',     Icons.bolt_rounded,               Color(0xFFFFCC00)),
    'routine_master': ('Routine',        Icons.checklist_rounded,          Color(0xFF2196F3)),
    '30_day_legend':  ('Legend',         Icons.workspace_premium_rounded,  Color(0xFF9C27B0)),
    'care_champion':  ('Champion',       Icons.military_tech_rounded,      Color(0xFFE91E63)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _catalog[badgeType];
    final label = info?.$1 ?? badgeType;
    final icon = info?.$2 ?? Icons.emoji_events_rounded;
    final color = info?.$3 ?? const Color(0xFF7B61FF);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withAlpha(isDark ? 80 : 50), color.withAlpha(isDark ? 40 : 25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color.withAlpha(isDark ? 120 : 100), width: 1.5),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 56,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withAlpha(180),
            ),
          ),
        ),
      ],
    );
  }
}

// Loading skeleton for awards section
class _AwardsSkeleton extends StatelessWidget {
  const _AwardsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: pt.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Own-profile action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _OwnProfileButtons extends StatelessWidget {
  const _OwnProfileButtons({required this.pet, required this.pt, required this.cs});

  final Pet pet;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Edit Profile',
            filled: false,
            onPressed: () => context.push('/pet/${pet.id}/edit'),
            cs: cs,
            pt: pt,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Share Profile',
            filled: false,
            onPressed: () {
              final text = "Check out ${pet.name}'s profile on Petfolio! 🐾\nhttps://petfolio.app/social/profile/${pet.id}";
              SharePlus.instance.share(ShareParams(text: text));
            },
            cs: cs,
            pt: pt,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Other-pet profile action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _OtherProfileButtons extends ConsumerWidget {
  const _OtherProfileButtons({required this.petId, required this.pt, required this.cs});

  final String petId;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(followStatusProvider(petId));
    final isFollowing = followAsync.value ?? false;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: followAsync.isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isFollowing
                        ? _ActionButton(
                            key: const ValueKey('following'),
                            label: 'Following',
                            filled: false,
                            onPressed: () => ref.read(followStatusProvider(petId).notifier).toggle(),
                            cs: cs,
                            pt: pt,
                          )
                        : _ActionButton(
                            key: const ValueKey('follow'),
                            label: 'Follow',
                            filled: true,
                            onPressed: () => ref.read(followStatusProvider(petId).notifier).toggle(),
                            cs: cs,
                            pt: pt,
                          ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          width: 36,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: pt.line),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final text = "Check out this pet's profile on Petfolio! 🐾\nhttps://petfolio.app/social/profile/$petId";
              SharePlus.instance.share(ShareParams(text: text));
            },
            child: Icon(Icons.ios_share_rounded, size: 18, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}

// Shared button style
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onPressed,
    required this.cs,
    required this.pt,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;
  final ColorScheme cs;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: cs.onSurface,
            side: BorderSide(color: pt.line),
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          );

    return filled
        ? FilledButton(style: style, onPressed: onPressed, child: Text(label))
        : OutlinedButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

