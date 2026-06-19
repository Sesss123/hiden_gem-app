import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour_session.dart';
import '../models/tour_link.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

final tourSessionRepositoryProvider = Provider((ref) => TourSessionRepository());

class TourSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSession(TourSession session) async {
    await _firestore.collection('tour_sessions').doc(session.sessionId).set(session.toJson());
  }

  Future<void> startSession(String sessionId) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'status': 'active',
      'startedAt': DateTime.now().toIso8601String(),
      'trackingEnabled': true,
    });
  }

  Future<void> endSession(String sessionId, {String status = 'completed_normally'}) async {
    final doc = await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (!doc.exists) return;
    
    final touristIds = List<String>.from(doc.get('touristIds') ?? []);
    final now = DateTime.now();
    final reviewWindow = now.add(const Duration(days: 14));

    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'status': 'completed',
      'currentPhase': 'completed',
      'endedAt': now.toIso8601String(),
      'completedAt': now.toIso8601String(),
      'completionStatus': status,
      'reviewWindowEndsAt': reviewWindow.toIso8601String(),
      'reviewEligibleTouristIds': touristIds, // Snapshot participants at end
      'trackingEnabled': false,
      'sosActive': false,
      'isLocked': true,
      'isReviewEnabled': true,
    });
  }

  Future<void> updateSessionPhase(String sessionId, String phase) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'currentPhase': phase,
    });
  }

  Future<void> updateMeetingPoint(String sessionId, String name, double lat, double lng) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('tour_sessions').doc(sessionId);
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentVersion = snapshot.get('meetingPointVersion') ?? 0;
      transaction.update(docRef, {
        'meetingPointName': name,
        'meetingPointLat': lat,
        'meetingPointLng': lng,
        'meetingPointVersion': currentVersion + 1,
      });
    });
  }

  Future<void> joinSession(String sessionId, String touristId) async {
    final doc = await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (!doc.exists) return;
    
    final phase = doc.get('currentPhase') ?? 'assembling';
    if (phase != 'assembling') {
      throw Exception("JOIN_BLOCKED: Tour has already started movement.");
    }

    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'touristIds': FieldValue.arrayUnion([touristId]),
    });
  }

  Future<String> generateJoinToken(String sessionId) async {
    final token = _generateShortToken(); // 6-char human readable or UUID fragment
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'joinToken': token,
      'tokenExpiresAt': expiry.toIso8601String(),
      'isJoinOpen': true,
    });

    return token;
  }

  Future<void> toggleJoinStatus(String sessionId, bool isOpen) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'isJoinOpen': isOpen,
    });
  }

  Future<TourSession> validateAndJoin({
    required String token,
    required String touristId,
    required bool consent,
  }) async {
    // 1. Find session with this active token
    final query = await _firestore
        .collection('tour_sessions')
        .where('joinToken', isEqualTo: token)
        .where('isJoinOpen', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("INVALID_TOKEN: No active session found for this code.");
    }

    final doc = query.docs.first;
    final session = TourSession.fromJson(doc.data());

    // 2. Check Expiry
    if (session.tokenExpiresAt != null && session.tokenExpiresAt!.isBefore(DateTime.now())) {
      throw Exception("EXPIRED_TOKEN: This join code has expired.");
    }

    // 3. Check Limits
    if (session.redeemedCount >= session.maxTourists) {
      throw Exception("LIMIT_REACHED: This session is full.");
    }

    // 4. Check Phase
    if (session.currentPhase != 'assembling') {
      throw Exception("JOIN_BLOCKED: Tour is already in progress.");
    }

    // 5. Atomic Join Transaction
    await _firestore.runTransaction((transaction) async {
      final sessionRef = _firestore.collection('tour_sessions').doc(session.sessionId);
      
      // Create TourLink
      final linkId = const Uuid().v4();
      final tourLink = TourLink(
        linkId: linkId,
        sessionId: session.sessionId,
        guideId: session.guideId,
        touristId: touristId,
        linkedAt: DateTime.now(),
        linkMethod: 'qr',
        trackingConsent: consent,
      );

      transaction.set(_firestore.collection('tour_links').doc(linkId), tourLink.toJson());
      
      // Update Session
      transaction.update(sessionRef, {
        'touristIds': FieldValue.arrayUnion([touristId]),
        'redeemedCount': FieldValue.increment(1),
      });
    });

    return session;
  }

  String _generateShortToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // SOS Logic with 30-second cooldown logic (Throttled)
  // Note: Cooldown is best handled on UI/Backend, but repository can check last SOS time.
  Future<void> triggerSos(String sessionId, bool isActive) async {
    // Phase A: Simple toggle for now, cooldown logic in UI/Functions
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'sosActive': isActive,
    });

    // Record the SOS event in a dedicated collection for Admin audit/alerts
    if (isActive) {
      await _firestore.collection('sos_alerts').add({
        'sessionId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'triggered',
      });
    }
  }

  Stream<TourSession?> getActiveSession(String sessionId) {
    return _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? TourSession.fromJson(doc.data()!) : null);
  }

  Future<TourSession?> getSession(String sessionId) async {
    final doc = await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (doc.exists) {
      return TourSession.fromJson(doc.data()!);
    }
    return null;
  }
}
