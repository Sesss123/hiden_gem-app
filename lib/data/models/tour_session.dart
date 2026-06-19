class TourSession {
  final String sessionId;
  final String guideId;
  final List<String> touristIds;
  final String meetingPointName;
  final double meetingPointLat;
  final double meetingPointLng;
  final String? vehicleId;
  final String? vehicleNumber;
  final String status; // initial, active, completed, cancelled
  final String currentPhase; // assembling, en_route, at_site, break_time, returning
  final String? sessionCode;
  final bool trackingEnabled;
  final bool sosActive;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int maxTourists;
  final String? notes;
  final double? lastGuideLat;
  final double? lastGuideLng;
  final double? lastVehicleLat;
  final double? lastVehicleLng;
  final int meetingPointVersion;
  final bool isLocked;
  final String? legacyBatchId;

  // Hardened Join Security
  final String? joinToken;
  final DateTime? tokenExpiresAt;
  final bool isJoinOpen;
  final int redeemedCount;

  // Phase C: Completion Integrity
  final String? completionStatus; // completed_normally, completed_with_incident, cancelled_by_guide, aborted_safety
  final DateTime? completedAt;
  final String? completedBy; 
  final DateTime? completionVerifiedAt;
  final DateTime? reviewWindowEndsAt;
  final List<String> reviewEligibleTouristIds; // Immutable after session close
  final int incidentCount;
  final int criticalIncidentCount;
  final double sessionHealthScore; // 0-100 analytics
  final bool isReviewEnabled;

  TourSession({
    required this.sessionId,
    required this.guideId,
    this.touristIds = const [],
    required this.meetingPointName,
    required this.meetingPointLat,
    required this.meetingPointLng,
    this.vehicleId,
    this.vehicleNumber,
    this.status = 'initial',
    this.currentPhase = 'assembling',
    this.sessionCode,
    this.trackingEnabled = false,
    this.sosActive = false,
    this.startedAt,
    this.endedAt,
    this.maxTourists = 10,
    this.notes,
    this.lastGuideLat,
    this.lastGuideLng,
    this.lastVehicleLat,
    this.lastVehicleLng,
    this.meetingPointVersion = 0,
    this.isLocked = false,
    this.legacyBatchId,
    this.completionStatus,
    this.completedAt,
    this.completedBy,
    this.completionVerifiedAt,
    this.reviewWindowEndsAt,
    this.reviewEligibleTouristIds = const [],
    this.incidentCount = 0,
    this.criticalIncidentCount = 0,
    this.sessionHealthScore = 100.0,
    this.isReviewEnabled = true,
    this.joinToken,
    this.tokenExpiresAt,
    this.isJoinOpen = false,
    this.redeemedCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'guideId': guideId,
    'touristIds': touristIds,
    'meetingPointName': meetingPointName,
    'meetingPointLat': meetingPointLat,
    'meetingPointLng': meetingPointLng,
    'vehicleId': vehicleId,
    'vehicleNumber': vehicleNumber,
    'status': status,
    'currentPhase': currentPhase,
    'sessionCode': sessionCode,
    'trackingEnabled': trackingEnabled,
    'sosActive': sosActive,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'maxTourists': maxTourists,
    'notes': notes,
    'lastGuideLat': lastGuideLat,
    'lastGuideLng': lastGuideLng,
    'lastVehicleLat': lastVehicleLat,
    'lastVehicleLng': lastVehicleLng,
    'meetingPointVersion': meetingPointVersion,
    'isLocked': isLocked,
    'legacyBatchId': legacyBatchId,
    'completionStatus': completionStatus,
    'completedAt': completedAt?.toIso8601String(),
    'completedBy': completedBy,
    'completionVerifiedAt': completionVerifiedAt?.toIso8601String(),
    'reviewWindowEndsAt': reviewWindowEndsAt?.toIso8601String(),
    'reviewEligibleTouristIds': reviewEligibleTouristIds,
    'incidentCount': incidentCount,
    'criticalIncidentCount': criticalIncidentCount,
    'sessionHealthScore': sessionHealthScore,
    'isReviewEnabled': isReviewEnabled,
    'joinToken': joinToken,
    'tokenExpiresAt': tokenExpiresAt?.toIso8601String(),
    'isJoinOpen': isJoinOpen,
    'redeemedCount': redeemedCount,
  };

  factory TourSession.fromJson(Map<String, dynamic> json) => TourSession(
    sessionId: json['sessionId'],
    guideId: json['guideId'],
    touristIds: List<String>.from(json['touristIds'] ?? []),
    meetingPointName: json['meetingPointName'],
    meetingPointLat: (json['meetingPointLat'] ?? 0.0).toDouble(),
    meetingPointLng: (json['meetingPointLng'] ?? 0.0).toDouble(),
    vehicleId: json['vehicleId'],
    vehicleNumber: json['vehicleNumber'],
    status: json['status'] ?? 'initial',
    currentPhase: json['currentPhase'] ?? 'assembling',
    sessionCode: json['sessionCode'],
    trackingEnabled: json['trackingEnabled'] ?? false,
    sosActive: json['sosActive'] ?? false,
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
    endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    maxTourists: json['maxTourists'] ?? 10,
    notes: json['notes'],
    lastGuideLat: (json['lastGuideLat'])?.toDouble(),
    lastGuideLng: (json['lastGuideLng'])?.toDouble(),
    lastVehicleLat: (json['lastVehicleLat'])?.toDouble(),
    lastVehicleLng: (json['lastVehicleLng'])?.toDouble(),
    meetingPointVersion: json['meetingPointVersion'] ?? 0,
    isLocked: json['isLocked'] ?? false,
    legacyBatchId: json['legacyBatchId'],
    completionStatus: json['completionStatus'],
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    completedBy: json['completedBy'],
    completionVerifiedAt: json['completionVerifiedAt'] != null ? DateTime.parse(json['completionVerifiedAt']) : null,
    reviewWindowEndsAt: json['reviewWindowEndsAt'] != null ? DateTime.parse(json['reviewWindowEndsAt']) : null,
    reviewEligibleTouristIds: List<String>.from(json['reviewEligibleTouristIds'] ?? []),
    incidentCount: json['incidentCount'] ?? 0,
    criticalIncidentCount: json['criticalIncidentCount'] ?? 0,
    sessionHealthScore: (json['sessionHealthScore'] ?? 100.0).toDouble(),
    isReviewEnabled: json['isReviewEnabled'] ?? true,
    joinToken: json['joinToken'],
    tokenExpiresAt: json['tokenExpiresAt'] != null ? DateTime.parse(json['tokenExpiresAt']) : null,
    isJoinOpen: json['isJoinOpen'] ?? false,
    redeemedCount: json['redeemedCount'] ?? 0,
  );

  TourSession copyWith({
    String? sessionId,
    String? guideId,
    List<String>? touristIds,
    String? meetingPointName,
    double? meetingPointLat,
    double? meetingPointLng,
    String? vehicleId,
    String? vehicleNumber,
    String? status,
    String? currentPhase,
    String? sessionCode,
    bool? trackingEnabled,
    bool? sosActive,
    DateTime? startedAt,
    DateTime? endedAt,
    int? maxTourists,
    String? notes,
    double? lastGuideLat,
    double? lastGuideLng,
    double? lastVehicleLat,
    double? lastVehicleLng,
    int? meetingPointVersion,
    bool? isLocked,
    String? legacyBatchId,
    String? completionStatus,
    DateTime? completedAt,
    String? completedBy,
    DateTime? completionVerifiedAt,
    DateTime? reviewWindowEndsAt,
    List<String>? reviewEligibleTouristIds,
    int? incidentCount,
    int? criticalIncidentCount,
    double? sessionHealthScore,
    bool? isReviewEnabled,
    String? joinToken,
    DateTime? tokenExpiresAt,
    bool? isJoinOpen,
    int? redeemedCount,
  }) {
    return TourSession(
      sessionId: sessionId ?? this.sessionId,
      guideId: guideId ?? this.guideId,
      touristIds: touristIds ?? this.touristIds,
      meetingPointName: meetingPointName ?? this.meetingPointName,
      meetingPointLat: meetingPointLat ?? this.meetingPointLat,
      meetingPointLng: meetingPointLng ?? this.meetingPointLng,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      sessionCode: sessionCode ?? this.sessionCode,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      sosActive: sosActive ?? this.sosActive,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      maxTourists: maxTourists ?? this.maxTourists,
      notes: notes ?? this.notes,
      lastGuideLat: lastGuideLat ?? this.lastGuideLat,
      lastGuideLng: lastGuideLng ?? this.lastGuideLng,
      lastVehicleLat: lastVehicleLat ?? this.lastVehicleLat,
      lastVehicleLng: lastVehicleLng ?? this.lastVehicleLng,
      meetingPointVersion: meetingPointVersion ?? this.meetingPointVersion,
      isLocked: isLocked ?? this.isLocked,
      legacyBatchId: legacyBatchId ?? this.legacyBatchId,
      completionStatus: completionStatus ?? this.completionStatus,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      completionVerifiedAt: completionVerifiedAt ?? this.completionVerifiedAt,
      reviewWindowEndsAt: reviewWindowEndsAt ?? this.reviewWindowEndsAt,
      reviewEligibleTouristIds: reviewEligibleTouristIds ?? this.reviewEligibleTouristIds,
      incidentCount: incidentCount ?? this.incidentCount,
      criticalIncidentCount: criticalIncidentCount ?? this.criticalIncidentCount,
      sessionHealthScore: sessionHealthScore ?? this.sessionHealthScore,
      isReviewEnabled: isReviewEnabled ?? this.isReviewEnabled,
      joinToken: joinToken ?? this.joinToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      isJoinOpen: isJoinOpen ?? this.isJoinOpen,
      redeemedCount: redeemedCount ?? this.redeemedCount,
    );
  }
}

