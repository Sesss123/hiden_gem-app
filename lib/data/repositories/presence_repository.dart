import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_presence.dart';

final presenceRepositoryProvider = Provider((ref) => PresenceRepository());

class PresenceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Skip a write if the position hasn't moved meaningfully since the last
  // one we actually wrote — a guide/tourist standing still at a stop was
  // previously getting a full Firestore write every tick (5-30s) even
  // though lat/lng were identical. A keep-alive interval still forces a
  // write periodically so "isOnline"/"lastUpdated" freshness holds up for
  // safety monitoring even when nobody is moving.
  static const double _minMoveMeters = 12.0;
  static const Duration _keepAliveInterval = Duration(minutes: 3);

  // Keyed by sessionId — the repository instance is app-lifetime (Riverpod
  // Provider, not autoDispose), and a guide could plausibly run more than
  // one tour session within a single app run, so caches must not leak
  // staleness across sessions.
  final Map<String, Position> _lastGuidePositions = {};
  final Map<String, DateTime> _lastGuideWriteAt = {};
  final Map<String, Position> _lastParticipantPositions = {};
  final Map<String, DateTime> _lastParticipantWriteAt = {};
  final Map<String, Position> _lastVehiclePositions = {};
  final Map<String, DateTime> _lastVehicleWriteAt = {};

  bool _shouldSkipWrite(Position? lastPos, DateTime? lastWriteAt, Position newPos) {
    if (lastPos == null || lastWriteAt == null) return false;
    if (DateTime.now().difference(lastWriteAt) >= _keepAliveInterval) return false;
    final movedMeters = Geolocator.distanceBetween(
      lastPos.latitude, lastPos.longitude, newPos.latitude, newPos.longitude,
    );
    return movedMeters < _minMoveMeters;
  }

  Future<void> updateGuidePresence(String sessionId, Position position) async {
    if (_shouldSkipWrite(_lastGuidePositions[sessionId], _lastGuideWriteAt[sessionId], position)) return;
    _lastGuidePositions[sessionId] = position;
    _lastGuideWriteAt[sessionId] = DateTime.now();

    // Cost fix: this used to ALSO call updateParticipantPresence() below on
    // every single tick, writing a second document
    // (tour_sessions/{sessionId}/presence/{guideId}) for the exact same
    // position update. That subcollection has zero readers anywhere in the
    // app (getAllParticipantsPresence(), the only method that queries it,
    // has zero callers) — map_explorer_screen.dart and
    // tourist_companion_hub.dart both read the guide's live location from
    // THIS document's lastGuideLat/lastGuideLng fields, not the presence
    // subcollection. Same class of dead-write bug as the already-removed
    // users/{guideId}.lastKnownLocation write (see prior fix). During an
    // active vehicle tour this ran every ~5s, so removing it halves the
    // guide GPS write volume for the whole tour duration.
    //
    // updateParticipantPresence() itself is kept — it's still used by the
    // tourist "I'm Lost" button and vehicle-position marking, both
    // low-frequency, user-tap-triggered calls, not this high-frequency
    // timer path.
    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'lastGuideLat': position.latitude,
      'lastGuideLng': position.longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateParticipantPresence({
    required String sessionId,
    required String userId,
    required Position position,
    required String role,
    bool isOnline = true,
  }) async {
    final cacheKey = '$sessionId:$userId';
    final lastPos = _lastParticipantPositions[cacheKey];
    final lastWriteAt = _lastParticipantWriteAt[cacheKey];
    if (_shouldSkipWrite(lastPos, lastWriteAt, position)) return;
    _lastParticipantPositions[cacheKey] = position;
    _lastParticipantWriteAt[cacheKey] = DateTime.now();

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
    final newPos = Position(
      latitude: lat, longitude: lng, timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0,
      headingAccuracy: 0, speed: 0, speedAccuracy: 0,
    );
    if (_shouldSkipWrite(_lastVehiclePositions[sessionId], _lastVehicleWriteAt[sessionId], newPos)) return;
    _lastVehiclePositions[sessionId] = newPos;
    _lastVehicleWriteAt[sessionId] = DateTime.now();

    await _firestore.collection('tour_sessions').doc(sessionId).update({
      'lastVehicleLat': lat,
      'lastVehicleLng': lng,
      'lastVehicleUpdate': FieldValue.serverTimestamp(),
    });
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
