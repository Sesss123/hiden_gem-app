import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/services/opening_hours_service.dart';

void main() {
  group('OpeningHoursService structured schedules', () {
    test('uses Sri Lanka local time for open status', () {
      final result = OpeningHoursService.evaluate(
        '',
        weeklyHours: {
          'mon': {'open': '08:00', 'close': '17:00', 'closed': false},
        },
        currentTime: DateTime.utc(2026, 9, 14, 4, 30), // 10:00 in Sri Lanka
      );

      expect(result.status, OpenStatus.open);
      expect(result.detailText, contains('5:00 PM'));
    });

    test('explicit weekly closure is closed', () {
      final result = OpeningHoursService.evaluate(
        '',
        weeklyHours: {
          'sun': {'closed': true},
        },
        currentTime: DateTime.utc(2026, 9, 13, 4, 30),
      );

      expect(result.status, OpenStatus.closed);
    });

    test('missing day is unknown rather than falsely closed', () {
      final result = OpeningHoursService.evaluate(
        '',
        weeklyHours: {
          'mon': {'open': '08:00', 'close': '17:00', 'closed': false},
        },
        currentTime: DateTime.utc(2026, 9, 13, 4, 30),
      );

      expect(result.status, OpenStatus.unknown);
    });

    test('previous-day overnight schedule remains open after midnight', () {
      final result = OpeningHoursService.evaluate(
        '',
        weeklyHours: {
          'mon': {'open': '20:00', 'close': '02:00', 'closed': false},
          'tue': {'open': '08:00', 'close': '17:00', 'closed': false},
        },
        currentTime: DateTime.utc(2026, 9, 14, 19, 0), // Tue 00:30 SL
      );

      expect(result.status, OpenStatus.open);
      expect(result.detailText, contains('2:00 AM'));
    });

    test('unparseable legacy text does not claim open', () {
      final result = OpeningHoursService.evaluate(
        'Varies by season',
        currentTime: DateTime.utc(2026, 9, 14),
      );

      expect(result.status, OpenStatus.unknown);
    });

    test('temporary closure overrides weekly schedule', () {
      final result = OpeningHoursService.evaluate(
        '',
        weeklyHours: {
          'mon': {'open': '08:00', 'close': '17:00', 'closed': false},
        },
        temporarilyClosed: true,
        closureNote: 'Flood damage',
        closureUntil: '2026-09-20T00:00:00Z',
        currentTime: DateTime.utc(2026, 9, 14, 4, 30),
      );

      expect(result.status, OpenStatus.closed);
      expect(result.closureReason, 'Flood damage');
    });
  });
}
