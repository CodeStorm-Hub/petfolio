import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../controllers/profile_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final bg = isDark ? pt.surface1 : pt.surface2;

    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final profileAsync = ref.watch(profileControllerProvider);
          Widget scrollView = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).top + 76.0 + 16),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: profileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  final email = ref.watch(currentUserProvider)?.email ?? '';
                  final displayName = profile.displayName ?? 'No Name';
                  final initials = _getInitials(displayName);
                  final avatarUrl = profile.avatarUrl;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? pt.surface2 : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.poppy.withAlpha(25),
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.poppy,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: pt.ink950,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: pt.ink500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading profile: $e',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ),
          _sectionHeader(context, 'MY PETS'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.pets_rounded,
              iconColor: pt.pillarPets,
              label: 'Switch Active Pet',
              onTap: () => PetSwitcherSheet.show(context),
            ),
            _AccountTile(
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppColors.mint,
              label: 'Add a New Pet',
              onTap: () => context.push('/onboarding?mode=add'),
            ),
          ]),

          _sectionHeader(context, 'ACCOUNT'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.location_on_outlined,
              label: 'Saved Addresses',
              onTap: () => context.push('/settings/addresses'),
            ),
            _AccountTile(
              icon: Icons.receipt_long_outlined,
              label: 'My Orders & Activity',
              onTap: () => context.push('/home/activity'),
            ),
          ]),

          _sectionHeader(context, 'STORE'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.favorite_border_rounded,
              label: 'Wishlist',
              onTap: () => context.push('/marketplace/wishlist'),
            ),
          ]),

          _sectionHeader(context, 'SOCIAL'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved Posts',
              onTap: () => context.push('/social/saved'),
            ),
          ]),

          _sectionHeader(context, 'APPEARANCE'),
          _group(isDark, pt, [
            _ThemeToggleRow(isDark: isDark, ref: ref),
          ]),

          _sectionHeader(context, 'OFFERS'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.local_offer_outlined,
              label: 'Promos & Deals',
              onTap: () => context.push('/offers'),
            ),
            _AccountTile(
              icon: Icons.card_giftcard_rounded,
              label: 'Refer & Get Discounts',
              trailing: _NewBadge(),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Referrals coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
            ),
          ]),

          _sectionHeader(context, 'HELP & LEGAL'),
          _group(isDark, pt, [
            _AccountTile(icon: Icons.help_outline_rounded, label: 'Help', onTap: () {}),
            _AccountTile(icon: Icons.description_outlined, label: 'Policies', onTap: () {}),
          ]),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _AccountTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  labelColor: AppColors.danger,
                  onTap: () async =>
                      ref.read(authRepositoryProvider).signOut(),
                ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: bottomPad + 100)),
        ],
          );
          if (isWide) {
            scrollView = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: scrollView,
              ),
            );
          }
          return scrollView;
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) =>
      SliverToBoxAdapter(child: SectionHeader(label: label));

  Widget _group(bool isDark, PetfolioThemeExtension pt, List<Widget> items) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? pt.surface2 : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 56, color: pt.line),
                ],
              ],
            ),
          ),
        ),
      );
}

// ── Account tile ──────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.trailing,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: iconColor ?? labelColor ?? pt.ink500),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: labelColor ?? pt.ink950,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 24,
      minTileHeight: 56,
    );
  }
}

// ── Theme toggle row ──────────────────────────────────────────────────────────

class _ThemeToggleRow extends StatelessWidget {
  const _ThemeToggleRow({required this.isDark, required this.ref});

  final bool isDark;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return ListTile(
      leading: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 22, color: pt.ink500,
      ),
      title: Text(
        isDark ? 'Light Mode' : 'Dark Mode',
        style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: pt.ink950,
        ),
      ),
      trailing: Semantics(
        label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        excludeSemantics: true,
        child: Switch(
          value: isDark,
          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
        ),
      ),
      onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 24,
      minTileHeight: 56,
    );
  }
}

// ── New badge ─────────────────────────────────────────────────────────────────

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.poppy,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'NEW',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    );
  }
}

String _getInitials(String displayName) {
  final cleanName = displayName.trim();
  if (cleanName.isEmpty) return '?';
  final parts = cleanName.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
  final first = parts[0].isNotEmpty ? parts[0][0] : '';
  final last = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
  final result = '$first$last';
  return result.isNotEmpty ? result.toUpperCase() : '?';
}
