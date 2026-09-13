import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/data/models/family_share_link.dart';

void main() {
  final baseJson = <String, dynamic>{
    'shareId': 'ABCDEFGHJKLMNPQRSTUVWXYZ23',
    'touristId': 'tourist-1',
    'sessionId': 'session-1',
    'recipientName': 'Family',
    'shareToken': 'ABCDEFGHJKLMNPQRSTUVWXYZ23',
    'isActive': true,
    'permissions': <String, bool>{'show_status': true},
    'viewCount': 0,
  };

  test('serializes expiry as an absolute Firestore timestamp', () {
    final expiry = DateTime.parse('2026-09-13T12:00:00+05:30');
    final link = FamilyShareLink.fromJson({
      ...baseJson,
      'expiresAt': Timestamp.fromDate(expiry),
    });

    final encoded = link.toJson();
    expect(encoded['expiresAt'], isA<Timestamp>());
    expect((encoded['expiresAt'] as Timestamp).toDate().toUtc(), expiry.toUtc());
  });

  test('continues to read legacy ISO string expiry documents', () {
    final link = FamilyShareLink.fromJson({
      ...baseJson,
      'expiresAt': '2026-09-13T12:00:00.000',
    });

    expect(link.expiresAt, DateTime(2026, 9, 13, 12));
  });
}
