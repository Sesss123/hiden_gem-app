import 'package:cloud_firestore/cloud_firestore.dart';

class TourBatch {
  final String id;
  final String guideId;
  final List<String> touristIds;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'active', 'completed', 'cancelled'
  final bool isSafetySyncEnabled;
  final bool isSosActive;

  TourBatch({
    required this.id,
    required this.guideId,
    required this.touristIds,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'active',
    this.isSafetySyncEnabled = false,
    this.isSosActive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'guideId': guideId,
        'touristIds': touristIds,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status,
        'isSafetySyncEnabled': isSafetySyncEnabled,
        'isSosActive': isSosActive,
      };

  factory TourBatch.fromJson(Map<String, dynamic> json) => TourBatch(
        id: json['id'],
        guideId: json['guideId'],
        touristIds: List<String>.from(json['touristIds'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        expiresAt: DateTime.parse(json['expiresAt']),
        status: json['status'] ?? 'active',
        isSafetySyncEnabled: json['isSafetySyncEnabled'] ?? false,
        isSosActive: json['isSosActive'] ?? false,
      );

  factory TourBatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TourBatch.fromJson({...data, 'id': doc.id});
  }
}
