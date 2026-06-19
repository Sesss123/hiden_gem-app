import 'guide_status.dart';
import 'guide_profile.dart';

class UserProfile {
  String uid; // Made non-final for flexibility during migrations
  List<String> preferredStyles;
  double avgBudgetLkr;
  List<String> visitedPlaces;
  String vibe; // "luxury", "explorer", "photographer", "budget"
  int totalTripsGenerated;
  String? languageCode;
  String? profileImagePath;
  List<String> sosContacts;
  String vibeTheme; // "ceylon_blue" | "jungle_green" | "sunset_red" | "lotus_pink" | "midnight_gold"
  String themeMode; // "system", "light", "dark"
  List<String> tripHistory; // past destinations for AI memory
  bool showScreenshotButton; // Whether to show the floating camera button
  bool hasAgreedToTerms; // Whether the user accepted Privacy Policy & Terms
  bool hasCompletedOnboarding; // Whether the user completed the onboarding presentation
  String role; // "user", "admin", "guide_pending", "guide_approved"
  bool isPremium;
  String? premiumPlan; // "monthly", "yearly"
  String? premiumSource; // "app_store", "google_play"
  DateTime? premiumStartedAt;
  DateTime? premiumExpiresAt;
  bool trialUsed;
  List<String> ownedArPacks;
  String? premiumSignature; // HMAC proof of expiry (Point 5)
  
  // Phase A: Production Trust Layer
  GuideStatus guideStatus;
  GuideProfile? guideProfile;
  bool hasMigratedToZenith;

  // Legacy Fields (Retained for migration)
  String? guideLicense;
  String? guideBio;
  bool isGuideApproved;
  int totalTouristsServed;
  String? currentBatchId; 

  // Tourism SaaS Limits Tracking
  int aiTripsUsedThisMonth;
  int arSessionsUsedThisMonth;
  int offlineDownloadsUsed;
  DateTime? usageResetDate;

  UserProfile({
    required this.uid,
    required this.preferredStyles,
    required this.avgBudgetLkr,
    required this.visitedPlaces,
    required this.vibe,
    this.totalTripsGenerated = 0,
    this.languageCode,
    this.profileImagePath,
    List<String>? sosContacts,
    this.vibeTheme = 'ceylon_blue',
    this.themeMode = 'system',
    List<String>? tripHistory,
    this.showScreenshotButton = true,
    this.hasAgreedToTerms = false,
    this.hasCompletedOnboarding = false,
    this.role = 'user',
    this.isPremium = false,
    this.premiumPlan,
    this.premiumSource,
    this.premiumStartedAt,
    this.premiumExpiresAt,
    this.trialUsed = false,
    List<String>? ownedArPacks,
    this.guideStatus = GuideStatus.none,
    this.guideProfile,
    this.hasMigratedToZenith = false,
    this.guideLicense,
    this.guideBio,
    this.isGuideApproved = false,
    this.totalTouristsServed = 0,
    this.currentBatchId,
    this.aiTripsUsedThisMonth = 0,
    this.arSessionsUsedThisMonth = 0,
    this.offlineDownloadsUsed = 0,
    this.usageResetDate,
    this.premiumSignature,
  })  : sosContacts = sosContacts ?? [],
        tripHistory = tripHistory ?? [],
        ownedArPacks = ownedArPacks ?? [];

