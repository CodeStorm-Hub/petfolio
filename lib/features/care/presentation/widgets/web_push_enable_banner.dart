import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/firebase/fcm_service.dart';
import '../../../../core/firebase/firebase_env.dart';
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
                  'Enable push notifications for care, matches, and social updates.',
                  style: TextStyle(fontSize: 13, color: pt.ink700, height: 1.35),
                ),
              ),
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
      final ok = await FcmService.instance.syncToken();
      if (!mounted) return;
      if (ok) {
        setState(() => _enabled = true);
        AppSnackBar.showSuccess('Push notifications enabled for this browser.');
      } else {
        AppSnackBar.showError(
          'Could not enable notifications. Add FIREBASE_VAPID_KEY to .env and rebuild.',
        );
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
