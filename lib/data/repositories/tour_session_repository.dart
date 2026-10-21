import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour_session.dart';
import 'dart:math';

final tourSessionRepositoryProvider =
    Provider((ref) => TourSessionRepository());

class TourSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSession(TourSession session) async {
    await _firestore
        .collection('tour_sessions')
        .doc(session.sessionId)
        .set(session.toJson());
  }

  Future<void> startSession(String sessionId) async {
    final guideId = FirebaseAuth.instance.currentUser?.uid;
    if (guideId == null) throw StateError('Guide sign-in is required.');
    final bookingQuery = await _firestore
        .collection('booking_requests')
        .where('guideId', isEqualTo: guideId)
        .where('linkedSessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    final sessionRef = _firestore.collection('tour_sessions').doc(sessionId);
    final bookingRef =
        bookingQuery.docs.isEmpty ? null : bookingQuery.docs.first.reference;
    final now = DateTime.now().toIso8601String();

    await _firestore.runTransaction((transaction) async {
      final sessionSnapshot = await transaction.get(sessionRef);
      if (!sessionSnapshot.exists ||
          sessionSnapshot.data()?['guideId'] != guideId) {
        throw StateError('Tour session was not found for this guide.');
      }
      if (bookingRef != null) {
        final bookingSnapshot = await transaction.get(bookingRef);
        final booking = bookingSnapshot.data();
        if (booking == null ||
            booking['status'] != 'confirmed' ||
            booking['payoutStatus'] != 'paid') {
          throw StateError(
              'The linked booking must be paid and confirmed before starting.');
        }
        transaction.update(bookingRef, {
          'status': 'in_progress',
          'startedAt': now,
        });
      }
      transaction.update(sessionRef, {
        'status': 'active',
        'actualStartTime': FieldValue.serverTimestamp(),
        'sessionStartedAt': now,
        'startedAt': now,
        'trackingEnabled': true,
      });
    });
  }

  Future<void> endSession(String sessionId,
      {String status = 'completed_normally'}) async {
    final doc =
        await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (!doc.exists) return;

    final touristIds = List<String>.from(doc.get('touristIds') ?? []);
    final now = DateTime.now();
    final reviewWindow = now.add(const Duration(days: 14));

    final guideId = FirebaseAuth.instance.currentUser?.uid;
    if (guideId == null) throw StateError('Guide sign-in is required.');
    final bookingQuery = await _firestore
        .collection('booking_requests')
        .where('guideId', isEqualTo: guideId)
        .where('linkedSessionId', isEqualTo: sessionId)
        .limit(1)
        .get();
    final sessionRef = _firestore.collection('tour_sessions').doc(sessionId);
    final bookingRef =
        bookingQuery.docs.isEmpty ? null : bookingQuery.docs.first.reference;

    await _firestore.runTransaction((transaction) async {
      final sessionSnapshot = await transaction.get(sessionRef);
      if (!sessionSnapshot.exists ||
          sessionSnapshot.data()?['guideId'] != guideId) {
        throw StateError('Tour session was not found for this guide.');
      }
      if (bookingRef != null) {
        final bookingSnapshot = await transaction.get(bookingRef);
        if (bookingSnapshot.data()?['status'] != 'in_progress') {
          throw StateError('The linked booking is not in progress.');
        }
        transaction.update(bookingRef, {
          'status': 'completed',
          'completedAt': now.toIso8601String(),
        });
      }
      transaction.update(sessionRef, {
        'status': 'completed',
        'currentPhase': 'completed',
        'endedAt': now.toIso8601String(),
        'completedAt': now.toIso8601String(),
        'completionStatus': status,
        'reviewWindowEndsAt': reviewWindow.toIso8601String(),
        'reviewEligibleTouristIds': touristIds,
        'trackingEnabled': false,
        'sosActive': false,
        'isLocked': true,
        'isReviewEnabled': true,
      });
    });
  }

  Future<TourSession?> getActiveOrInitialSessionForGuide(String guideId) async {
    // Check for active sessions first
    final activeQuery = await _firestore
        .collection('tour_sessions')
        .where('guideId', isEqualTo: guideId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (activeQuery.docs.isNotEmpty) {
      return TourSession.fromJson(activeQuery.docs.first.data());
    }

    // Check for initial/standby sessions next
    final initialQuery = await _firestore
        .collection('tour_sessions')
        .where('guideId', isEqualTo: guideId)
        .where('status', isEqualTo: 'initial')
        .limit(1)
        .get();
    if (initialQuery.docs.isNotEmpty) {
      return TourSession.fromJson(initialQuery.docs.first.data());
    }

    return null;
  }

  /// Finds the tourist's current active (or assembling) session, if any.
  /// Safe under firestore.rules: querying by `touristIds array-contains uid`
  /// can only ever return sessions the caller is already a participant of.
  Future<TourSession?> getActiveSessionForTourist(String touristId) async {
    final activeQuery = await _firestore
        .collection('tour_sessions')
        .where('touristIds', arrayContains: touristId)
        .where('status', whereIn: ['active', 'initial'])
        .limit(1)
        .get();
    if (activeQuery.docs.isNotEmpty) {
      return TourSession.fromJson(activeQuery.docs.first.data());
    }
    return null;
  }

  Future<void> updateSessionPhase(String sessionId, String phase) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'currentPhase': phase,
    });
  }

  Future<void> updateMeetingPoint(
      String sessionId, String name, double lat, double lng) async {
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

  Future<String> generateJoinToken(String sessionId) async {
    final token =
        _generateShortToken(); // 6-char human readable or UUID fragment
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

  Future<TourSession> previewJoinSession(String token) async {
    final Map<String, dynamic> result;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('validateJoinToken');
      final response =
          await callable.call({'token': token, 'mode': 'preview'});
      result = Map<String, dynamic>.from(response.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        throw Exception(
            "TOO_MANY_ATTEMPTS: ${error.message ?? 'Please wait a few minutes and try again.'}");
      }
      rethrow;
    }

    if (result['found'] != true) {
      throw Exception("INVALID_TOKEN: No active session found for this code.");
    }

    final sessionData = result['session'];
    if (sessionData is! Map) {
      throw Exception("INVALID_TOKEN: No active session found for this code.");
    }
    return TourSession.fromJson(Map<String, dynamic>.from(sessionData));
  }

  Future<TourSession> validateAndJoin({
    required String token,
    required String touristId,
    required bool consent,
  }) async {
    if (touristId != FirebaseAuth.instance.currentUser?.uid) {
      throw StateError('The signed-in tourist does not match the join request.');
    }
    final callable =
        FirebaseFunctions.instance.httpsCallable('validateJoinToken');
    final response = await callable.call({
      'token': token,
      'mode': 'join',
      'trackingConsent': consent,
    });
    final result = Map<String, dynamic>.from(response.data as Map);
    if (result['found'] != true || result['session'] is! Map) {
      throw Exception("INVALID_TOKEN: No active session found for this code.");
    }
    return TourSession.fromJson(
        Map<String, dynamic>.from(result['session'] as Map));
  }

  String _generateShortToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // SOS Logic with 30-second cooldown logic (Throttled)
  // Note: Cooldown is best handled on UI/Backend, but repository can check last SOS time.
  Future<void> triggerSos(String sessionId, bool isActive) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in is required to use SOS.');

    // The session state and its audit record must commit together. Previously
    // the UI could show SOS active even if the alert record failed to write.
    final batch = _firestore.batch();
    batch.update(_firestore.collection('tour_sessions').doc(sessionId), {
      'sosActive': isActive,
    });

    // Record the SOS event in a dedicated collection for Admin audit/alerts
    if (isActive) {
      batch.set(_firestore.collection('sos_alerts').doc(), {
        'sessionId': sessionId,
        'triggeredBy': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'triggered',
      });
    }
    await batch.commit();
  }

  Stream<TourSession?> getActiveSession(String sessionId) {
    return _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => doc.exists ? TourSession.fromJson(doc.data()!) : null);
  }

  Future<TourSession?> getSession(String sessionId) async {
    final doc =
        await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (doc.exists) {
      return TourSession.fromJson(doc.data()!);
    }
    return null;
  }
}
