import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/controllers/auth_controller.dart';

final isAdminProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session?.user.appMetadata['is_admin'] == true,
    loading: () =>
        Supabase.instance.client.auth.currentUser?.appMetadata['is_admin'] ==
        true,
    error: (_, _) => false,
  );
});
