import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../data/models/shop_deletion_request.dart';
import '../controllers/shop_deletion_controller.dart';
import 'admin_shared_widgets.dart';

class ShopsTab extends ConsumerWidget {
  const ShopsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(shopDeletionRequestsProvider);

    return AdminPanelScaffold(
      title: 'Shop Deletion Requests',
      onRefresh: () => ref.read(shopDeletionRequestsProvider.notifier).refresh(),
      child: async.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (requests) {
          if (requests.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.store_outlined,
              message: 'No pending deletion requests',
            );
          }
          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DeletionRequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _DeletionRequestCard extends ConsumerStatefulWidget {
  const _DeletionRequestCard({required this.request});

  final ShopDeletionRequest request;

  @override
  ConsumerState<_DeletionRequestCard> createState() => _DeletionRequestCardState();
}

class _DeletionRequestCardState extends ConsumerState<_DeletionRequestCard> {
  var _loading = false;

  Future<void> _resolve({required bool approve, String? rejectionNote}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(shopDeletionRequestsProvider.notifier).resolve(
            widget.request.id,
            approve: approve,
            rejectionNote: rejectionNote,
          );
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showApproveDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve shop deletion?'),
        content: Text(
          '"${widget.request.shopName}" will be deactivated and all its products unlisted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve deletion'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _resolve(approve: true);
  }

  Future<void> _showRejectDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reject deletion request'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection (required)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Confirm Reject'),
            ),
          ],
        ),
      ),
    );
    if (note != null && note.isNotEmpty) {
      await _resolve(approve: false, rejectionNote: note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = widget.request;

    final requestedDate = _formatDate(r.requestedAt);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        border: Border.all(color: pt.line, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_forever_rounded,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.shopName,
                  style: tt.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const AdminStatusChip(label: 'Pending', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Requested $requestedDate',
            style: tt.labelSmall!.copyWith(color: pt.ink500),
          ),
          if (r.reason != null && r.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pt.surface2,
                borderRadius:
                    BorderRadius.circular(PetfolioThemeExtension.radiusSm),
              ),
              child: Text(
                r.reason!.length > 200
                    ? '${r.reason!.substring(0, 200)}…'
                    : r.reason!,
                style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface,
                    height: 1.4),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Approving deactivates this shop and unlists all its products.',
            style: TextStyle(fontSize: 12, color: pt.ink500),
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
                    onPressed: _showRejectDialog,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: pt.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            PetfolioThemeExtension.radiusSm),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _showApproveDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            PetfolioThemeExtension.radiusSm),
                      ),
                    ),
                    child: const Text('Approve deletion'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
