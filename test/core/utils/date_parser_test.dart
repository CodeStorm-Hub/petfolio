import 'package:flutter_test/flutter_test.dart';
import 'package:petfolio/core/utils/date_parser.dart';

void main() {
  group('DateParser', () {
    test('formatDate returns Today for current date', () {
      final now = DateTime.now();
      expect(DateParser.formatDate(now), 'Today');
    });

    test('formatDate returns Yesterday for 1 day ago', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateParser.formatDate(yesterday), 'Yesterday');
    });

    test('formatDate returns Xd ago for 2-6 days ago', () {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      expect(DateParser.formatDate(threeDaysAgo), '3d ago');
    });

    test('formatDate returns MM/DD/YYYY for >6 days ago', () {
      final oldDate = DateTime(2023, 5, 12);
      expect(DateParser.formatDate(oldDate), '05/12/2023');
    });

    test('formatTime handles AM correctly', () {
      final dt = DateTime(2023, 5, 12, 9, 30);
      expect(DateParser.formatTime(dt), '9:30 AM');
    });

    test('formatTime handles PM correctly', () {
      final dt = DateTime(2023, 5, 12, 14, 45);
      expect(DateParser.formatTime(dt), '2:45 PM');
    });

    test('formatTime handles midnight correctly', () {
      final dt = DateTime(2023, 5, 12, 0, 15);
      expect(DateParser.formatTime(dt), '12:15 AM');
    });

    test('formatTime handles noon correctly', () {
      final dt = DateTime(2023, 5, 12, 12, 0);
      expect(DateParser.formatTime(dt), '12:00 PM');
    });
  });
}
