import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/data/models/booking_request.dart';
import 'package:hidden_gems_sl/data/models/subscription_record.dart';

void main() {
  test('pending booking submission preserves the tourist name snapshot', () {
    final request = BookingRequest(
      bookingId: '',
      touristId: 'tourist-1',
      touristDisplayName: 'Nimali',
      guideId: 'guide-1',
      requestedDate: DateTime.utc(2026, 11, 1),
      guestCount: 2,
      createdAt: DateTime.utc(2026, 10, 21),
    );

    final submitted = request.asPendingSubmission(
      bookingId: 'booking-1',
      isPriority: true,
    );

    expect(submitted.touristDisplayName, 'Nimali');
    expect(submitted.toJson()['touristDisplayName'], 'Nimali');
    expect(submitted.bookingId, 'booking-1');
    expect(submitted.status, 'pending');
    expect(submitted.isPriority, isTrue);
  });

  test('legacy webhook subscription data remains readable', () {
    final record = SubscriptionRecord.fromJson({
      'id': 'guide-1',
      'accountType': 'guide',
      'accountId': 'guide-1',
      'planId': 'pro',
      'status': 'active',
      'expiresAt': '2026-11-21T00:00:00Z',
      'lastEventAtMs': DateTime.utc(2026, 10, 21).millisecondsSinceEpoch,
    });

    expect(record.subscriptionId, 'guide-1');
    expect(record.startedAt, DateTime.utc(2026, 10, 21));
    expect(record.expiresAt, DateTime.utc(2026, 11, 21));
  });
}
