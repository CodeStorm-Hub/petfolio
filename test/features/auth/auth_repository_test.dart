import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/auth/data/repositories/auth_repository.dart';
import '../../helpers/fake_supabase_client.dart';

void main() {
  group('AuthRepository', () {
    test('currentUser is null when not signed in', () {
      final repo = AuthRepository(FakeSupabaseClient());
      expect(repo.currentUser, isNull);
      expect(repo.currentSession, isNull);
    });
  });
}
