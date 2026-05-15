import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';

void main() {
  test('parseCareScheduledTimeOfDay null and empty', () {
    expect(parseCareScheduledTimeOfDay(null), isNull);
    expect(parseCareScheduledTimeOfDay(''), isNull);
    expect(parseCareScheduledTimeOfDay('   '), isNull);
  });

  test('parseCareScheduledTimeOfDay HH:mm', () {
    final t = parseCareScheduledTimeOfDay('09:30');
    expect(t, isNotNull);
    expect(t!.hour, 9);
    expect(t.minute, 30);
  });

  test('parseCareScheduledTimeOfDay HH:mm:ss uses first two parts', () {
    final t = parseCareScheduledTimeOfDay('14:05:00');
    expect(t, isNotNull);
    expect(t!.hour, 14);
    expect(t.minute, 5);
  });
}
