import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final User? user = Supabase.instance.client.auth.currentUser;
    final bg = isDark ? pt.surface1 : AppColors.surface3;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: pt.ink950,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Account & Settings',
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ProfileCard(user: user, pt: pt, isDark: isDark),
              ),
            ),

            SliverToBoxAdapter(
              child: _SettingsGroup(
                label: 'ACCOUNT',
                isDark: isDark,
                pt: pt,
                items: [
                  _SettingsTile(
                    icon: Icons.location_on_outlined,
                    label: 'Saved Addresses',
                    onTap: () => context.push('/settings/addresses'),
                  ),
                  _SettingsTile(
                    icon: Icons.shopping_bag_outlined,
                    label: 'My Orders',
                    onTap: () => context.go('/home/activity'),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: _SettingsGroup(
                label: 'OFFERS',
                isDark: isDark,
                pt: pt,
                items: [
                  _SettingsTile(
                    icon: Icons.local_offer_outlined,
                    label: 'Promos',
                    onTap: () => context.push('/offers'),
                  ),
                  _SettingsTile(
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
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: _SettingsGroup(
                label: 'SETTINGS',
                isDark: isDark,
                pt: pt,
                items: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/social/notifications'),
                  ),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    label: 'Appearance',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme settings coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: _SettingsGroup(
                label: 'HELP & LEGAL',
                isDark: isDark,
                pt: pt,
                items: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    label: 'Policies',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: _SettingsGroup(
                label: 'MORE',
                isDark: isDark,
                pt: pt,
                items: [
                  _SettingsTile(
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

            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.pt,
    required this.isDark,
  });

  final User? user;
  final PetfolioThemeExtension pt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? pt.surface2 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
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
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.isNotEmpty ? email : 'Petfolio User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: pt.ink950,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.premiumGold, AppColors.premiumGoldSoft],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '⭐ Gold Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: pt.ink500),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.label,
    required this.items,
    required this.isDark,
    required this.pt,
  });

  final String label;
  final List<_SettingsTile> items;
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.8,
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
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: pt.line,
                      ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: labelColor ?? pt.ink500),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: labelColor ?? pt.ink950,
        ),
      ),
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 24,
    );
  }
}

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
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    );
  }
}
