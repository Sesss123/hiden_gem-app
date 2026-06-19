class RecommendationProfile {
  final String profileId;
  final String userId;
  
  // Preferences
  final List<String> preferredLanguages;
  final List<String> interests; // heritage, food, nature, adventure, religious
  final String tripStyle; // relaxed, fast-paced, luxury, budget, eco-friendly
  final String budgetRange; // economy, standard, premium
  
  // Group Context
  final String groupType; // solo, couple, family_with_kids, seniors, business_group
  final List<String> mobilityNeeds; // wheelchair, oxygen, low_walking
  
  // Geographics
  final List<String> preferredRegions;
  final List<String> excludedPlaces;
  
  // Discovery
  final String? lastMatchId;
  final Map<String, List<String>> explanationTags; // {guideId: [tags]}
  final DateTime updatedAt;

  RecommendationProfile({
    required this.profileId,
    required this.userId,
    this.preferredLanguages = const ['English'],
    this.interests = const [],
    this.tripStyle = 'standard',
    this.budgetRange = 'standard',
    this.groupType = 'solo',
    this.mobilityNeeds = const [],
    this.preferredRegions = const [],
    this.excludedPlaces = const [],
    this.lastMatchId,
    this.explanationTags = const {},
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'userId': userId,
    'preferredLanguages': preferredLanguages,
    'interests': interests,
    'tripStyle': tripStyle,
    'budgetRange': budgetRange,
    'groupType': groupType,
    'mobilityNeeds': mobilityNeeds,
    'preferredRegions': preferredRegions,
    'excludedPlaces': excludedPlaces,
    'lastMatchId': lastMatchId,
    'explanationTags': explanationTags,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RecommendationProfile.fromJson(Map<String, dynamic> json) => RecommendationProfile(
    profileId: json['profileId'],
    userId: json['userId'],
    preferredLanguages: List<String>.from(json['preferredLanguages'] ?? []),
    interests: List<String>.from(json['interests'] ?? []),
    tripStyle: json['tripStyle'] ?? 'standard',
    budgetRange: json['budgetRange'] ?? 'standard',
    groupType: json['groupType'] ?? 'solo',
    mobilityNeeds: List<String>.from(json['mobilityNeeds'] ?? []),
    preferredRegions: List<String>.from(json['preferredRegions'] ?? []),
    excludedPlaces: List<String>.from(json['excludedPlaces'] ?? []),
    lastMatchId: json['lastMatchId'],
    explanationTags: (json['explanationTags'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, List<String>.from(v)),
    ) ?? {},
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
