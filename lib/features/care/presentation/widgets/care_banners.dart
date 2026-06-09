import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';

class CareExploreRow extends StatelessWidget {
  const CareExploreRow({super.key, required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ExploreTile(
            icon: Icons.map_rounded,
            iconBg: AppColors.skySoft,
            iconColor: AppColors.sky700,
            title: 'Walk Tracker',
            subtitle: 'Live GPS route map',
            onTap: () => context.go('/care/walk'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ExploreTile(
            icon: Icons.groups_rounded,
            iconBg: AppColors.poppySoft,
            iconColor: AppColors.poppy700,
            title: 'Communities',
            subtitle: 'Pet parent groups',
            onTap: () => context.go('/social/communities'),
          ),
        ),
      ],
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pt.line),
              boxShadow: pt.shadowE1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: pt.ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: pt.ink500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CareUtilityBanner extends StatelessWidget {
  const CareUtilityBanner({super.key, required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pt.line),
        boxShadow: pt.shadowE1,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UtilityHalf(
              key: const ValueKey<String>('care_nutrition_banner'),
              icon: Icons.monitor_weight_outlined,
              iconBg: AppColors.sunnySoft,
              iconColor: AppColors.sunny700,
              title: 'Nutrition',
              subtitle: 'Weight & caloric needs',
              detail: 'Track daily feeding',
              onTap: () => context.go('/care/nutrition'),
            ),
            VerticalDivider(width: 1, thickness: 1, color: pt.line),
            _UtilityHalf(
              key: const ValueKey<String>('care_medical_vault_banner'),
              icon: Icons.folder_special_outlined,
              iconBg: AppColors.mintSoft,
              iconColor: AppColors.mint700,
              title: 'Medical Vault',
              subtitle: 'Vaccines · Meds · Vet',
              detail: 'View health records',
              onTap: () => context.go('/care/health'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityHalf extends StatelessWidget {
  const _UtilityHalf({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 15, color: pt.ink300),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: pt.ink950,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: pt.ink500,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CareAppointmentsBanner extends StatelessWidget {
  const CareAppointmentsBanner({super.key, required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.go('/care/appointments'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: pt.line),
          boxShadow: pt.shadowE1,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lilacSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_rounded, color: AppColors.lilac700, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointments',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: pt.ink950),
                  ),
                  Text(
                    'Schedule & track vet visits',
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300),
          ],
        ),
      ),
    );
  }
}
