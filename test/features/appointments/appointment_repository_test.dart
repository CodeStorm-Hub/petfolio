import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/appointments/data/models/appointment.dart';
import 'package:petfolio/features/appointments/data/repositories/appointment_repository.dart';
import '../../helpers/fake_supabase_client.dart';

void main() {
  group('AppointmentRepository', () {
    test('create throws when user is not signed in', () async {
      final repo = AppointmentRepository(FakeSupabaseClient());
      final appointment = Appointment(
        id: '',
        petId: 'pet-1',
        title: 'Vet visit',
        scheduledAt: DateTime.utc(2026, 6, 10, 14),
        isCompleted: false,
        createdAt: DateTime.utc(2026, 6, 8),
      );

      expect(
        () => repo.create(appointment),
        throwsA(isA<StateError>()),
      );
    });
  });
}
