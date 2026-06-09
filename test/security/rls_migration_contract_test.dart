import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _criticalTables = [
  'appointments',
  'pet_weight_logs',
  'product_reviews',
  'communities',
  'community_members',
  'community_posts',
  'products',
  'swipes',
  'matches',
  'care_tasks',
  'health_logs',
  'medical_vault',
  'shops',
  'story_reactions',
];

void main() {
  group('RLS migration contract', () {
    late String allMigrationSql;

    setUpAll(() {
      final dir = Directory('supabase/migrations');
      final buffer = StringBuffer();
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.endsWith('.sql')) {
          buffer.writeln(entity.readAsStringSync());
        }
      }
      allMigrationSql = buffer.toString().toLowerCase();
    });

    for (final table in _criticalTables) {
      test('$table has RLS enabled in migrations', () {
        final rlsPattern = RegExp(
          'alter\\s+table\\s+(?:public\\.)?$table\\s+enable\\s+row\\s+level\\s+security',
        );
        expect(
          rlsPattern.hasMatch(allMigrationSql),
          isTrue,
          reason: 'Expected ENABLE ROW LEVEL SECURITY for public.$table',
        );
      });

      test('$table has at least one CREATE POLICY in migrations', () {
        final policyPattern = RegExp(
          'create\\s+policy\\s+[^\\n]+\\s+on\\s+(?:public\\.)?$table',
        );
        expect(
          policyPattern.hasMatch(allMigrationSql),
          isTrue,
          reason: 'Expected CREATE POLICY on public.$table',
        );
      });
    }

    test('recent product_reviews policies use cached auth.uid subselect', () {
      final file = File('supabase/migrations/20260608120000_product_reviews.sql');
      final sql = file.readAsStringSync().toLowerCase();
      expect(sql.contains('(select auth.uid())'), isTrue);
    });
  });
}
