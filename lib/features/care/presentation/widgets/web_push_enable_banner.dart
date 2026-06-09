import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/firebase/fcm_service.dart';
import '../../../../core/firebase/firebase_env.dart';
import '../../../../core/platform/web_push_environment.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class WebPushEnableBanner extends ConsumerStatefulWidget {
  const WebPushEnableBanner({super.key});

  @override
  ConsumerState<WebPushEnableBanner> createState() => _WebPushEnableBannerState();
}

class _WebPushEnableBannerState extends ConsumerState<WebPushEnableBanner> {
  bool _loading = false;
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !FirebaseEnv.canRequestWebToken) {
      return const SizedBox.shrink();
    }

    if (_enabled) return const SizedBox.shrink();

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final iosBrowserOnly = isAppleMobileWeb && !isIosStandalonePwa;
    final message = iosBrowserOnly
        ? 'Install PetFolio to your Home Screen, then open that app to enable push on iPhone.'
        : 'Enable push notifications for care, matches, and social updates.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: pt.surface2,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: pt.pillarPets),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 13, color: pt.ink700, height: 1.35),
                ),
              ),
              if (!iosBrowserOnly) ...[
                const SizedBox(width: 8),
                _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _enable,
                        child: const Text('Enable'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enable() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      AppSnackBar.showError('Sign in to enable notifications.');
      return;
    }

    setState(() => _loading = true);
    try {
      final error = await FcmService.instance.syncTokenWithMessage(
        requestPermission: true,
      );
      if (!mounted) return;
      if (error == null) {
        setState(() => _enabled = true);
        AppSnackBar.showSuccess('Push notifications enabled for this browser.');
      } else {
        AppSnackBar.showError(error);
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
