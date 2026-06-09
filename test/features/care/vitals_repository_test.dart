import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/care/data/repositories/vitals_repository.dart';
import '../../helpers/fake_supabase_client.dart';

void main() {
  group('VitalsRepository', () {
    test('instantiates with Supabase client', () {
      expect(VitalsRepository(FakeSupabaseClient()), isA<VitalsRepository>());
    });
  });
}
