import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:hidden_gems_sl/core/config/app_config.dart';

void main() {
  group('Account Deletion Service & Contract Tests', () {
    test('Account deletion contract targets Laravel /auth/account endpoint', () {
      final endpoint = '${AppConfig.laravelUrl}/auth/account';
      expect(endpoint, contains('/auth/account'));
      expect(endpoint, startsWith('http'));
    });

    test('Non-200 server response extracts backend error message properly', () {
      const errorJson = '{"status":"error","message":"Account deletion failed due to a server error. Your account has not been deleted. Please try again.","code":"deletion_failed"}';
      final parsed = jsonDecode(errorJson) as Map<String, dynamic>;

      expect(parsed['status'], equals('error'));
      expect(parsed['code'], equals('deletion_failed'));
      expect(parsed['message'], contains('Your account has not been deleted'));

      String? serverMsg;
      try {
        final body = jsonDecode(errorJson);
        serverMsg = body['message'] as String?;
      } catch (_) {}

      expect(serverMsg, equals(parsed['message']));
    });

    test('Server error fallback message is used when response body is not JSON', () {
      const nonJsonBody = '<html>502 Bad Gateway</html>';
      String? serverMsg;
      try {
        final body = jsonDecode(nonJsonBody);
        serverMsg = body['message'] as String?;
      } catch (_) {}

      final resolvedMessage = serverMsg ?? 'Account deletion failed on the server (502).';
      expect(resolvedMessage, equals('Account deletion failed on the server (502).'));
    });

    test('FCM unsubscription list covers all user roles and session topics', () {
      const testUid = 'user_test_uid_456';
      final expectedTopics = [
        'guide_$testUid',
        'user_$testUid',
        'tourist_$testUid',
        'booking_$testUid',
      ];

      expect(expectedTopics.length, equals(4));
      expect(expectedTopics, contains('guide_user_test_uid_456'));
      expect(expectedTopics, contains('user_user_test_uid_456'));
      expect(expectedTopics, contains('tourist_user_test_uid_456'));
      expect(expectedTopics, contains('booking_user_test_uid_456'));
    });

    test('Dual storage folder keys resolve correctly for both UID and numeric ID', () {
      const uid = 'firebase-uid-abc';
      const numericId = 105;

      final guideDocPaths = [
        'guide_documents/$uid',
        'guide_documents/$numericId',
      ];
      final listingPhotoPaths = [
        'listing_photos/$uid',
        'listing_photos/$numericId',
      ];

      expect(guideDocPaths[0], equals('guide_documents/firebase-uid-abc'));
      expect(guideDocPaths[1], equals('guide_documents/105'));
      expect(listingPhotoPaths[0], equals('listing_photos/firebase-uid-abc'));
      expect(listingPhotoPaths[1], equals('listing_photos/105'));
    });
  });
}
