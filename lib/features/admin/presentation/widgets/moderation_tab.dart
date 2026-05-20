import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/post_report.dart';
import '../controllers/moderation_controller.dart';
import 'admin_shared_widgets.dart';

class ModerationTab extends ConsumerWidget {
  const ModerationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(moderationProvider);

    return AdminPanelScaffold(
      title: 'Moderation',
      onRefresh: () => ref.read(moderationProvider.notifier).refresh(),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (reports) {
          if (reports.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.shield_outlined,
              message: 'No pending reports — feed is clean',
            );
          }
          return ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _ReportCard(report: reports[i]),
          );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard({required this.report});

  final PostReport report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  var _loading = false;

  Future<void> _resolve({required bool dismiss, required bool hidePost}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(moderationProvider.notifier).resolve(
            widget.report.id,
            dismiss: dismiss,
            hidePost: hidePost,
          );
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final r = widget.report;
    final reporterShort = r.reporterId.substring(0, 8).toUpperCase();
    final snippet = r.postContent?.trim();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        border: Border.all(color: pt.line200, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(
                'Reporter #$reporterShort',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: pt.ink500,
                    ),
              ),
              const Spacer(),
              AdminStatusChip(
                label: 'Pending',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (snippet != null && snippet.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pt.surface2,
                borderRadius:
                    BorderRadius.circular(PetfolioThemeExtension.radiusSm),
              ),
              child: Text(
                snippet.length > 200
                    ? '${snippet.substring(0, 200)}…'
                    : snippet,
                style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Reason',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: pt.ink500,
                  letterSpacing: 0.08 * 11,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            r.reason,
            style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resolve(dismiss: true, hidePost: false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: pt.line200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusSm,
                        ),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _resolve(dismiss: false, hidePost: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusSm,
                        ),
                      ),
                    ),
                    child: const Text('Hide post'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
