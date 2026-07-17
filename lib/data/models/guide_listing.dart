import 'guide_availability.dart';

class GuideListing {
  final String listingId;
  final String guideId;
  final String displayName;
  final String? bio;
  final String? profilePhotoUrl;
  final String? licenseNumber;
  final bool isInsured; // Platform-backed verified & insured trust badge (Pro/Elite)
  final List<String> coverPhotos;
  
  // Categorization
  final String guideCategory; // chauffeur, site, adventure, etc.
  final List<String> languages;
  final List<String> specializations; // heritage, wildlife, photography
  final List<String> regions; // central, southern, etc.

  // Fixed, filterable tour-type taxonomy (booleans, not a List<String>, so
  // each is an independent equality filter — Firestore allows only one
  // arrayContains per query, and regions/languages already use theirs).
  final bool doesBoatSafari;
  final bool doesWildlifeSafari;
  final bool doesHiking;
  final bool doesDiving;
  final bool doesCulturalTours;

  // Public Performance
  final double ratingAverage;
  final int reviewCount;
  final String trustTierPublic; // Excellent, Strong, etc.
  final int yearsExperience;
  
  // Service Attributes
  final bool vehicleAvailable;
  final String? vehicleType;
  final String? vehicleImageUrl;
  final double hourlyRate;
  final String currency;
  
  // Marketplace Status
  final String status; // draft, pending_review, published, paused, archived
  final String moderationStatus; // pending, approved, rejected
  final String? moderationNotes;
  final bool isFlagged;
  
  // Availability
  final GuideAvailability? availability;
  
  final bool isFeatured;
  final DateTime? featuredUntil;
  // Guide-settable signal of intent to be featured — NOT a trust field
  // itself (unlike isFeatured), so it's safe for clients to write freely.
  // An admin (or a future automated job that checks the guide's real
  // featuredListings entitlement) reads this queue and grants isFeatured
  // via GuideListingController::setFeatured server-side.
  final bool isFeaturedRequested;
  final int profileViews;
  final int bookingRequestsCount;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  GuideListing({
    required this.listingId,
    required this.guideId,
    required this.displayName,
    this.bio,
    this.profilePhotoUrl,
    this.licenseNumber,
    this.isInsured = false,
    this.coverPhotos = const [],
    required this.guideCategory,
    this.languages = const ['English'],
    this.specializations = const [],
    this.regions = const [],
    this.doesBoatSafari = false,
    this.doesWildlifeSafari = false,
    this.doesHiking = false,
    this.doesDiving = false,
    this.doesCulturalTours = false,
    this.ratingAverage = 5.0,
    this.reviewCount = 0,
    this.trustTierPublic = 'Strong',
    this.yearsExperience = 1,
    this.vehicleAvailable = false,
    this.vehicleType,
    this.vehicleImageUrl,
    this.hourlyRate = 0.0,
    this.currency = 'USD',
    this.status = 'draft',
    this.moderationStatus = 'pending',
    this.moderationNotes,
    this.isFlagged = false,
    this.availability,
    this.isFeatured = false,
    this.featuredUntil,
    this.isFeaturedRequested = false,
    this.profileViews = 0,
    this.bookingRequestsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'listingId': listingId,
    'guideId': guideId,
    'displayName': displayName,
    'bio': bio,
    'profilePhotoUrl': profilePhotoUrl,
    'licenseNumber': licenseNumber,
    'isInsured': isInsured,
    'coverPhotos': coverPhotos,
    'guideCategory': guideCategory,
    'languages': languages,
    'specializations': specializations,
    'regions': regions,
    'doesBoatSafari': doesBoatSafari,
    'doesWildlifeSafari': doesWildlifeSafari,
    'doesHiking': doesHiking,
    'doesDiving': doesDiving,
    'doesCulturalTours': doesCulturalTours,
    'ratingAverage': ratingAverage,
    'reviewCount': reviewCount,
    'trustTierPublic': trustTierPublic,
    'yearsExperience': yearsExperience,
    'vehicleAvailable': vehicleAvailable,
    'vehicleType': vehicleType,
    'vehicleImageUrl': vehicleImageUrl,
    'hourlyRate': hourlyRate,
    'currency': currency,
    'status': status,
    'moderationStatus': moderationStatus,
    'moderationNotes': moderationNotes,
    'isFlagged': isFlagged,
    'availability': availability?.toJson(),
    'isFeatured': isFeatured,
    'featuredUntil': featuredUntil?.toIso8601String(),
    'isFeaturedRequested': isFeaturedRequested,
    'profileViews': profileViews,
    'bookingRequestsCount': bookingRequestsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory GuideListing.fromJson(Map<String, dynamic> json) => GuideListing(
    listingId: json['listingId'],
    guideId: json['guideId'],
    displayName: json['displayName'],
    bio: json['bio'],
    profilePhotoUrl: json['profilePhotoUrl'],
    licenseNumber: json['licenseNumber'],
    isInsured: json['isInsured'] ?? false,
    coverPhotos: List<String>.from(json['coverPhotos'] ?? []),
    guideCategory: json['guideCategory'],
    languages: List<String>.from(json['languages'] ?? []),
    specializations: List<String>.from(json['specializations'] ?? []),
    regions: List<String>.from(json['regions'] ?? []),
    doesBoatSafari: json['doesBoatSafari'] ?? false,
    doesWildlifeSafari: json['doesWildlifeSafari'] ?? false,
    doesHiking: json['doesHiking'] ?? false,
    doesDiving: json['doesDiving'] ?? false,
    doesCulturalTours: json['doesCulturalTours'] ?? false,
    ratingAverage: (json['ratingAverage'] ?? 5.0).toDouble(),
    reviewCount: json['reviewCount'] ?? 0,
    trustTierPublic: json['trustTierPublic'] ?? 'Strong',
    yearsExperience: json['yearsExperience'] ?? 1,
    vehicleAvailable: json['vehicleAvailable'] ?? false,
    vehicleType: json['vehicleType'],
    vehicleImageUrl: json['vehicleImageUrl'],
    hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
    currency: json['currency'] ?? 'USD',
    status: json['status'] ?? 'draft',
    moderationStatus: json['moderationStatus'] ?? 'pending',
    moderationNotes: json['moderationNotes'],
    isFlagged: json['isFlagged'] ?? false,
    availability: json['availability'] != null ? GuideAvailability.fromJson(json['availability']) : null,
    isFeatured: json['isFeatured'] ?? false,
    featuredUntil: json['featuredUntil'] != null ? DateTime.parse(json['featuredUntil']) : null,
    isFeaturedRequested: json['isFeaturedRequested'] ?? false,
    profileViews: json['profileViews'] ?? 0,
    bookingRequestsCount: json['bookingRequestsCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  /// Reads a tour-type boolean by its field key (e.g. 'doesBoatSafari').
  /// Single place that maps TourType.fieldKey -> the actual field, so
  /// screens/repositories don't each hand-roll their own switch statement
  /// that has to be kept in sync with the 5 boolean fields above.
  bool hasTourType(String fieldKey) {
    switch (fieldKey) {
      case 'doesBoatSafari': return doesBoatSafari;
      case 'doesWildlifeSafari': return doesWildlifeSafari;
      case 'doesHiking': return doesHiking;
      case 'doesDiving': return doesDiving;
      case 'doesCulturalTours': return doesCulturalTours;
      default: return false;
    }
  }
}
