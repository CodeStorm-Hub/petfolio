import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/features/care/data/models/weight_log.dart';

void main() {
  group('WeightLog.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'wl-1',
        'pet_id': 'pet-1',
        'weight_kg': 4.5,
        'recorded_at': '2026-06-01T08:00:00.000Z',
        'notes': 'After breakfast',
      };
      final log = WeightLog.fromJson(json);
      expect(log.id, 'wl-1');
      expect(log.petId, 'pet-1');
      expect(log.weightKg, 4.5);
      expect(log.recordedAt, DateTime.utc(2026, 6, 1, 8));
      expect(log.notes, 'After breakfast');
    });

    test('handles int weight_kg (coerced to double)', () {
      final json = {
        'id': 'wl-2',
        'pet_id': 'pet-1',
        'weight_kg': 5,
        'recorded_at': '2026-06-02T00:00:00.000Z',
        'notes': null,
      };
      final log = WeightLog.fromJson(json);
      expect(log.weightKg, 5.0);
      expect(log.weightKg, isA<double>());
      expect(log.notes, isNull);
    });
  });

  group('WeightLog.copyWith', () {
    final base = WeightLog(
      id: 'wl-1',
      petId: 'pet-1',
      weightKg: 4.5,
      recordedAt: DateTime.utc(2026, 6, 1),
    );

    test('updates weightKg only', () {
      final updated = base.copyWith(weightKg: 4.8);
      expect(updated.weightKg, 4.8);
      expect(updated.id, base.id);
      expect(updated.recordedAt, base.recordedAt);
    });

    test('preserves all fields when nothing changed', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.petId, base.petId);
      expect(copy.weightKg, base.weightKg);
    });
  });
}
