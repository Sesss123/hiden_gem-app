import 'package:cloud_firestore/cloud_firestore.dart';

class ARSession {
  final String id; // This will be the 6-digit Join Code
  final String hostUid;
  final String cloudAnchorId;
  final String modelId;
  final bool isHistorical;
  final DateTime createdAt;
  final List<String> participantUids;

  ARSession({
    required this.id,
    required this.hostUid,
    required this.cloudAnchorId,
    required this.modelId,
    this.isHistorical = false,
    required this.createdAt,
    this.participantUids = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'hostUid': hostUid,
      'cloudAnchorId': cloudAnchorId,
      'modelId': modelId,
      'isHistorical': isHistorical,
      'createdAt': Timestamp.fromDate(createdAt),
      'participantUids': participantUids,
    };
  }

  factory ARSession.fromFirestore(String id, Map<String, dynamic> map) {
    return ARSession(
      id: id,
      hostUid: map['hostUid'] as String,
      cloudAnchorId: map['cloudAnchorId'] as String,
      modelId: map['modelId'] as String,
      isHistorical: map['isHistorical'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      participantUids: List<String>.from(map['participantUids'] ?? []),
    );
  }
}
