class GuideAnalyticsSnapshot {
  final String guideId;
  final DateTime periodStart;
  final DateTime periodEnd;
  
  // High Level Metrics
  final int completedSessions;
  final int touristsServed;
  final double avgOverallRating;
  final double avgSafetyRating;
  final double avgCommunicationRating;
  
  // Safety & Operations
  final int incidentCount;
  final int criticalIncidentCount;
  final int sessionCompletionRate; // Percentage
  final int lateStartCount;
  final int cancelledSessionCount;
  final int incidentFreeStreak;
  final double responseTimeAvg; // Minutes
  
  // Marketing & Growth
  final int promoRedemptions;
  final double promoConversionRate;
  
  // Marketplace Summary Fields (Requested by UI)
  final int completedTours;
  final double ratingAverage;
  final int totalSafetyIncidents;
  
  // Trust Governance (Explainable Model)
  final int trustScore; // 0-100
  final String trustTier; // "Excellent", "Strong", "Watchlist", "Restricted"
  final Map<String, double> trustScoreFactors; // {docs, ratings, safety, incidents, completion, suspension}

  GuideAnalyticsSnapshot({
    required this.guideId,
    required this.periodStart,
    required this.periodEnd,
    required this.completedSessions,
    required this.touristsServed,
    required this.avgOverallRating,
    this.avgSafetyRating = 0.0,
    this.avgCommunicationRating = 0.0,
    this.incidentCount = 0,
    this.criticalIncidentCount = 0,
    this.sessionCompletionRate = 100,
    this.lateStartCount = 0,
    this.cancelledSessionCount = 0,
    this.incidentFreeStreak = 0,
    this.responseTimeAvg = 0.0,
    this.promoRedemptions = 0,
    this.promoConversionRate = 0.0,
    this.completedTours = 0,
    this.ratingAverage = 0.0,
    this.totalSafetyIncidents = 0,
    this.trustScore = 100,
    this.trustTier = 'Strong',
    this.trustScoreFactors = const {},
  });

  Map<String, dynamic> toJson() => {
    'guideId': guideId,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'completedSessions': completedSessions,
    'touristsServed': touristsServed,
    'avgOverallRating': avgOverallRating,
    'avgSafetyRating': avgSafetyRating,
    'avgCommunicationRating': avgCommunicationRating,
    'incidentCount': incidentCount,
    'criticalIncidentCount': criticalIncidentCount,
    'sessionCompletionRate': sessionCompletionRate,
    'lateStartCount': lateStartCount,
    'cancelledSessionCount': cancelledSessionCount,
    'incidentFreeStreak': incidentFreeStreak,
    'responseTimeAvg': responseTimeAvg,
    'promoRedemptions': promoRedemptions,
    'promoConversionRate': promoConversionRate,
    'completedTours': completedTours,
    'ratingAverage': ratingAverage,
    'totalSafetyIncidents': totalSafetyIncidents,
    'trustScore': trustScore,
    'trustTier': trustTier,
    'trustScoreFactors': trustScoreFactors,
  };

  factory GuideAnalyticsSnapshot.fromJson(Map<String, dynamic> json) => GuideAnalyticsSnapshot(
    guideId: json['guideId'],
    periodStart: DateTime.parse(json['periodStart']),
    periodEnd: DateTime.parse(json['periodEnd']),
    completedSessions: json['completedSessions'] ?? 0,
    touristsServed: json['touristsServed'] ?? 0,
    avgOverallRating: (json['avgOverallRating'] ?? 0.0).toDouble(),
    avgSafetyRating: (json['avgSafetyRating'] ?? 0.0).toDouble(),
    avgCommunicationRating: (json['avgCommunicationRating'] ?? 0.0).toDouble(),
    incidentCount: json['incidentCount'] ?? 0,
    criticalIncidentCount: json['criticalIncidentCount'] ?? 0,
    sessionCompletionRate: json['sessionCompletionRate'] ?? 100,
    lateStartCount: json['lateStartCount'] ?? 0,
    cancelledSessionCount: json['cancelledSessionCount'] ?? 0,
    incidentFreeStreak: json['incidentFreeStreak'] ?? 0,
    responseTimeAvg: (json['responseTimeAvg'] ?? 0.0).toDouble(),
    promoRedemptions: json['promoRedemptions'] ?? 0,
    promoConversionRate: (json['promoConversionRate'] ?? 0.0).toDouble(),
    completedTours: json['completedTours'] ?? 0,
    ratingAverage: (json['ratingAverage'] ?? 0.0).toDouble(),
    totalSafetyIncidents: json['totalSafetyIncidents'] ?? 0,
    trustScore: json['trustScore'] ?? 100,
    trustTier: json['trustTier'] ?? 'Strong',
    trustScoreFactors: Map<String, double>.from(json['trustScoreFactors'] ?? {}),
  );
}
