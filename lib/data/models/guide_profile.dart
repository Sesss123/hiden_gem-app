class GuideProfile {
  final String? licenseNumber;
  final String? bio;
  final String? category; // National, Provincial, Site
  final int experienceYears;
  final List<String> languages;
  final bool verifiedBadge;
  final double ratingAverage;
  final int travelersServed;
  final bool isBroadcasting;
  final String? licenseDocUrl;
  final String? nicDocUrl;
  final String? selfieDocUrl;

  GuideProfile({
    this.licenseNumber,
    this.bio,
    this.category,
    this.experienceYears = 0,
    this.languages = const ['English', 'Sinhala'],
    this.verifiedBadge = false,
    this.ratingAverage = 5.0,
    this.travelersServed = 0,
    this.isBroadcasting = false,
    this.licenseDocUrl,
    this.nicDocUrl,
    this.selfieDocUrl,
  });

  Map<String, dynamic> toJson() => {
    'licenseNumber': licenseNumber,
    'bio': bio,
    'category': category,
    'experienceYears': experienceYears,
    'languages': languages,
    'verifiedBadge': verifiedBadge,
    'ratingAverage': ratingAverage,
    'travelersServed': travelersServed,
    'isBroadcasting': isBroadcasting,
    'licenseDocUrl': licenseDocUrl,
    'nicDocUrl': nicDocUrl,
    'selfieDocUrl': selfieDocUrl,
  };

  factory GuideProfile.fromJson(Map<String, dynamic> json) => GuideProfile(
    licenseNumber: json['licenseNumber'],
    bio: json['bio'],
    category: json['category'],
    experienceYears: json['experienceYears'] ?? 0,
    languages: List<String>.from(json['languages'] ?? ['English', 'Sinhala']),
    verifiedBadge: json['verifiedBadge'] ?? false,
    ratingAverage: (json['ratingAverage'] ?? 5.0).toDouble(),
    travelersServed: json['travelersServed'] ?? 0,
    isBroadcasting: json['isBroadcasting'] ?? false,
    licenseDocUrl: json['licenseDocUrl'],
    nicDocUrl: json['nicDocUrl'],
    selfieDocUrl: json['selfieDocUrl'],
  );

  GuideProfile copyWith({
    String? licenseNumber,
    String? bio,
    String? category,
    int? experienceYears,
    List<String>? languages,
    bool? verifiedBadge,
    double? ratingAverage,
    int? travelersServed,
    bool? isBroadcasting,
    String? licenseDocUrl,
    String? nicDocUrl,
    String? selfieDocUrl,
  }) {
    return GuideProfile(
      licenseNumber: licenseNumber ?? this.licenseNumber,
      bio: bio ?? this.bio,
      category: category ?? this.category,
      experienceYears: experienceYears ?? this.experienceYears,
      languages: languages ?? this.languages,
      verifiedBadge: verifiedBadge ?? this.verifiedBadge,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      travelersServed: travelersServed ?? this.travelersServed,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      licenseDocUrl: licenseDocUrl ?? this.licenseDocUrl,
      nicDocUrl: nicDocUrl ?? this.nicDocUrl,
      selfieDocUrl: selfieDocUrl ?? this.selfieDocUrl,
    );
  }
}
