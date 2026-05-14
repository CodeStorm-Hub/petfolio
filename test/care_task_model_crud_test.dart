import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/care/data/models/care_task.dart';

void main() {
  test('CareTask copyWith used for edit keeps stable keys', () {
    final now = DateTime.utc(2026, 6, 2, 12);
    final t = CareTask(
      id: 'task-id',
      petId: 'pet-id',
      taskType: CareTaskType.feeding,
      title: 'Morning',
      frequency: CareFrequency.daily,
      scheduledTime: '08:00',
      isCompleted: false,
      completedAt: null,
      gamificationPoints: 10,
      notes: null,
      categoryIcon: null,
      createdAt: now,
      updatedAt: now,
    );
    final u = t.copyWith(
      title: 'Evening meal',
      taskType: CareTaskType.feeding,
      frequency: CareFrequency.twiceDaily,
      scheduledTime: '18:00',
      updatedAt: DateTime.utc(2026, 6, 2, 15),
    );
    expect(u.id, 'task-id');
    expect(u.petId, 'pet-id');
    expect(u.createdAt, now);
    expect(u.title, 'Evening meal');
    expect(u.frequency, CareFrequency.twiceDaily);
    expect(u.scheduledTime, '18:00');
  });
}
