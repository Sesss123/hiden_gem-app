import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_presence.dart';

final presenceRepositoryProvider = Provider((ref) => PresenceRepository());

class PresenceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateGuidePresence(String sessionId, Position position) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'lastGuideLat': position.latitude,
      'lastGuideLng': position.longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Also update the guide's individual presence entry
    await updateParticipantPresence(
      sessionId: sessionId,
      userId: 'guide_default', // In production, use real guide UID
      position: position,
      role: 'guide',
    );

    // Legacy support
    final sessionDoc = await _firestore.collection('tour_sessions').doc(sessionId).get();
    if (sessionDoc.exists) {
      final guideId = sessionDoc.get('guideId');
      await _firestore.collection('users').doc(guideId).update({
        'lastKnownLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
    }
  }

  Future<void> updateParticipantPresence({
    required String sessionId,
    required String userId,
    required Position position,
    required String role,
    bool isOnline = true,
  }) async {
    final presence = SessionPresence(
      userId: userId,
      sessionId: sessionId,
      role: role,
      lastSeenAt: DateTime.now(),
      lat: position.latitude,
      lng: position.longitude,
      accuracyMeters: position.accuracy,
      isOnline: isOnline,
    );

    await _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('presence')
        .doc(userId)
        .set(presence.toJson());
  }

  Future<void> updateVehiclePresence(String sessionId, double lat, double lng) async {
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'lastVehicleLat': lat,
      'lastVehicleLng': lng,
      'lastVehicleUpdate': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SessionPresence>> getAllParticipantsPresence(String sessionId) {
    return _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('presence')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionPresence.fromJson(doc.data()))
            .toList());
  }

  Stream<Map<String, double>> getPresence(String sessionId) {
    return _firestore.collection('tour_sessions').doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data()!;
      return {
        'guideLat': (data['lastGuideLat'] ?? 0.0).toDouble(),
        'guideLng': (data['lastGuideLng'] ?? 0.0).toDouble(),
        'vehicleLat': (data['lastVehicleLat'] ?? 0.0).toDouble(),
        'vehicleLng': (data['lastVehicleLng'] ?? 0.0).toDouble(),
      };
    });
  }
}