  factory UserProfile.defaultProfile({String uid = 'TEMP'}) {
    return UserProfile(
      uid: uid,
      preferredStyles: ['Adventure', 'Nature'],
      avgBudgetLkr: 50000,
      visitedPlaces: [],
      vibe: 'explorer',
      vibeTheme: 'ceylon_blue',
      themeMode: 'system',
      showScreenshotButton: true,
      hasAgreedToTerms: false,
      hasCompletedOnboarding: false,
      role: 'user',
      isPremium: false,
      trialUsed: false,
      ownedArPacks: [],
      aiTripsUsedThisMonth: 0,
      arSessionsUsedThisMonth: 0,
      offlineDownloadsUsed: 0,
      usageResetDate: DateTime.now().add(const Duration(days: 30)),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'preferredStyles': preferredStyles,
        'avgBudgetLkr': avgBudgetLkr,
        'visitedPlaces': visitedPlaces,
        'vibe': vibe,
        'totalTripsGenerated': totalTripsGenerated,
        'languageCode': languageCode,
        'profileImagePath': profileImagePath,
        'sosContacts': sosContacts,
        'vibeTheme': vibeTheme,
        'themeMode': themeMode,
        'tripHistory': tripHistory,
        'showScreenshotButton': showScreenshotButton,
        'hasAgreedToTerms': hasAgreedToTerms,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'role': role,
        'isPremium': isPremium,
        'premiumPlan': premiumPlan,
        'premiumSource': premiumSource,
        'premiumStartedAt': premiumStartedAt?.toIso8601String(),
        'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
        'trialUsed': trialUsed,
        'ownedArPacks': ownedArPacks,
        'guideStatus': guideStatus.name,
        'guideProfile': guideProfile?.toJson(),
        'hasMigratedToZenith': hasMigratedToZenith,
        'guideLicense': guideLicense,
        'guideBio': guideBio,
        'isGuideApproved': isGuideApproved,
        'totalTouristsServed': totalTouristsServed,
        'currentBatchId': currentBatchId,
        'aiTripsUsedThisMonth': aiTripsUsedThisMonth,
        'arSessionsUsedThisMonth': arSessionsUsedThisMonth,
        'offlineDownloadsUsed': offlineDownloadsUsed,
        'usageResetDate': usageResetDate?.toIso8601String(),
        'premiumSignature': premiumSignature,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'] ?? 'N/A',
        preferredStyles: List<String>.from(json['preferredStyles'] ?? []),
        avgBudgetLkr: (json['avgBudgetLkr'] ?? 50000).toDouble(),
        visitedPlaces: List<String>.from(json['visitedPlaces'] ?? []),
        vibe: json['vibe'] ?? 'explorer',
        totalTripsGenerated: json['totalTripsGenerated'] ?? 0,
        languageCode: json['languageCode'],
        profileImagePath: json['profileImagePath'],
        sosContacts: List<String>.from(json['sosContacts'] ?? []),
        vibeTheme: json['vibeTheme'] ?? 'ceylon_blue',
        themeMode: json['themeMode'] ?? 'system',
        tripHistory: List<String>.from(json['tripHistory'] ?? []),
        showScreenshotButton: json['showScreenshotButton'] ?? true,
        hasAgreedToTerms: json['hasAgreedToTerms'] ?? false,
        hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
        role: json['role'] ?? 'user',
        isPremium: json['isPremium'] ?? false,
        premiumPlan: json['premiumPlan'],
        premiumSource: json['premiumSource'],
        premiumStartedAt: json['premiumStartedAt'] != null ? DateTime.parse(json['premiumStartedAt']) : null,
        premiumExpiresAt: json['premiumExpiresAt'] != null ? DateTime.parse(json['premiumExpiresAt']) : null,
        trialUsed: json['trialUsed'] ?? false,
        ownedArPacks: List<String>.from(json['ownedArPacks'] ?? []),
        guideStatus: GuideStatus.values.byName(json['guideStatus'] ?? 'none'),
        guideProfile: json['guideProfile'] != null ? GuideProfile.fromJson(json['guideProfile']) : null,
        hasMigratedToZenith: json['hasMigratedToZenith'] ?? false,
        guideLicense: json['guideLicense'],
        guideBio: json['guideBio'],
        isGuideApproved: json['isGuideApproved'] ?? false,
        totalTouristsServed: json['totalTouristsServed'] ?? 0,
        currentBatchId: json['currentBatchId'],
        aiTripsUsedThisMonth: json['aiTripsUsedThisMonth'] ?? 0,
        arSessionsUsedThisMonth: json['arSessionsUsedThisMonth'] ?? 0,
        offlineDownloadsUsed: json['offlineDownloadsUsed'] ?? 0,
        usageResetDate: json['usageResetDate'] != null ? DateTime.parse(json['usageResetDate']) : null,
        premiumSignature: json['premiumSignature'],
      );
}
