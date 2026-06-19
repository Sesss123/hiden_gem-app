class TourLink {
  final String linkId;
  final String sessionId;
  final String guideId;
  final String touristId;
  final DateTime linkedAt;
  final String linkMethod; // 'qr' | 'code' | 'invite'
  final bool trackingConsent;
  final bool isActive;

  TourLink({
    required this.linkId,
    required this.sessionId,
    required this.guideId,
    required this.touristId,
    required this.linkedAt,
    this.linkMethod = 'qr',
    this.trackingConsent = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'linkId': linkId,
    'sessionId': sessionId,
    'guideId': guideId,
    'touristId': touristId,
    'linkedAt': linkedAt.toIso8601String(),
    'linkMethod': linkMethod,
    'trackingConsent': trackingConsent,
    'isActive': isActive,
  };

  factory TourLink.fromJson(Map<String, dynamic> json) => TourLink(
    linkId: json['linkId'],
    sessionId: json['sessionId'],
    guideId: json['guideId'],
    touristId: json['touristId'],
    linkedAt: DateTime.parse(json['linkedAt']),
    linkMethod: json['linkMethod'] ?? 'qr',
    trackingConsent: json['trackingConsent'] ?? false,
    isActive: json['isActive'] ?? true,
  );

  TourLink copyWith({
    String? linkId,
    String? sessionId,
    String? guideId,
    String? touristId,
    DateTime? linkedAt,
    String? linkMethod,
    bool? trackingConsent,
    bool? isActive,
  }) {
    return TourLink(
      linkId: linkId ?? this.linkId,
      sessionId: sessionId ?? this.sessionId,
      guideId: guideId ?? this.guideId,
      touristId: touristId ?? this.touristId,
      linkedAt: linkedAt ?? this.linkedAt,
      linkMethod: linkMethod ?? this.linkMethod,
      trackingConsent: trackingConsent ?? this.trackingConsent,
      isActive: isActive ?? this.isActive,
    );
  }
}
