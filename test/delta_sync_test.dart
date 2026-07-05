import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/core/services/delta_sync_service.dart';
import 'package:hidden_gems_sl/core/utils/secure_logger.dart';

void main() {
  group('DeltaSyncService Error Recovery & Quarantine Tests', () {
    setUp(() {
      SecureLogger.clearHistory();
    });

    test('parseDeltaPayload captures malformed records without dropping valid ones or silently failing', () {
      // 1. Simulate a delta payload where one of several places has a malformed required field
      // place_2 has 'riskTags' as a string instead of a List, causing DiscoveryPlace.fromJson to throw TypeError
      final String simulatedPayload = jsonEncode({
        'sync_version': 100,
        'has_more': false,
        'next_cursor': 100,
        'upsert_places': [
          {
            'id': 'place_1',
            'name': 'Sigiriya Rock Fortress',
            'district': 'Matale',
            'category': 'Heritage',
            'lat': 7.9570,
            'lng': 80.7603,
            'rating': 4.9,
            'riskTags': ['Climb', 'Steep'],
            'sync_version': 95
          },
          {
            'id': 'place_2',
            'name': 'Malformed Gem Place',
            'district': 'Kandy',
            'category': 'Nature',
            'lat': 7.2906,
            'lng': 80.6337,
            'rating': 4.5,
            'riskTags': 'INVALID_STRING_INSTEAD_OF_LIST', // Causes TypeError in fromJson
            'sync_version': 98
          },
          {
            'id': 'place_3',
            'name': 'Temple of the Tooth',
            'district': 'Kandy',
            'category': 'Heritage',
            'lat': 7.2936,
            'lng': 80.6385,
            'rating': 4.8,
            'riskTags': ['Crowded'],
            'sync_version': 100
          }
        ],
        'deleted_ids': []
      });

      // 2. Execute parseDeltaPayload
      final result = parseDeltaPayload(simulatedPayload);

      // 3. Verify (b): The other valid places in the same chunk STILL get upserted
      expect(result.placesToUpsert.length, equals(2), reason: 'Valid places must not be dropped when another place fails.');
      expect(result.placesToUpsert[0].id, equals('place_1'));
      expect(result.placesToUpsert[1].id, equals('place_3'));

      // 4. Verify (c): The failed place is captured and flagged with a reason for SQLite quarantine/retry
      expect(result.failedItems.length, equals(1), reason: 'Failed place must be captured in failedItems for quarantine.');
      final failedItem = result.failedItems.first;
      expect(failedItem['id'], equals('place_2'));
      expect(failedItem['name'], equals('Malformed Gem Place'));
      expect(failedItem['sync_version'], equals(98));
      expect(failedItem['reason'], contains('JSON Parse Error:'));

      // 5. Verify (a): The failure is logged with identifying info via SecureLogger
      final errorLogs = SecureLogger.history.where((e) => e.level == '🔴 ERROR' || e.message.contains('place_2')).toList();
      expect(errorLogs.isNotEmpty, isTrue, reason: 'Failure must be surfaced in SecureLogger history.');
      expect(errorLogs.first.message, contains('place_2'));
      expect(errorLogs.first.message, contains('Malformed Gem Place'));
    });
  });
}
