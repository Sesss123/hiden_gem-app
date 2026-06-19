class AbuseEvent {
  final String eventId;
  final String userId;
  final String? relatedSessionId;
  final String? relatedPromoCodeId;
  
  // Event Categorization
  final String type; // promo_spam, duplicate_redemption, location_anomaly, session_creation_spike, suspicious_role_change_attempt, review_abuse, fake_presence, excessive_sos
  final String severity; // low, medium, high, critical
  final String details;
  final String description; // Detailed human-readable log
  final String? deviceHash;
  final String? ipHash;
  
  // Intel
  final Map<String, dynamic> evidenceSummary; // {distanceKm, redemptionsPerMinute, etc.}
  final int riskScore; // 0-100 impact on user reputation
  
  // Pipeline Results
  final String recommendedAction; // warning, suspension, revoke_promo, none
  final String? actualActionTaken;
  final bool autoActionTriggered;
  
  // Administrative Status
  final String status; // open, reviewed, dismissed, penalised
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? actionNote;

  AbuseEvent({
    required this.eventId,
    required this.userId,
    this.relatedSessionId,
    this.relatedPromoCodeId,
    required this.type,
    required this.severity,
    required this.details,
    this.description = '',
    this.deviceHash,
    this.ipHash,
    this.evidenceSummary = const {},
    this.riskScore = 0,
    required this.recommendedAction,
    this.actualActionTaken,
    this.autoActionTriggered = false,
    this.status = 'open',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.actionNote,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'userId': userId,
    'relatedSessionId': relatedSessionId,
    'relatedPromoCodeId': relatedPromoCodeId,
    'type': type,
    'severity': severity,
    'details': details,
    'description': description,
    'deviceHash': deviceHash,
    'ipHash': ipHash,
    'evidenceSummary': evidenceSummary,
    'riskScore': riskScore,
    'recommendedAction': recommendedAction,
    'actualActionTaken': actualActionTaken,
    'autoActionTriggered': autoActionTriggered,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
    'actionNote': actionNote,
  };

  factory AbuseEvent.fromJson(Map<String, dynamic> json) => AbuseEvent(
    eventId: json['eventId'],
    userId: json['userId'],
    relatedSessionId: json['relatedSessionId'],
    relatedPromoCodeId: json['relatedPromoCodeId'],
    type: json['type'],
    severity: json['severity'],
    details: json['details'],
    description: json['description'] ?? '',
    deviceHash: json['deviceHash'],
    ipHash: json['ipHash'],
    evidenceSummary: Map<String, dynamic>.from(json['evidenceSummary'] ?? {}),
    riskScore: json['riskScore'] ?? 0,
    recommendedAction: json['recommendedAction'],
    actualActionTaken: json['actualActionTaken'],
    autoActionTriggered: json['autoActionTriggered'] ?? false,
    status: json['status'] ?? 'open',
    createdAt: DateTime.parse(json['createdAt']),
    reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
    reviewedBy: json['reviewedBy'],
    actionNote: json['actionNote'],
  );
}
