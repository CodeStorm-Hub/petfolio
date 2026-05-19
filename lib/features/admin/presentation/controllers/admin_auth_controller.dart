import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final isAdminProvider = Provider<bool>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.appMetadata['is_admin'] == true;
});
