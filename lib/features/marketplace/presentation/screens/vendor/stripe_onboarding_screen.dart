import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';

class StripeOnboardingScreen extends StatefulWidget {
  const StripeOnboardingScreen({super.key, required this.accountLinkUrl});

  final String accountLinkUrl;

  @override
  State<StripeOnboardingScreen> createState() => _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState extends State<StripeOnboardingScreen> {
  bool _launched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowser());
  }

  Future<void> _openBrowser() async {
    if (_launched) return;
    _launched = true;
    final uri = Uri.tryParse(widget.accountLinkUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface1,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.ink700),
                  onPressed: () => context.pop(),
                ),
              ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface2,
                ),
                child: const Icon(Icons.account_balance_outlined,
                    size: 36, color: AppColors.ink500),
              ),
              const SizedBox(height: 24),
              const Text(
                'Stripe setup',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink950,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete verification in your browser, then return here. '
                'We will refresh your shop status when you come back.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.ink500),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'Open setup again',
                isFullWidth: true,
                size: PillButtonSize.lg,
                onPressed: () {
                  _launched = false;
                  _openBrowser();
                },
              ),
              const SizedBox(height: 12),
              PrimaryPillButton(
                label: 'Back to dashboard',
                isFullWidth: true,
                size: PillButtonSize.lg,
                variant: PillButtonVariant.secondary,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
