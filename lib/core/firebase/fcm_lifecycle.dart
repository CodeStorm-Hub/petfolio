import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import 'fcm_service.dart';

class FcmLifecycle extends ConsumerStatefulWidget {
  const FcmLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FcmLifecycle> createState() => _FcmLifecycleState();
}

class _FcmLifecycleState extends ConsumerState<FcmLifecycle> {
  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((state) async {
        if (state.session != null) {
          await FcmService.instance.syncToken();
        } else {
          await FcmService.instance.clearTokenForSignOut();
        }
      });
    });

    final router = GoRouter.of(context);
    FcmService.instance.updateRouter(router);
    return widget.child;
  }
}
