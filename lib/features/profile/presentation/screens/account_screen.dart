import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/widgets/pet_avatar.dart';
import '../../../../core/widgets/wave_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final user = Supabase.instance.client.auth.currentUser;
    final activePet = ref.watch(activePetControllerProvider);
    final bg = isDark ? pt.surface1 : const Color(0xFFF2F3F7);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WaveHeader(
              size: WaveHeaderSize.compact,
              color: pt.pillarPets,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: _ProfileHeroCard(
                    user: user,
                    activePet: activePet,
                    pt: pt,
                    isDark: isDark,
                    onTap: () => PetSwitcherSheet.show(context),
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
              onTap: () => context.go('/activity'),
            ),
          ]),

          _sectionHeader(context, 'STORE'),
          _group(isDark, pt, [
            _AccountTile(
              icon: Icons.storefront_outlined,
              label: 'My Shop',
              onTap: () => context.go('/seller'),
            ),
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
              child: Semantics(
                label: 'Sign out',
                button: true,
                child: _AccountTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  labelColor: AppColors.danger,
                  onTap: () async =>
                      ref.read(authRepositoryProvider).signOut(),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: bottomPad + 100)),
        ],
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

// ── Profile hero card ─────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.activePet,
    required this.pt,
    required this.isDark,
    required this.onTap,
  });

  final dynamic user;
  final dynamic activePet;
  final PetfolioThemeExtension pt;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final email = user?.email as String? ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Semantics(
      label: 'Profile card, tap to switch pet',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              if (activePet != null)
                PetAvatar(
                  imageUrl: activePet!.avatarUrl as String?,
                  species: activePet!.speciesEnum,
                  size: PetAvatarSize.lg,
                  showRing: true,
                  semanticLabel: activePet!.name as String,
                  heroTag: 'pet-avatar-${activePet!.id}',
                )
              else
                Container(
                  width: 48, height: 48,
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
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePet?.name as String? ?? (email.isNotEmpty ? email : 'Petfolio User'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: pt.ink950,
                      ),
                    ),
                    const SizedBox(height: 2),
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
      ),
    );
  }
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
    return Semantics(
      label: label,
      button: true,
      child: ListTile(
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
      ),
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
    return Semantics(
      label: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      button: true,
      child: ListTile(
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
        trailing: Switch(
          value: isDark,
          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minLeadingWidth: 24,
        minTileHeight: 56,
      ),
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
