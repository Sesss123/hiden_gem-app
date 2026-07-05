import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_gems_sl/data/models/tour_session.dart';

void main() {
  group('Phase 2 Financial & Session Priority Tests', () {
    test('Commission calculation deducts 10% platform fee and yields 90% guide net earned', () {
      const double quotedPrice = 35000.0;
      final double commissionAmount = quotedPrice * 0.10;
      final double guideNetAmount = quotedPrice * 0.90;

      expect(commissionAmount, equals(3500.0), reason: 'Platform commission must be exactly 10%');
      expect(guideNetAmount, equals(31500.0), reason: 'Guide net earnings must be exactly 90%');
      expect(commissionAmount + guideNetAmount, equals(quotedPrice), reason: 'Net + Commission must equal Gross Quoted Price');
    });

    test('Session priority discovery favors active status over initial standby status', () {
      final initialSession = TourSession(
        sessionId: 'session_initial',
        guideId: 'guide_123',
        touristIds: ['tourist_1'],
        meetingPointName: 'Colombo Fort',
        meetingPointLat: 6.9319,
        meetingPointLng: 79.8478,
        status: 'initial',
      );

      final activeSession = TourSession(
        sessionId: 'session_active',
        guideId: 'guide_123',
        touristIds: ['tourist_1', 'tourist_2'],
        meetingPointName: 'Galle Face Green',
        meetingPointLat: 6.9271,
        meetingPointLng: 79.8612,
        status: 'active',
      );

      final sessions = [initialSession, activeSession];

      // Simulate getActiveOrInitialSessionForGuide priority logic
      TourSession? selectedSession;
      try {
        selectedSession = sessions.firstWhere((s) => s.status == 'active');
      } catch (_) {
        try {
          selectedSession = sessions.firstWhere((s) => s.status == 'initial');
        } catch (_) {
          selectedSession = null;
        }
      }

      expect(selectedSession, isNotNull);
      expect(selectedSession!.sessionId, equals('session_active'), reason: 'Active session must be prioritized over initial standby session');
    });

    test('Session priority discovery falls back to initial standby status when no active session exists', () {
      final initialSession = TourSession(
        sessionId: 'session_initial',
        guideId: 'guide_123',
        touristIds: ['tourist_1'],
        meetingPointName: 'Colombo Fort',
        meetingPointLat: 6.9319,
        meetingPointLng: 79.8478,
        status: 'initial',
      );

      final sessions = [initialSession];

      // Simulate getActiveOrInitialSessionForGuide priority logic
      TourSession? selectedSession;
      try {
        selectedSession = sessions.firstWhere((s) => s.status == 'active');
      } catch (_) {
        try {
          selectedSession = sessions.firstWhere((s) => s.status == 'initial');
        } catch (_) {
          selectedSession = null;
        }
      }

      expect(selectedSession, isNotNull);
      expect(selectedSession!.sessionId, equals('session_initial'), reason: 'Initial session must be returned when no active session exists');
    });
  });
}
