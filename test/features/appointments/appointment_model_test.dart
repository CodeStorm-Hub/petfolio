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
    test('deserializes all fields from current schema', () {
      final json = {
        'id': 'appt-1',
        'pet_id': 'pet-1',
        'title': 'Annual check-up',
        'scheduled_at': '2026-07-15T10:30:00.000Z',
        'status': 'upcoming',
        'created_at': '2026-06-01T00:00:00.000Z',
        'vet_name': 'Dr. Shah',
        'location': 'City Vet',
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

    test('maps completed status', () {
      final json = {
        'id': 'appt-3',
        'pet_id': 'pet-1',
        'title': 'Follow-up',
        'scheduled_at': '2026-07-20T09:00:00.000Z',
        'status': 'completed',
        'created_at': '2026-06-01T00:00:00.000Z',
      };
      expect(Appointment.fromJson(json).isCompleted, true);
    });

    test('handles legacy is_completed and clinic_name', () {
      final json = {
        'id': 'appt-2',
        'pet_id': 'pet-1',
        'title': 'Grooming',
        'scheduled_at': '2026-07-20T09:00:00.000Z',
        'is_completed': null,
        'created_at': '2026-06-01T00:00:00.000Z',
        'clinic_name': 'Old Clinic',
      };
      final appt = Appointment.fromJson(json);
      expect(appt.isCompleted, false);
      expect(appt.clinicName, 'Old Clinic');
      expect(appt.vetName, isNull);
      expect(appt.notes, isNull);
    });
  });

  group('Appointment.toInsertJson', () {
    test('includes owner_id and maps clinic to location', () {
      final json = base.toInsertJson(ownerId: 'owner-1');
      expect(json.containsKey('id'), false);
      expect(json['owner_id'], 'owner-1');
      expect(json['pet_id'], 'pet-1');
      expect(json['title'], 'Annual check-up');
      expect(json['status'], 'upcoming');
      expect(json['location'], 'City Vet');
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
      final json = bare.toInsertJson(ownerId: 'owner-1');
      expect(json.containsKey('vet_name'), false);
      expect(json.containsKey('location'), false);
      expect(json.containsKey('notes'), false);
    });

    test('serializes scheduledAt as UTC ISO 8601', () {
      final json = base.toInsertJson(ownerId: 'owner-1');
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
