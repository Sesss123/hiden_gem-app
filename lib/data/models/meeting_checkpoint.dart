class MeetingCheckpoint {
  final String checkpointId;
  final String sessionId;
  final String title;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final String createdBy;

  MeetingCheckpoint({
    required this.checkpointId,
    required this.sessionId,
    required this.title,
    required this.lat,
    required this.lng,
    this.radiusMeters = 50.0,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'checkpointId': checkpointId,
    'sessionId': sessionId,
    'title': title,
    'lat': lat,
    'lng': lng,
    'radiusMeters': radiusMeters,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory MeetingCheckpoint.fromJson(Map<String, dynamic> json) => MeetingCheckpoint(
    checkpointId: json['checkpointId'],
    sessionId: json['sessionId'],
    title: json['title'],
    lat: (json['lat'] ?? 0.0).toDouble(),
    lng: (json['lng'] ?? 0.0).toDouble(),
    radiusMeters: (json['radiusMeters'] ?? 50.0).toDouble(),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    createdBy: json['createdBy'],
  );
}
