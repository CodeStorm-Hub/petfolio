import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/verification.dart';
import '../controllers/verification_controller.dart';

class VerificationCenterScreen extends ConsumerWidget {
  const VerificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(verificationControllerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(title: const Text('Verification center')),
      body: async.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (_, _) => const Center(
          child: PetfolioEmptyState(
            icon: Icons.error_outline,
            title: 'Could not load verifications',
          ),
        ),
        data: (items) {
          final byType = {for (final v in items) v.type: v};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text(
                'Verified badges build trust with other owners and breeders.',
                style: tt.bodyMedium?.copyWith(color: pt.ink500),
              ),
              const SizedBox(height: 16),
              for (final type in VerificationType.values)
                _VerificationTile(
                  type: type,
                  existing: byType[type],
                  onRequest: () => ref
                      .read(verificationControllerProvider.notifier)
                      .request(type)
                      .then((_) =>
                          AppSnackBar.showSuccess('Verification requested'))
                      .catchError(
                          (Object e) => AppSnackBar.showError(e)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.type,
    required this.existing,
    required this.onRequest,
  });

  final VerificationType type;
  final Verification? existing;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final status = existing?.status;

    final Color color;
    final IconData icon;
    switch (status) {
      case VerificationStatus.approved:
        color = pt.success;
        icon = Icons.verified;
      case VerificationStatus.rejected:
        color = pt.warning;
        icon = Icons.cancel_outlined;
      case VerificationStatus.pending:
        color = pt.ink500;
        icon = Icons.hourglass_top_outlined;
      case null:
        color = pt.ink300;
        icon = Icons.shield_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(type.label),
        subtitle: Text(
          status?.label ?? 'Not requested',
          style: tt.bodySmall?.copyWith(color: pt.ink500),
        ),
        trailing: (status == null || status == VerificationStatus.rejected)
            ? TextButton(onPressed: onRequest, child: const Text('Request'))
            : null,
      ),
    );
  }
}
