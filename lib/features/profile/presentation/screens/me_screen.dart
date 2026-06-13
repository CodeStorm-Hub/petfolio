import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final User? user = Supabase.instance.client.auth.currentUser;
    final activePet = ref.watch(activePetControllerProvider);
    final bg = isDark ? pt.surface1 : const Color(0xFFF2F3F7);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad + 76)),

          // ── Profile card ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _ProfileCard(
                user: user,
                activePet: activePet,
                pt: pt,
                isDark: isDark,
              ),
            ),
          ),

          // ── Pet section ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'MY PETS',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(
                  icon: Icons.pets_rounded,
                  iconColor: AppColors.tangerine,
                  label: 'Switch Active Pet',
                  onTap: () => PetSwitcherSheet.show(context),
                ),
                _MeTile(
                  icon: Icons.add_circle_outline_rounded,
                  iconColor: AppColors.mint,
                  label: 'Add a New Pet',
                  onTap: () => context.push('/onboarding?mode=add'),
                ),
              ],
            ),
          ),

          // ── Account ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'ACCOUNT',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Addresses',
                  onTap: () => context.push('/settings/addresses'),
                ),
                _MeTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Orders & Activity',
                  onTap: () => context.go('/activity'),
                ),
                _MeTile(
                  icon: Icons.storefront_outlined,
                  label: 'Seller Dashboard',
                  onTap: () => context.go('/seller'),
                ),
              ],
            ),
          ),

          // ── Preferences ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'PREFERENCES',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => context.go('/notifications'),
                ),
                _MeTile(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),

          // ── Offers ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'OFFERS',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(
                  icon: Icons.local_offer_outlined,
                  label: 'Promos & Deals',
                  onTap: () => context.push('/offers'),
                ),
                _MeTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Refer & Get Discounts',
                  trailing: _NewBadge(),
                  onTap: () => AppSnackBar.show('Referrals coming soon!'),
                ),
              ],
            ),
          ),

          // ── Help & Legal ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'HELP & LEGAL',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(icon: Icons.help_outline_rounded, label: 'Help', onTap: () {}),
                _MeTile(icon: Icons.description_outlined, label: 'Policies', onTap: () {}),
              ],
            ),
          ),

          // ── Sign out ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MeGroup(
              label: 'MORE',
              isDark: isDark,
              pt: pt,
              items: [
                _MeTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  labelColor: AppColors.danger,
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: bottomPad + 100)),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.activePet,
    required this.pt,
    required this.isDark,
  });

  final User? user;
  final dynamic activePet;
  final PetfolioThemeExtension pt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () => PetSwitcherSheet.show(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? pt.surface2 : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (activePet != null)
              PetAvatar(
                imageUrl: activePet!.avatarUrl,
                species: activePet!.speciesEnum,
                size: PetAvatarSize.md,
                showRing: true,
              )
            else
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.poppy, AppColors.tangerine],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activePet?.name ?? (email.isNotEmpty ? email : 'Petfolio User'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: pt.ink950,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFF5D56E)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '⭐ Gold Member',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink500),
          ],
        ),
      ),
    );
  }
}

// ── Group ─────────────────────────────────────────────────────────────────────

class _MeGroup extends StatelessWidget {
  const _MeGroup({
    required this.label,
    required this.items,
    required this.isDark,
    required this.pt,
  });

  final String label;
  final List<_MeTile> items;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: pt.ink500, letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? pt.surface2 : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final isLast = e.key == items.length - 1;
                return Column(
                  children: [
                    e.value,
                    if (!isLast) Divider(height: 1, indent: 56, color: pt.line),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _MeTile extends StatelessWidget {
  const _MeTile({
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
              fontSize: 10, fontWeight: FontWeight.w900,
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
