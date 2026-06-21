import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class VendorWebRedirectScreen extends StatefulWidget {
  const VendorWebRedirectScreen({super.key});

  @override
  State<VendorWebRedirectScreen> createState() =>
      _VendorWebRedirectScreenState();
}

class _VendorWebRedirectScreenState extends State<VendorWebRedirectScreen> {
  bool _launchFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDashboard());
  }

  Future<void> _openDashboard() async {
    final uri = Uri.parse(AppConfig.dashboardUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) setState(() => _launchFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.poppySoftD : AppColors.poppySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🛍️', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Selling moved to the\nweb dashboard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: pt.ink950,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _launchFailed
                      ? 'Open this link on your device:\n${AppConfig.dashboardUrl}'
                      : 'Manage your shop, products, and orders at\n${AppConfig.dashboardUrl}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: pt.ink500, height: 1.5),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openDashboard,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.poppy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle:
                          GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    child: const Text('Open vendor dashboard'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/marketplace'),
                  child: const Text('Back to shop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
