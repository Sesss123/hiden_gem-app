import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/broadcast_message.dart';

final broadcastRepositoryProvider = Provider((ref) => BroadcastRepository());

class BroadcastRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendBroadcast(BroadcastMessage message) async {
    await _firestore
        .collection('tour_sessions')
        .doc(message.sessionId)
        .collection('broadcasts')
        .doc(message.messageId)
        .set(message.toJson());
  }

  Future<void> acknowledgeMessage(String sessionId, String messageId, String userId) async {
    await _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('broadcasts')
        .doc(messageId)
        .update({
      'acknowledgedBy': FieldValue.arrayUnion([userId]),
    });
  }

  Stream<List<BroadcastMessage>> getActiveBroadcasts(String sessionId) {
    final now = DateTime.now();
    return _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('broadcasts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BroadcastMessage.fromJson(doc.data()))
          .where((msg) => msg.expiresAt == null || msg.expiresAt!.isAfter(now))
          .toList();
    });
  }

  Future<void> deactivateBroadcast(String sessionId, String messageId) async {
    await _firestore
        .collection('tour_sessions')
        .doc(sessionId)
        .collection('broadcasts')
        .doc(messageId)
        .update({'isActive': false});
  }
}
