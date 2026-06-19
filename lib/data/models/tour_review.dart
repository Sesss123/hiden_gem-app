class TourReview {
  final String reviewId;
  final String sessionId;
  final String guideId;
  final String touristId;
  
  // Rating Dimensions (1-5)
  final double overallRating;
  final double knowledgeRating;
  final double communicationRating;
  final double punctualityRating;
  final double safetyRating;
  final double friendlinessRating;
  
  final String comment;
  final DateTime createdAt;
  
  // Integrity & Moderation
  final bool isVerifiedSession; // linked via code/QR
  final bool reviewWindowValidated; // submitted within X days
  final String? submittedFromDeviceHash; // anti-spam
  
  final String moderationStatus; // active, flagged, hidden, under_review
  final bool isFlagged;
  final String? flagReason;
  final String? hiddenByAdmin;
  final String? hiddenReason;
  
  final bool isEdited;
  final DateTime? editedAt;

  TourReview({
    required this.reviewId,
    required this.sessionId,
    required this.guideId,
    required this.touristId,
    required this.overallRating,
    this.knowledgeRating = 0.0,
    this.communicationRating = 0.0,
    this.punctualityRating = 0.0,
    this.safetyRating = 0.0,
    this.friendlinessRating = 0.0,
    this.comment = '',
    required this.createdAt,
    this.isVerifiedSession = false,
    this.reviewWindowValidated = false,
    this.submittedFromDeviceHash,
    this.moderationStatus = 'active',
    this.isFlagged = false,
    this.flagReason,
    this.hiddenByAdmin,
    this.hiddenReason,
    this.isEdited = false,
    this.editedAt,
  });

  Map<String, dynamic> toJson() => {
    'reviewId': reviewId,
    'sessionId': sessionId,
    'guideId': guideId,
    'touristId': touristId,
    'overallRating': overallRating,
    'knowledgeRating': knowledgeRating,
    'communicationRating': communicationRating,
    'punctualityRating': punctualityRating,
    'safetyRating': safetyRating,
    'friendlinessRating': friendlinessRating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'isVerifiedSession': isVerifiedSession,
    'reviewWindowValidated': reviewWindowValidated,
    'submittedFromDeviceHash': submittedFromDeviceHash,
    'moderationStatus': moderationStatus,
    'isFlagged': isFlagged,
    'flagReason': flagReason,
    'hiddenByAdmin': hiddenByAdmin,
    'hiddenReason': hiddenReason,
    'isEdited': isEdited,
    'editedAt': editedAt?.toIso8601String(),
  };

  factory TourReview.fromJson(Map<String, dynamic> json) => TourReview(
    reviewId: json['reviewId'],
    sessionId: json['sessionId'],
    guideId: json['guideId'],
    touristId: json['touristId'],
    overallRating: (json['overallRating'] ?? 0.0).toDouble(),
    knowledgeRating: (json['knowledgeRating'] ?? 0.0).toDouble(),
    communicationRating: (json['communicationRating'] ?? 0.0).toDouble(),
    punctualityRating: (json['punctualityRating'] ?? 0.0).toDouble(),
    safetyRating: (json['safetyRating'] ?? 0.0).toDouble(),
    friendlinessRating: (json['friendlinessRating'] ?? 0.0).toDouble(),
    comment: json['comment'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    isVerifiedSession: json['isVerifiedSession'] ?? false,
    reviewWindowValidated: json['reviewWindowValidated'] ?? false,
    submittedFromDeviceHash: json['submittedFromDeviceHash'],
    moderationStatus: json['moderationStatus'] ?? 'active',
    isFlagged: json['isFlagged'] ?? false,
    flagReason: json['flagReason'],
    hiddenByAdmin: json['hiddenByAdmin'],
    hiddenReason: json['hiddenReason'],
    isEdited: json['isEdited'] ?? false,
    editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
  );
}
