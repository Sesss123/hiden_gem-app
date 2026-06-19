import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ar_video_content.dart';
import '../../../../core/utils/secure_logger.dart';

/// Repository for fetching AR Cinematic content from Firestore.
/// Collection: 'locations'
class ARVideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a single AR video content by location ID.
  /// Falls back to Sigiriya demo if the document doesn't exist or is offline.
  Future<ARVideoContent> fetchContent(String locationId) async {
    try {
      final doc = await _firestore.collection('locations').doc(locationId).get();
      
      if (!doc.exists) {
        SecureLogger.info('AR Content for $locationId not found, falling back to demo.');
        return ARVideoContent.sigiriyaDemo();
      }

      return ARVideoContent.fromMap(doc.id, doc.data()!);
    } catch (e) {
      SecureLogger.error('Error fetching AR content for $locationId: $e');
      return ARVideoContent.sigiriyaDemo();
    }
  }

  /// Streams all AR-enabled locations for the Library screen.
  Stream<List<ARVideoContent>> streamAllEnabled() {
    return _firestore
        .collection('locations')
        .where('videoUrl', isNotEqualTo: '') // Basic filter for AR-enabled
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ARVideoContent.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// One-time fetch of all AR-enabled locations.
  Future<List<ARVideoContent>> getAllEnabled() async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('videoUrl', isNotEqualTo: '')
          .get();
      
      final list = snapshot.docs
          .map((doc) => ARVideoContent.fromMap(doc.id, doc.data()))
          .toList();

      // Ensure Sigiriya is always there for demo purposes if list is empty
      if (list.isEmpty) {
        return [ARVideoContent.sigiriyaDemo()];
      }
      return list;
    } catch (e) {
      SecureLogger.error('Error getting AR library: $e');
      return [ARVideoContent.sigiriyaDemo()];
    }
  }
}
