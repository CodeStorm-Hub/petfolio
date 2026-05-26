import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/primary_pill_button.dart';
import '../../controllers/my_shop_controller.dart';
import '../../../../../core/theme/app_theme.dart';


class StripeOnboardingScreen extends ConsumerStatefulWidget {
  const StripeOnboardingScreen({super.key, required this.accountLinkUrl});

  final String accountLinkUrl;

  @override
  ConsumerState<StripeOnboardingScreen> createState() =>
      _StripeOnboardingScreenState();
}

class _StripeOnboardingScreenState extends ConsumerState<StripeOnboardingScreen>
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: const Color(0xFF334155)),
                  onPressed: () => context.pop(),
                ),
              ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pt.surface2,
                ),
                child: Icon(Icons.account_balance_outlined,
                    size: 36, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              Text(
                'Stripe setup',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: pt.ink950,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete identity verification in your browser to start receiving payouts. '
                'Return here once done — we will automatically update your shop status.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'Proceed to Stripe to verify your identity',
                isFullWidth: true,
                size: PillButtonSize.lg,
                isLoading: _launching,
                onPressed: _launching ? null : _openBrowser,
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
