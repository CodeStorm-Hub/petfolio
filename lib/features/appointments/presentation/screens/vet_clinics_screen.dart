import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/vet_clinic.dart';
import '../controllers/clinic_list_provider.dart';

class VetClinicsScreen extends ConsumerWidget {
  const VetClinicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final clinicsAsync = ref.watch(clinicListProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: pt.surface1,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: pt.ink950),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VETS', style: TextStyle(fontSize: 10, color: pt.ink500, letterSpacing: 1)),
            Text(
              'Find a Vet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: pt.ink950),
            ),
          ],
        ),
      ),
      body: clinicsAsync.when(
        loading: () => const _SkeletonList(),
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
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: clinics.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _ClinicCard(
                  clinic: clinics[i],
                  onTap: () => context.push(
                    '/appointments/${clinics[i].id}',
                    extra: clinics[i],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Clinic card ──────────────────────────────────────────────────────────────

class _ClinicCard extends StatefulWidget {
  const _ClinicCard({required this.clinic, required this.onTap});
  final VetClinic clinic;
  final VoidCallback onTap;

  @override
  State<_ClinicCard> createState() => _ClinicCardState();
}

class _ClinicCardState extends State<_ClinicCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: widget.clinic.name,
      hint: 'View clinic details',
      button: true,
      child: GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? pt.surface2 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pt.line),
            boxShadow: pt.shadowE2,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: widget.clinic.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.clinic.avatarUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _ClinicAvatarPlaceholder(size: 52),
                        errorWidget: (_, _, _) => _ClinicAvatarPlaceholder(size: 52),
                      )
                    : _ClinicAvatarPlaceholder(size: 52),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.clinic.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: pt.ink950,
                        height: 1.2,
                      ),
                    ),
                    if (widget.clinic.tagline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.clinic.tagline!,
                        style: TextStyle(fontSize: 12, color: pt.ink500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: pt.ink300),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${widget.clinic.address}, ${widget.clinic.city}',
                            style: TextStyle(fontSize: 11, color: pt.ink500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        widget.clinic.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pt.ink950,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.clinic.reviewCount} reviews',
                    style: TextStyle(fontSize: 10, color: pt.ink300),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ─── Clinic avatar placeholder ────────────────────────────────────────────────

class _ClinicAvatarPlaceholder extends StatelessWidget {
  const _ClinicAvatarPlaceholder({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.sky.withAlpha(30),
      alignment: Alignment.center,
      child: Text('🏥', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

// ─── Skeleton list ────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const SkeletonLoader(
        width: double.infinity,
        height: 88,
        borderRadius: 20,
      ),
    );
  }
}
