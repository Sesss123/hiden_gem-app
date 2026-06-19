import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/abuse_event.dart';

final abuseRepositoryProvider = Provider((ref) => AbuseRepository());

class AbuseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _abuseRef => 
      _firestore.collection('abuse_events');

  /// Detects and logs suspicious promo redemption spikes.
  Future<void> logPromoAbuse({
    required String promoCodeId,
    required String userId,
    required String deviceHash,
    required int redemptionsInPastMinute,
    required int threshold,
  }) async {
    if (redemptionsInPastMinute < threshold) return;

    final event = AbuseEvent(
      eventId: _abuseRef.doc().id,
      userId: userId,
      relatedPromoCodeId: promoCodeId,
      type: 'promo_spam',
      severity: redemptionsInPastMinute > threshold * 2 ? 'critical' : 'medium',
      details: 'Suspicious burst of $redemptionsInPastMinute redemptions in 1 minute.',
      deviceHash: deviceHash,
      evidenceSummary: {
        'count': redemptionsInPastMinute,
        'threshold': threshold,
      },
      riskScore: (redemptionsInPastMinute * 5).clamp(0, 100),
      recommendedAction: 'revoke_promo',
      createdAt: DateTime.now(),
    );

    await _abuseRef.doc(event.eventId).set(event.toJson());
  }

  /// Detects impossible movement for a participant in a session.
  Future<void> detectLocationAnomaly({
    required String sessionId,
    required String userId,
    required double newLat,
    required double newLng,
    required double oldLat,
    required double oldLng,
    required DateTime oldTimestamp,
    required double thresholdKmH,
  }) async {
    final double distance = Geolocator.distanceBetween(oldLat, oldLng, newLat, newLng); // Meters
    final double timeSeconds = DateTime.now().difference(oldTimestamp).inSeconds.toDouble();
    if (timeSeconds < 1) return;

    final double speedKmh = (distance / 1000) / (timeSeconds / 3600);

    if (speedKmh > thresholdKmH) {
      final event = AbuseEvent(
        eventId: _abuseRef.doc().id,
        userId: userId,
        relatedSessionId: sessionId,
        type: 'location_anomaly',
        severity: 'high',
        details: 'Impossible movement speed: ${speedKmh.toStringAsFixed(2)} km/h.',
        evidenceSummary: {
          'speed': speedKmh,
          'distance': distance,
          'time': timeSeconds,
          'threshold': thresholdKmH,
        },
        riskScore: ((speedKmh / thresholdKmH) * 20).clamp(0, 100).toInt(),
        recommendedAction: 'investigate_session',
        createdAt: DateTime.now(),
      );

      await _abuseRef.doc(event.eventId).set(event.toJson());
    }
  }

  Future<void> updateAbuseAction(String eventId, String adminId, String action, String note) async {
    await _abuseRef.doc(eventId).update({
      'status': 'penalised',
      'actualActionTaken': action,
      'reviewedAt': DateTime.now().toIso8601String(),
      'reviewedBy': adminId,
      'actionNote': note,
    });
  }

  Stream<List<AbuseEvent>> getRecentSuspiciousEvents() {
    return _abuseRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbuseEvent.fromJson(doc.data()))
            .toList());
  }

  Stream<List<AbuseEvent>> getHighRiskEvents() {
    return _abuseRef
        .where('severity', whereIn: ['high', 'critical'])
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbuseEvent.fromJson(doc.data()))
            .toList());
  }
}
