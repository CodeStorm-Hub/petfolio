import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/my_shop_controller.dart';

class StripeOnboardingDialog extends ConsumerStatefulWidget {
  const StripeOnboardingDialog({super.key, required this.accountLinkUrl});

  final String accountLinkUrl;

  static Future<void> show(BuildContext context, String accountLinkUrl) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StripeOnboardingDialog(accountLinkUrl: accountLinkUrl),
    );
  }

  @override
  ConsumerState<StripeOnboardingDialog> createState() => _StripeOnboardingDialogState();
}

class _StripeOnboardingDialogState extends ConsumerState<StripeOnboardingDialog>
    with WidgetsBindingObserver {
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(myShopProvider.notifier).refreshAfterOnboarding();
    }
  }

  Future<void> _openBrowser() async {
    if (_launching) return;
    final uri = Uri.tryParse(widget.accountLinkUrl);
    if (uri == null) return;
    setState(() => _launching = true);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) setState(() => _launching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface2),
            child: const Icon(Icons.account_balance_outlined, size: 32, color: AppColors.ink500),
          ),
          const SizedBox(height: 20),
          const Text(
            'Stripe setup',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.ink950),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Complete identity verification in your browser to start receiving payouts. '
            'Return here once done — we will automatically update your shop status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.ink500, height: 1.5),
          ),
          const SizedBox(height: 28),
          PrimaryPillButton(
            label: 'Proceed to Stripe',
            isFullWidth: true,
            size: PillButtonSize.lg,
            isLoading: _launching,
            onPressed: _launching ? null : _openBrowser,
          ),
          const SizedBox(height: 10),
          PrimaryPillButton(
            label: 'Close',
            isFullWidth: true,
            size: PillButtonSize.lg,
            variant: PillButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// Backward-compat alias — existing router/call-sites still compile.
class StripeOnboardingScreen extends StatelessWidget {
  const StripeOnboardingScreen({super.key, required this.accountLinkUrl});
  final String accountLinkUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(child: Center(child: StripeOnboardingDialog(accountLinkUrl: accountLinkUrl))),
    );
  }
}
