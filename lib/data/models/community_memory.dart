import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMemory extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String message;
  final double rating;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String? imageUrl;

  const CommunityMemory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.message,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.imageUrl,
  });

  factory CommunityMemory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location']['geopoint'] as GeoPoint;
    
    return CommunityMemory(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Explorer',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      message: data['message'] ?? '',
      rating: (data['rating'] ?? 5.0).toDouble(),
      lat: geoPoint.latitude,
      lng: geoPoint.longitude,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'rating': rating,
      'location': {
        'geopoint': GeoPoint(lat, lng),
        'geohash': '', // Will be set by geoflutterfire_plus
      },
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }

  @override
  List<Object?> get props => [id, userId, message, lat, lng];
}
