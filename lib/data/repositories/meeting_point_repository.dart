import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_checkpoint.dart';

final meetingPointRepositoryProvider = Provider((ref) => MeetingPointRepository());

class MeetingPointRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateMeetingPoint(MeetingCheckpoint checkpoint) async {
    // 1. Update the session-level quick snapshot
    await _firestore.collection('tour_sessions').doc(checkpoint.sessionId).update({
      'meetingPointName': checkpoint.title,
      'meetingPointLat': checkpoint.lat,
      'meetingPointLng': checkpoint.lng,
    });

    // 2. Add to history of checkpoints
    await _firestore
        .collection('tour_sessions')
        .doc(checkpoint.sessionId)
        .collection('checkpoints')
        .doc(checkpoint.checkpointId)
        .set(checkpoint.toJson());
  }

  Stream<MeetingCheckpoint?> getActiveCheckpoint(String sessionId) {
    return _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('checkpoints')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? MeetingCheckpoint.fromJson(snapshot.docs.first.data())
            : null);
  }
}
