import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      body: IndexedStack(
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = i);
        },
        backgroundColor: isDark ? pt.surface2 : Colors.white,
        indicatorColor: AppColors.sky.withAlpha(isDark ? 45 : 28),
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital_rounded, color: AppColors.sky),
            label: 'Clinics',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: AppColors.sky),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppColors.sky),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.sky),
            label: 'Profile',
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clinic Grid Card — image + name + specialty + city + rating
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const SkeletonLoader(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 20,
              ),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
          ),
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
          padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
