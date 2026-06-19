class SessionPresence {
  final String userId;
  final String sessionId;
  final String role; // guide, tourist
  final DateTime lastSeenAt;
  final double? lat;
  final double? lng;
  final double? accuracyMeters;
  final bool isOnline;

  SessionPresence({
    required this.userId,
    required this.sessionId,
    required this.role,
    required this.lastSeenAt,
    this.lat,
    this.lng,
    this.accuracyMeters,
    this.isOnline = true,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'sessionId': sessionId,
    'role': role,
    'lastSeenAt': lastSeenAt.toIso8601String(),
    'lat': lat,
    'lng': lng,
    'accuracyMeters': accuracyMeters,
    'isOnline': isOnline,
  };

  factory SessionPresence.fromJson(Map<String, dynamic> json) => SessionPresence(
    userId: json['userId'],
    sessionId: json['sessionId'],
    role: json['role'] ?? 'tourist',
    lastSeenAt: DateTime.parse(json['lastSeenAt']),
    lat: (json['lat'])?.toDouble(),
    lng: (json['lng'])?.toDouble(),
    accuracyMeters: (json['accuracyMeters'])?.toDouble(),
    isOnline: json['isOnline'] ?? true,
  );
}
