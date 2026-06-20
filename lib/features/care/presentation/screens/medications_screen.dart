import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/medications_controller.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final pet = ref.watch(activePetControllerProvider);

    if (pet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(title: const Text('Medications')),
        body: const Center(
          child: PetfolioEmptyState(
            icon: Icons.medication_outlined,
            title: 'No active pet',
          ),
        ),
      );
    }

    final async = ref.watch(medicationsControllerProvider(pet.id));

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(title: Text('${pet.name}’s medications')),
      body: async.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (_, _) => const Center(
          child: PetfolioEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load medications',
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: PetfolioEmptyState(
                icon: Icons.medication_outlined,
                title: 'No active medications',
                subtitle:
                    'Add medications in the Medical Vault to track daily doses here.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _MedicationCard(
              adherence: items[i],
              onGiven: () => ref
                  .read(medicationsControllerProvider(pet.id).notifier)
                  .logDose(items[i].record.id)
                  .then((_) => AppSnackBar.showSuccess('Dose logged'))
                  .catchError((Object e) => AppSnackBar.showError(e)),
            ),
          );
        },
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.adherence, required this.onGiven});

  final MedicationAdherence adherence;
  final VoidCallback onGiven;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final r = adherence.record;
    final subtitleParts = [
      if (r.dosage != null && r.dosage!.isNotEmpty) r.dosage!,
      if (r.frequency != null && r.frequency!.isNotEmpty) r.frequency!,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pt.surface2,
        borderRadius: BorderRadius.circular(20),
        boxShadow: pt.shadowE1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication_liquid_outlined, color: pt.pillarHealth),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.name,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (adherence.dosesToday > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pt.success.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${adherence.dosesToday}× today',
                    style: tt.labelSmall?.copyWith(color: pt.success),
                  ),
                ),
            ],
          ),
          if (subtitleParts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitleParts.join(' · '),
                style: tt.bodySmall?.copyWith(color: pt.ink500)),
          ],
          if (adherence.lastGivenAt != null) ...[
            const SizedBox(height: 4),
            Text('Last given ${_time(adherence.lastGivenAt!)}',
                style: tt.bodySmall?.copyWith(color: pt.ink300)),
          ],
          const SizedBox(height: 12),
          PrimaryPillButton(
            label: 'Mark dose given',
            isFullWidth: true,
            leadingIcon: const Icon(Icons.check_rounded, size: 18),
            onPressed: onGiven,
          ),
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final ampm = l.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}
