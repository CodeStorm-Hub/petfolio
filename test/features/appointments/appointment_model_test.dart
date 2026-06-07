import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/features/appointments/data/models/appointment.dart';

void main() {
  final base = Appointment(
    id: 'appt-1',
    petId: 'pet-1',
    title: 'Annual check-up',
    scheduledAt: DateTime.utc(2026, 7, 15, 10, 30),
    isCompleted: false,
    createdAt: DateTime.utc(2026, 6, 1),
    vetName: 'Dr. Shah',
    clinicName: 'City Vet',
    notes: 'Bring vaccination card',
  );

  group('Appointment.fromJson', () {
    test('deserializes all fields', () {
      final json = {
        'id': 'appt-1',
        'pet_id': 'pet-1',
        'title': 'Annual check-up',
        'scheduled_at': '2026-07-15T10:30:00.000Z',
        'is_completed': false,
        'created_at': '2026-06-01T00:00:00.000Z',
        'vet_name': 'Dr. Shah',
        'clinic_name': 'City Vet',
        'notes': 'Bring vaccination card',
      };
      final appt = Appointment.fromJson(json);
      expect(appt.id, 'appt-1');
      expect(appt.petId, 'pet-1');
      expect(appt.title, 'Annual check-up');
      expect(appt.scheduledAt, DateTime.utc(2026, 7, 15, 10, 30));
      expect(appt.isCompleted, false);
      expect(appt.vetName, 'Dr. Shah');
      expect(appt.clinicName, 'City Vet');
      expect(appt.notes, 'Bring vaccination card');
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'appt-2',
        'pet_id': 'pet-1',
        'title': 'Grooming',
        'scheduled_at': '2026-07-20T09:00:00.000Z',
        'is_completed': null,
        'created_at': '2026-06-01T00:00:00.000Z',
      };
      final appt = Appointment.fromJson(json);
      expect(appt.isCompleted, false);
      expect(appt.vetName, isNull);
      expect(appt.clinicName, isNull);
      expect(appt.notes, isNull);
    });
  });

  group('Appointment.toJson', () {
    test('omits id — server assigns it on insert', () {
      final json = base.toJson();
      expect(json.containsKey('id'), false);
    });

    test('includes required fields', () {
      final json = base.toJson();
      expect(json['pet_id'], 'pet-1');
      expect(json['title'], 'Annual check-up');
      expect(json['is_completed'], false);
    });

    test('omits null optional fields', () {
      final bare = Appointment(
        id: 'x',
        petId: 'p',
        title: 'T',
        scheduledAt: DateTime.utc(2026),
        isCompleted: false,
        createdAt: DateTime.utc(2026),
      );
      final json = bare.toJson();
      expect(json.containsKey('vet_name'), false);
      expect(json.containsKey('clinic_name'), false);
      expect(json.containsKey('notes'), false);
    });

    test('serializes scheduledAt as UTC ISO 8601', () {
      final json = base.toJson();
      expect(json['scheduled_at'], '2026-07-15T10:30:00.000Z');
    });
  });

  group('Appointment.copyWith', () {
    test('preserves unchanged fields', () {
      final updated = base.copyWith(isCompleted: true);
      expect(updated.id, base.id);
      expect(updated.petId, base.petId);
      expect(updated.title, base.title);
      expect(updated.scheduledAt, base.scheduledAt);
      expect(updated.vetName, base.vetName);
    });

    test('updates only the given field', () {
      final updated = base.copyWith(title: 'Dental cleaning');
      expect(updated.title, 'Dental cleaning');
      expect(updated.isCompleted, false);
    });

    test('toggles isCompleted', () {
      final done = base.copyWith(isCompleted: true);
      expect(done.isCompleted, true);
      final undone = done.copyWith(isCompleted: false);
      expect(undone.isCompleted, false);
    });
  });
}
