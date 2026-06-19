class TourPackage {
  final String packageId;
  final String ownerId; // guideId or operatorId
  final String ownerType; // guide, operator
  
  // Content
  final String title;
  final String description;
  final String? detailedItinerary;
  final List<String> photos;
  
  // Rules
  final List<String> regions;
  final int durationHours;
  final int maxGuests;
  final double price;
  final String currency;
  final bool includesVehicle;
  final List<String> inclusions;
  final List<String> exclusions;
  
  // Status
  final bool isActive;
  final bool isFeatured;
  final int bookingsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  TourPackage({
    required this.packageId,
    required this.ownerId,
    required this.ownerType,
    required this.title,
    required this.description,
    this.detailedItinerary,
    this.photos = const [],
    this.regions = const [],
    required this.durationHours,
    required this.maxGuests,
    required this.price,
    this.currency = 'USD',
    this.includesVehicle = false,
    this.inclusions = const [],
    this.exclusions = const [],
    this.isActive = true,
    this.isFeatured = false,
    this.bookingsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'ownerId': ownerId,
    'ownerType': ownerType,
    'title': title,
    'description': description,
    'detailedItinerary': detailedItinerary,
    'photos': photos,
    'regions': regions,
    'durationHours': durationHours,
    'maxGuests': maxGuests,
    'price': price,
    'currency': currency,
    'includesVehicle': includesVehicle,
    'inclusions': inclusions,
    'exclusions': exclusions,
    'isActive': isActive,
    'isFeatured': isFeatured,
    'bookingsCount': bookingsCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TourPackage.fromJson(Map<String, dynamic> json) => TourPackage(
    packageId: json['packageId'],
    ownerId: json['ownerId'],
    ownerType: json['ownerType'],
    title: json['title'],
    description: json['description'],
    detailedItinerary: json['detailedItinerary'],
    photos: List<String>.from(json['photos'] ?? []),
    regions: List<String>.from(json['regions'] ?? []),
    durationHours: json['durationHours'] ?? 4,
    maxGuests: json['maxGuests'] ?? 2,
    price: (json['price'] ?? 0.0).toDouble(),
    currency: json['currency'] ?? 'USD',
    includesVehicle: json['includesVehicle'] ?? false,
    inclusions: List<String>.from(json['inclusions'] ?? []),
    exclusions: List<String>.from(json['exclusions'] ?? []),
    isActive: json['isActive'] ?? true,
    isFeatured: json['isFeatured'] ?? false,
    bookingsCount: json['bookingsCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
