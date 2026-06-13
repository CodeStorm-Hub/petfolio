import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/vet_clinic.dart';
import '../controllers/appointment_controller.dart';
import '../controllers/clinic_list_provider.dart';
import 'appointments_screen.dart' show AppointmentCardWidget;

// ─────────────────────────────────────────────────────────────────────────────
// VetHubScreen — 4-tab hub entry point for the Vet feature.
// Routes: /appointments → this screen (replaces VetClinicsScreen).
// ─────────────────────────────────────────────────────────────────────────────

class VetHubScreen extends StatefulWidget {
  const VetHubScreen({super.key});

  @override
  State<VetHubScreen> createState() => _VetHubScreenState();
}

class _VetHubScreenState extends State<VetHubScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: pt.surface1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: pt.ink950),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PETFOLIO · VET',
              style: TextStyle(fontSize: 10, color: pt.ink500, letterSpacing: 1),
            ),
            Text(
              'Vet Hub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: pt.ink950,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                _ClinicsGridTab(),
                _AppointmentsHistoryTab(),
                _PlaceholderTab(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites Coming Soon',
                  subtitle: 'Save your favourite vets and clinics here.',
                ),
                _PlaceholderTab(
                  icon: Icons.person_rounded,
                  title: 'Vet Profile Coming Soon',
                  subtitle: 'Your vet history and profile will appear here.',
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12 + MediaQuery.paddingOf(context).bottom,
            child: _VetFloatingNav(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Clinics Grid
// ─────────────────────────────────────────────────────────────────────────────

class _ClinicsGridTab extends ConsumerWidget {
  const _ClinicsGridTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(clinicListProvider);

    return clinicsAsync.when(
      loading: () => const _SkeletonGrid(),
      error: (e, _) => PetfolioEmptyState(
        icon: Icons.local_hospital_outlined,
        title: 'Could not load clinics',
        subtitle: 'Check your connection and try again.',
        action: TextButton(
          onPressed: () => ref.invalidate(clinicListProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (clinics) => clinics.isEmpty
          ? const PetfolioEmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'No clinics available',
              subtitle: 'Check back soon.',
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _ClinicGridCard(
                        clinic: clinics[i],
                        onTap: () => context.push(
                          '/appointments/${clinics[i].id}',
                          extra: clinics[i],
                        ),
                      ),
                      childCount: clinics.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : ResponsiveLayout.isTablet(context) ? 3 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96 + MediaQuery.paddingOf(context).bottom,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clinic Grid Card — icon + name + specialty + city + rating
// ─────────────────────────────────────────────────────────────────────────────

class _ClinicGridCard extends StatefulWidget {
  const _ClinicGridCard({required this.clinic, required this.onTap});

  final VetClinic clinic;
  final VoidCallback onTap;

  @override
  State<_ClinicGridCard> createState() => _ClinicGridCardState();
}

class _ClinicGridCardState extends State<_ClinicGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? pt.surface2 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pt.line),
            boxShadow: pt.shadowE2,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hospital icon ─────────────────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.sky.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('🏥', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 10),

              // ── Clinic name ───────────────────────────────────────────────
              Text(
                widget.clinic.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: pt.ink950,
                  height: 1.3,
                ),
              ),

              // ── Tagline / specialty ───────────────────────────────────────
              if (widget.clinic.tagline != null) ...[
                const SizedBox(height: 3),
                Text(
                  widget.clinic.tagline!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: pt.ink500),
                ),
              ],

              const Spacer(),

              // ── City ──────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 11, color: pt.ink300),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      widget.clinic.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: pt.ink500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Rating row ────────────────────────────────────────────────
              Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    widget.clinic.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: pt.ink950,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '(${widget.clinic.reviewCount})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: pt.ink300),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.sky),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Grid — loading state for Tab 1
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const SkeletonLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 20,
              ),
              childCount: 6,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveLayout.isDesktop(context) ? 4 : ResponsiveLayout.isTablet(context) ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: 96 + MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Appointments History
// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentsHistoryTab extends StatelessWidget {
  const _AppointmentsHistoryTab();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.sky,
            unselectedLabelColor: pt.ink500,
            indicatorColor: AppColors.sky,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _AppointmentsList(past: false),
                _AppointmentsList(past: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appointments List — reads upcoming / past providers; reuses AppointmentCardWidget
// ─────────────────────────────────────────────────────────────────────────────

class _AppointmentsList extends ConsumerWidget {
  const _AppointmentsList({required this.past});

  final bool past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final bottomClearance = 96.0 + MediaQuery.paddingOf(context).bottom;
    final appointmentsAsync =
        ref.watch(past ? pastAppointmentsProvider : upcomingAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        if (past) {
          await ref.read(pastAppointmentsProvider.notifier).refresh();
        } else {
          await ref.read(upcomingAppointmentsProvider.notifier).refresh();
        }
      },
      child: appointmentsAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomClearance),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const SkeletonLoader(
            width: double.infinity,
            height: 80,
            borderRadius: 16,
          ),
        ),
        error: (err, _) => Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Could not load: $err',
                  style: TextStyle(color: pt.ink500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
                PetfolioEmptyState(
                  icon: Icons.event_available_rounded,
                  title: past ? 'No past appointments' : 'No upcoming appointments',
                  subtitle: past
                      ? 'Your completed or cancelled visits will appear here.'
                      : 'Book a vet from the Clinics tab.',
                ),
              ],
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomClearance),
            itemCount: appointments.length,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                AppointmentCardWidget(appointment: appointments[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder Tab — used for Tabs 3 (Favorites) and 4 (Profile)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PetfolioEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vet Nav Destination — lightweight data class for the floating nav
// ─────────────────────────────────────────────────────────────────────────────

class _VetNavDest {
  const _VetNavDest({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color accent;
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Pill Nav — mirrors AppShell's _FloatingNav exactly
// ─────────────────────────────────────────────────────────────────────────────

class _VetFloatingNav extends StatelessWidget {
  const _VetFloatingNav({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _dests = [
    _VetNavDest(
      icon: Icons.local_hospital_outlined,
      activeIcon: Icons.local_hospital_rounded,
      label: 'Clinics',
      accent: AppColors.sky,
    ),
    _VetNavDest(
      icon: Icons.history,
      activeIcon: Icons.history,
      label: 'History',
      accent: AppColors.mint,
    ),
    _VetNavDest(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Favorites',
      accent: AppColors.poppy,
    ),
    _VetNavDest(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      accent: AppColors.lilac,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface0D : AppColors.surface0;
    final border = isDark ? AppColors.lineD : AppColors.line;
    final shadowColor = isDark ? AppColors.shadowE3D : AppColors.shadowE3L;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < _dests.length; i++)
            Expanded(
              child: _VetNavTab(
                dest: _dests[i],
                isSelected: i == selectedIndex,
                isDark: isDark,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vet Nav Tab — spring animation identical to AppShell's _NavTab
// ─────────────────────────────────────────────────────────────────────────────

class _VetNavTab extends StatefulWidget {
  const _VetNavTab({
    required this.dest,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _VetNavDest dest;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_VetNavTab> createState() => _VetNavTabState();
}

class _VetNavTabState extends State<_VetNavTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _spring = SpringDescription(
    mass: 1.0,
    stiffness: 550,
    damping: 32,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_VetNavTab old) {
    super.didUpdateWidget(old);
    if (widget.isSelected == old.isSelected) return;
    if (widget.isSelected) {
      _ctrl.animateWith(SpringSimulation(_spring, _ctrl.value, 1.0, 0.0));
    } else {
      _ctrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselected = widget.isDark ? AppColors.ink500D : AppColors.ink500;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value.clamp(0.0, 1.3);
          final tC = t.clamp(0.0, 1.0);

          final iconColor = Color.lerp(unselected, widget.dest.accent, tC)!;
          final bgAlpha = (36 * tC).round();
          final hPad = 8.0 + 6.0 * t;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + 0.08 * t,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.dest.accent.withAlpha(bgAlpha),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    tC > 0.5 ? widget.dest.activeIcon : widget.dest.icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.dest.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: tC > 0.5 ? FontWeight.w700 : FontWeight.w500,
                  color: iconColor,
                  height: 1.0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
