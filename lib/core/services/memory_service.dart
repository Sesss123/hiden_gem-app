import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../../data/models/community_memory.dart';
import '../../core/utils/secure_logger.dart';

class MemoryService {
  static final _firestore = FirebaseFirestore.instance;
  static final _collection = _firestore.collection('community_memories');

  /// Post a new memory drop to a specific location
  static Future<void> dropMemory({
    required String userId,
    required String userName,
    required String userPhotoUrl,
    required String message,
    required double lat,
    required double lng,
    String? imageUrl,
  }) async {
    try {
      final GeoFirePoint point = GeoFirePoint(GeoPoint(lat, lng));
      
      await _collection.add({
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'message': message,
        'location': point.data,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });
      SecureLogger.info('Memory dropped successfully at $lat, $lng');
    } catch (e) {
      SecureLogger.error('Failed to drop memory: $e');
      rethrow;
    }
  }

  /// Listen to community memories within a 5km radius
  static Stream<List<CommunityMemory>> getNearbyMemories(double lat, double lng, {double radiusInKm = 5.0}) {
    final GeoFirePoint center = GeoFirePoint(GeoPoint(lat, lng));
    
    return GeoCollectionReference(_collection)
        .subscribeWithin(
      center: center,
      radiusInKm: radiusInKm,
      field: 'location',
      geopointFrom: (data) => (data['location'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
    )
    .map((docs) => docs.map((doc) => CommunityMemory.fromFirestore(doc)).toList());
  }
}
