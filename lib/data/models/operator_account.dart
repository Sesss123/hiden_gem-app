class OperatorAccount {
  final String operatorId;
  final String companyName;
  final String? bio;
  final String ownerUserId;
  final List<String> teamGuideIds;
  final Map<String, String> teamRoles; // {userId: role} - owner, manager, dispatcher, analyst
  final List<String> vehicleIds;
  
  // Registration
  final String brNumber; // Business Registration
  final bool isVerified;
  final String status; // active, suspended, under_review
  
  // Branding
  final String? logoUrl;
  final Map<String, String> brandingAssets; // {primaryColor, secondaryColor, etc.}
  final String website;
  final String supportEmail;
  
  // Monetization
  final String subscriptionPlan; // Starter, Growth, Enterprise
  final DateTime? subExpiresAt;
  
  // Stats
  final int totalMissionsCompleted;
  final double averageTeamRating;
  final int currentActiveSessions;

  OperatorAccount({
    required this.operatorId,
    required this.companyName,
    this.bio,
    required this.ownerUserId,
    this.teamGuideIds = const [],
    this.teamRoles = const {},
    this.vehicleIds = const [],
    required this.brNumber,
    this.isVerified = false,
    this.status = 'active',
    this.logoUrl,
    this.brandingAssets = const {},
    this.website = '',
    required this.supportEmail,
    required this.subscriptionPlan,
    this.subExpiresAt,
    this.totalMissionsCompleted = 0,
    this.averageTeamRating = 5.0,
    this.currentActiveSessions = 0,
  });

  Map<String, dynamic> toJson() => {
    'operatorId': operatorId,
    'companyName': companyName,
    'bio': bio,
    'ownerUserId': ownerUserId,
    'teamGuideIds': teamGuideIds,
    'teamRoles': teamRoles,
    'vehicleIds': vehicleIds,
    'brNumber': brNumber,
    'isVerified': isVerified,
    'status': status,
    'logoUrl': logoUrl,
    'brandingAssets': brandingAssets,
    'website': website,
    'supportEmail': supportEmail,
    'subscriptionPlan': subscriptionPlan,
    'subExpiresAt': subExpiresAt?.toIso8601String(),
    'totalMissionsCompleted': totalMissionsCompleted,
    'averageTeamRating': averageTeamRating,
    'currentActiveSessions': currentActiveSessions,
  };

  factory OperatorAccount.fromJson(Map<String, dynamic> json) => OperatorAccount(
    operatorId: json['operatorId'],
    companyName: json['companyName'],
    bio: json['bio'],
    ownerUserId: json['ownerUserId'],
    teamGuideIds: List<String>.from(json['teamGuideIds'] ?? []),
    teamRoles: Map<String, String>.from(json['teamRoles'] ?? {}),
    vehicleIds: List<String>.from(json['vehicleIds'] ?? []),
    brNumber: json['brNumber'],
    isVerified: json['isVerified'] ?? false,
    status: json['status'] ?? 'active',
    logoUrl: json['logoUrl'],
    brandingAssets: Map<String, String>.from(json['brandingAssets'] ?? {}),
    website: json['website'] ?? '',
    supportEmail: json['supportEmail'],
    subscriptionPlan: json['subscriptionPlan'] ?? 'Starter',
    subExpiresAt: json['subExpiresAt'] != null ? DateTime.parse(json['subExpiresAt']) : null,
    totalMissionsCompleted: json['totalMissionsCompleted'] ?? 0,
    averageTeamRating: (json['averageTeamRating'] ?? 5.0).toDouble(),
    currentActiveSessions: json['currentActiveSessions'] ?? 0,
  );
}
