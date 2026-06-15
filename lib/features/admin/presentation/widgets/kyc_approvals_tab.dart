import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../../marketplace/data/models/shop.dart';
import '../controllers/kyc_review_controller.dart';
import 'admin_shared_widgets.dart';
import 'secure_doc_button.dart';

class KycApprovalsTab extends ConsumerWidget {
  const KycApprovalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycAsync = ref.watch(kycReviewProvider);
    final isWide = MediaQuery.sizeOf(context).width > 800;

    return AdminPanelScaffold(
      title: 'KYC Approvals',
      onRefresh: () => ref.read(kycReviewProvider.notifier).refresh(),
      child: kycAsync.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => AdminErrorState(message: e.toString()),
        data: (shops) {
          if (shops.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.verified_user_rounded,
              message: 'All caught up — no pending KYC submissions',
            );
          }
          if (isWide) {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 420,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: shops.length,
              itemBuilder: (context, i) => KycRequestCard(shop: shops[i]),
            );
          }
          return ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                bottom: i < shops.length - 1 ? 16 : 0,
              ),
              child: KycRequestCard(shop: shops[i]),
            ),
          );
        },
      ),
    );
  }
}

class KycRequestCard extends ConsumerStatefulWidget {
  const KycRequestCard({super.key, required this.shop});

  final Shop shop;

  @override
  ConsumerState<KycRequestCard> createState() => _KycRequestCardState();
}

class _KycRequestCardState extends ConsumerState<KycRequestCard> {
  bool _busy = false;

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(kycReviewProvider.notifier).approve(widget.shop.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final reason = await _showRejectDialog(context);
    if (reason == null || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(kycReviewProvider.notifier)
          .reject(widget.shop.id, reason.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _showRejectDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusXl),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.error.withAlpha(15),
              ),
              child: Icon(Icons.cancel_outlined, size: 18, color: cs.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Reject KYC',
              style: tt.headlineSmall!.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provide a reason for rejecting ${widget.shop.shopName}. '
              'The vendor will see this message.',
              style: tt.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. NID image is blurry or expired…',
                filled: true,
                fillColor: AppColors.surface1,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusMd),
                  borderSide:
                      const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusMd),
                  borderSide:
                      BorderSide(color: cs.error, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusMd,
                        ),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusMd,
                        ),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final bank = shop.bankAccountDetails;
    final hasNid = shop.nationalIdUrl != null;
    final hasLicense = shop.tradeLicenseUrl != null;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusXl),
        color: cs.surface,
        boxShadow: pt.shadowE1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ShopAvatar(logoUrl: shop.logoUrl, name: shop.shopName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.headlineSmall!.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const AdminStatusChip(
                        label: 'Submitted',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.line),

          // ── Bank details ─────────────────────────────────────────────────
          if (bank != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _BankDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Account Holder',
                    value: bank['account_holder']?.toString(),
                  ),
                  _BankDetailRow(
                    icon: Icons.account_balance_rounded,
                    label: 'Bank',
                    value: bank['bank_name']?.toString(),
                  ),
                  _BankDetailRow(
                    icon: Icons.tag_rounded,
                    label: 'Account No.',
                    value: bank['account_number']?.toString(),
                  ),
                  _BankDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Branch',
                    value: bank['branch']?.toString(),
                  ),
                ],
              ),
            ),

          // ── Documents ─────────────────────────────────────────────────────
          if (hasNid || hasLicense)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOCUMENTS',
                    style: tt.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hasNid)
                        SecureDocButton(
                          label: 'National ID',
                          documentPath: shop.nationalIdUrl!,
                        ),
                      if (hasLicense)
                        SecureDocButton(
                          label: 'Trade License',
                          documentPath: shop.tradeLicenseUrl!,
                        ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.line),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _reject,
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(
                        color: _busy ? AppColors.line : cs.error,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusMd,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _approve,
                    icon: _busy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.success.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusMd,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shop avatar ────────────────────────────────────────────────────────────────

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        color: AppColors.blue500.withAlpha(15),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _fallback,
            )
          : _fallback,
    );
  }

  Widget get _fallback => const Center(
        child: Icon(Icons.storefront_outlined,
            size: 22, color: AppColors.blue500),
      );
}

// ── Bank detail row ────────────────────────────────────────────────────────────

class _BankDetailRow extends StatelessWidget {
  const _BankDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.ink500),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(label, style: tt.labelMedium),
          ),
          Expanded(
            child: Text(
              value!,
              style: tt.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
