enum BroadcastType {
  departure,
  meetingPoint,
  delay,
  weather,
  vehicleChange,
  safety,
  general
}

enum BroadcastPriority {
  low,
  normal,
  high,
  critical
}

class BroadcastMessage {
  final String messageId;
  final String sessionId;
  final String guideId;
  final BroadcastType type;
  final String title;
  final String body;
  final BroadcastPriority priority;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool requiresAck;
  final List<String> acknowledgedBy;
  final bool isActive;

  BroadcastMessage({
    required this.messageId,
    required this.sessionId,
    required this.guideId,
    required this.type,
    required this.title,
    required this.body,
    this.priority = BroadcastPriority.normal,
    required this.createdAt,
    this.expiresAt,
    this.requiresAck = false,
    this.acknowledgedBy = const [],
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'messageId': messageId,
    'sessionId': sessionId,
    'guideId': guideId,
    'type': type.name,
    'title': title,
    'body': body,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'requiresAck': requiresAck,
    'acknowledgedBy': acknowledgedBy,
    'isActive': isActive,
  };

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) => BroadcastMessage(
    messageId: json['messageId'],
    sessionId: json['sessionId'],
    guideId: json['guideId'],
    type: BroadcastType.values.byName(json['type']),
    title: json['title'],
    body: json['body'],
    priority: BroadcastPriority.values.byName(json['priority'] ?? 'normal'),
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    requiresAck: json['requiresAck'] ?? false,
    acknowledgedBy: List<String>.from(json['acknowledgedBy'] ?? []),
    isActive: json['isActive'] ?? true,
  );
}
