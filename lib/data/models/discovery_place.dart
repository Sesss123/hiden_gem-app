import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/encryption_util.dart';
import 'ar_artifact.dart';

class PlaceImageModel {
  final int id;
  final String thumbPath;
  final String fullPath;
  final bool isCover;

  const PlaceImageModel({
    required this.id,
    required this.thumbPath,
    required this.fullPath,
    this.isCover = false,
  });

  factory PlaceImageModel.fromJson(Map<String, dynamic> json) {
    return PlaceImageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      thumbPath: json['thumbPath'] as String? ?? json['thumb_path'] as String? ?? '',
      fullPath: json['fullPath'] as String? ?? json['full_path'] as String? ?? '',
      isCover: json['isCover'] as bool? ?? json['is_cover'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thumbPath': thumbPath,
      'thumb_path': thumbPath,
      'fullPath': fullPath,
      'full_path': fullPath,
      'isCover': isCover,
      'is_cover': isCover,
    };
  }
}

class DiscoveryPlace {

  final String id;
  final String name;
  final String district;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String ticketRange;
  final String imageUrl;
  
  final String roadType;
  final String vehicleAccess;
  final List<String> riskTags;
  final String parkingRange;
  final String bestTime;
  final List<String> facilities;
  final String openingHours;

  // Curated travel/safety/access field notes (Laravel `places` table columns
  // that were previously dropped by this model even though the backend
  // already sends them — see PlaceResource.php).
  final String mobileSignal;
  final String roadCondition;
  final String activities;
  final String touristPopularity;
  final String familyFriendly;
  final String budgetCategory;
  final String toilets;
  final String foodNearby;
  final String wheelchairAccess;
  final String campingAllowed;
  final String safetyLevel;
  final String wildlifeHazard;
  final String guideRequired;
  final String rainSensitivity;
  final String monsoonNote;
  final String heightM;
  final String lengthKm;
  final String surfing;

  final String updatedAt;
  final int syncVersion;
  final bool arSupported;
  final int arTier;
  final String arBrandName;
  final String arModelUrl;
  final String arHistoricalModelUrl;
  final double arModelScale;
  final String historicalPeriod;
  final double arFileSizeMb;
  final String arAuthor;
  final int arContentVersion;
  final String audioUrlSi;
  final String audioUrlEn;
  final String fallbackVideoUrl;
  final List<dynamic> arHotspots;
  final List<ARArtifact> arArtifacts;
  
  final String geohash;
  final List<PlaceImageModel> images;

  // Prefer the cover image's 1080px webp (fullPath) over the 400px
  // thumb `imageUrl` — for large display contexts like a details-screen
  // hero banner, where the thumb noticeably upscales and blurs.
  String get heroImageUrl {
    if (images.isEmpty) return imageUrl;
    final cover = images.firstWhere(
      (img) => img.isCover,
      orElse: () => images.first,
    );
    return cover.fullPath.isNotEmpty ? cover.fullPath : imageUrl;
  }

  double distanceKm;
  String aiReason;

  DiscoveryPlace({
    required this.id,
    required this.name,
    required this.district,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.ticketRange,
    required this.roadType,
    required this.vehicleAccess,
    required this.riskTags,
    required this.parkingRange,
    required this.bestTime,
    required this.facilities,
    this.openingHours = '',
    this.mobileSignal = '',
    this.roadCondition = '',
    this.activities = '',
    this.touristPopularity = '',
    this.familyFriendly = '',
    this.budgetCategory = '',
    this.toilets = '',
    this.foodNearby = '',
    this.wheelchairAccess = '',
    this.campingAllowed = '',
    this.safetyLevel = '',
    this.wildlifeHazard = '',
    this.guideRequired = '',
    this.rainSensitivity = '',
    this.monsoonNote = '',
    this.heightM = '',
    this.lengthKm = '',
    this.surfing = '',
    this.updatedAt = '',
    this.syncVersion = 0,
    this.arSupported = false,
    this.arTier = 3,
    this.arBrandName = '',
    this.arModelUrl = '',
    this.arHistoricalModelUrl = '',
    this.arModelScale = 0.01,
    this.historicalPeriod = '',
    this.arFileSizeMb = 0.0,
    this.arAuthor = 'Hidden Gems SL',
    this.arContentVersion = 1,
    this.audioUrlSi = '',
    this.audioUrlEn = '',
    this.fallbackVideoUrl = '',
    this.arHotspots = const [],
    this.arArtifacts = const [],
    this.geohash = '',
    this.images = const [],
    this.distanceKm = 0.0,
    this.aiReason = '',
    this.imageUrl = '',
  });

  factory DiscoveryPlace.fromJson(Map<String, dynamic> json) {
    final bool encrypted = json['isEncrypted'] as bool? ?? false;

    String decryptVal(dynamic val) {
      if (val == null) return '';
      if (!encrypted) return val.toString();
      return EncryptionUtil.decryptSync(val.toString());
    }

    double parseCoord(dynamic val) {
      if (val == null) return 0.0;
      double? parsed;
      if (val is num) {
        parsed = val.toDouble();
      } else {
        parsed = double.tryParse(decryptVal(val));
      }
      if (parsed == null) return 0.0;
      // BUG-042: Preserve up to 8 decimal places for GPS precision without truncation
      return double.tryParse(parsed.toStringAsFixed(8)) ?? parsed;
    }

    String parseUtcTimestamp(dynamic val) {
      if (val == null || val.toString().isEmpty) return DateTime.now().toUtc().toIso8601String();
      try {
        if (val is Timestamp) return val.toDate().toUtc().toIso8601String();
        return DateTime.parse(val.toString()).toUtc().toIso8601String();
      } catch (_) {
        return DateTime.now().toUtc().toIso8601String();
      }
    }

    // Backend (MySQL `places` table, see System Architecture.md) sends
    // `district_id`/`category_id` (plain readable names like "Kandy" and
    // "Plunge", not numeric foreign keys) and `ticket_price` as an integer
    // rather than the legacy `district`/`category`/`ticketRange` string
    // fields — fall back through all three naming conventions so the app
    // reads correctly regardless of which backend produced the payload.
    String ticketRangeFromPrice() {
      final price = json['ticket_price'];
      if (price == null) return '';
      final numPrice = price is num ? price : num.tryParse(price.toString());
      if (numPrice == null || numPrice == 0) return 'Free';
      return 'LKR ${numPrice.toStringAsFixed(0)}';
    }

    return DiscoveryPlace(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? json['district_id'] as String? ?? '',
      category: json['category'] as String? ?? json['category_id'] as String? ?? '',
      lat: parseCoord(json['lat']),
      lng: parseCoord(json['lng']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ticketRange: json['ticketRange'] as String? ??
          json['ticket_range'] as String? ??
          (json['ticket_price'] != null ? ticketRangeFromPrice() : null) ??
          'Free',
      roadType: json['roadType'] as String? ?? json['road_type'] as String? ?? '',
      vehicleAccess: json['vehicleAccess'] as String? ?? json['vehicle_access'] as String? ?? '',
      riskTags: List<String>.from(json['riskTags'] ?? json['risk_tags'] ?? []),
      parkingRange: json['parkingRange'] as String? ?? json['parking_range'] as String? ?? '',
      bestTime: json['bestTime'] as String? ?? json['best_time'] as String? ?? '',
      facilities: List<String>.from(json['facilities'] ?? []),
      openingHours: json['openingHours'] as String? ?? json['opening_hours'] as String? ?? '',
      mobileSignal: json['mobile_signal'] as String? ?? '',
      roadCondition: json['road_condition'] as String? ?? '',
      activities: json['activities'] as String? ?? '',
      touristPopularity: json['tourist_popularity'] as String? ?? '',
      familyFriendly: json['family_friendly'] as String? ?? '',
      budgetCategory: json['budget_category'] as String? ?? '',
      toilets: json['toilets'] as String? ?? '',
      foodNearby: json['food_nearby'] as String? ?? '',
      wheelchairAccess: json['wheelchair_access'] as String? ?? '',
      campingAllowed: json['camping_allowed'] as String? ?? '',
      safetyLevel: json['safety_level'] as String? ?? '',
      wildlifeHazard: json['wildlife_hazard'] as String? ?? '',
      guideRequired: json['guide_required'] as String? ?? '',
      rainSensitivity: json['rain_sensitivity'] as String? ?? '',
      monsoonNote: json['monsoon_note'] as String? ?? '',
      heightM: json['height_m']?.toString() ?? '',
      lengthKm: json['length_km']?.toString() ?? '',
      surfing: json['surfing'] as String? ?? '',
      updatedAt: parseUtcTimestamp(json['updatedAt'] ?? json['updated_at']),
      syncVersion: (json['syncVersion'] as num?)?.toInt() ?? (json['sync_version'] as num?)?.toInt() ?? 0,
      arSupported: json['arSupported'] as bool? ?? json['ar_supported'] as bool? ?? false,
      arTier: json['arTier'] as int? ?? json['ar_tier'] as int? ?? 3,
      arBrandName: json['arBrandName'] as String? ?? json['ar_brand_name'] as String? ?? '',
      arModelUrl: json['arModelUrl'] as String? ?? json['ar_model_url'] as String? ?? '',
      arHistoricalModelUrl: json['arHistoricalModelUrl'] as String? ?? json['ar_historical_model_url'] as String? ?? '',
      arModelScale: (json['arModelScale'] as num?)?.toDouble() ?? (json['ar_model_scale'] as num?)?.toDouble() ?? 0.01,
      historicalPeriod: json['historicalPeriod'] as String? ?? json['historical_period'] as String? ?? '',
      arFileSizeMb: (json['ar_file_size_mb'] as num?)?.toDouble() ?? 0.0,
      arAuthor: json['ar_author'] as String? ?? 'Hidden Gems SL',
      arContentVersion: json['ar_content_version'] as int? ?? 1,
      audioUrlSi: json['audio_guide_url_si'] as String? ?? '',
      audioUrlEn: json['audio_guide_url_en'] as String? ?? '',
      fallbackVideoUrl: json['fallback_video_url'] as String? ?? '',
      arHotspots: json['ar_hotspots'] as List<dynamic>? ?? [],
      arArtifacts: (json['ar_artifacts'] as List<dynamic>? ?? [])
          .map((a) => ARArtifact.fromMap(a as Map<String, dynamic>))
          .toList(),
      geohash: json['geohash'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
      images: (json['images'] is List && (json['images'] as List).isNotEmpty)
          ? (json['images'] as List).map((i) => PlaceImageModel.fromJson(i as Map<String, dynamic>)).toList()
          : (json['imageUrl'] != null || json['image_url'] != null)
              ? [
                  PlaceImageModel(
                    id: 0,
                    thumbPath: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
                    fullPath: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
                    isCover: true,
                  )
                ]
              : const [],
    );
  }

  factory DiscoveryPlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['geoPoint'] as GeoPoint?;
    
    double parseCoord(dynamic val, double? geoVal) {
      if (geoVal != null) return double.tryParse(geoVal.toStringAsFixed(8)) ?? geoVal;
      if (val == null) return 0.0;
      double? parsed = val is num ? val.toDouble() : double.tryParse(val.toString());
      if (parsed == null) return 0.0;
      // BUG-042: Preserve up to 8 decimal places for GPS precision without truncation
      return double.tryParse(parsed.toStringAsFixed(8)) ?? parsed;
    }

    String parseUtcTimestamp(dynamic val) {
      if (val == null || val.toString().isEmpty) return DateTime.now().toUtc().toIso8601String();
      try {
        if (val is Timestamp) return val.toDate().toUtc().toIso8601String();
        return DateTime.parse(val.toString()).toUtc().toIso8601String();
      } catch (_) {
        return DateTime.now().toUtc().toIso8601String();
      }
    }

    return DiscoveryPlace(
      id: doc.id,
      name: data['name'] ?? '',
      district: data['district'] ?? '',
      category: data['category'] ?? '',
      lat: parseCoord(data['lat'], geoPoint?.latitude),
      lng: parseCoord(data['lng'], geoPoint?.longitude),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ticketRange: data['ticketRange'] ?? data['ticket_range'] ?? '',
      roadType: data['roadType'] ?? data['road_type'] ?? '',
      vehicleAccess: data['vehicleAccess'] ?? data['vehicle_access'] ?? '',
      riskTags: List<String>.from(data['riskTags'] ?? data['risk_tags'] ?? []),
      parkingRange: data['parkingRange'] ?? data['parking_range'] ?? '',
      bestTime: data['bestTime'] ?? data['best_time'] ?? '',
      facilities: List<String>.from(data['facilities'] ?? []),
      openingHours: data['openingHours'] ?? data['opening_hours'] ?? '',
      mobileSignal: data['mobile_signal'] ?? '',
      roadCondition: data['road_condition'] ?? '',
      activities: data['activities'] ?? '',
      touristPopularity: data['tourist_popularity'] ?? '',
      familyFriendly: data['family_friendly'] ?? '',
      budgetCategory: data['budget_category'] ?? '',
      toilets: data['toilets'] ?? '',
      foodNearby: data['food_nearby'] ?? '',
      wheelchairAccess: data['wheelchair_access'] ?? '',
      campingAllowed: data['camping_allowed'] ?? '',
      safetyLevel: data['safety_level'] ?? '',
      wildlifeHazard: data['wildlife_hazard'] ?? '',
      guideRequired: data['guide_required'] ?? '',
      rainSensitivity: data['rain_sensitivity'] ?? '',
      monsoonNote: data['monsoon_note'] ?? '',
      heightM: data['height_m']?.toString() ?? '',
      lengthKm: data['length_km']?.toString() ?? '',
      surfing: data['surfing'] ?? '',
      updatedAt: parseUtcTimestamp(data['updatedAt'] ?? data['updated_at']),
      syncVersion: (data['syncVersion'] as num?)?.toInt() ?? (data['sync_version'] as num?)?.toInt() ?? 0,
      arSupported: data['arSupported'] ?? false,
      arTier: data['arTier'] ?? 3,
      arBrandName: data['arBrandName'] ?? '',
      arModelUrl: data['arModelUrl'] ?? '',
      arHistoricalModelUrl: data['arHistoricalModelUrl'] ?? '',
      arModelScale: (data['arModelScale'] as num?)?.toDouble() ?? 0.01,
      historicalPeriod: data['historicalPeriod'] ?? '',
      arFileSizeMb: (data['ar_file_size_mb'] as num?)?.toDouble() ?? 0.0,
      audioUrlSi: data['audio_guide_url_si'] ?? '',
      audioUrlEn: data['audio_guide_url_en'] ?? '',
      geohash: data['geohash'] ?? '',
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? '',
      images: (data['images'] is List && (data['images'] as List).isNotEmpty)
          ? (data['images'] as List).map((i) => PlaceImageModel.fromJson(i as Map<String, dynamic>)).toList()
          : (data['imageUrl'] != null || data['image_url'] != null)
              ? [
                  PlaceImageModel(
                    id: 0,
                    thumbPath: data['imageUrl'] ?? data['image_url'] ?? '',
                    fullPath: data['imageUrl'] ?? data['image_url'] ?? '',
                    isCover: true,
                  )
                ]
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'category': category,
      'lat': lat,
      'lng': lng,
      'rating': rating,
      'ticketRange': ticketRange,
      'ticket_range': ticketRange,
      'roadType': roadType,
      'road_type': roadType,
      'vehicleAccess': vehicleAccess,
      'vehicle_access': vehicleAccess,
      'riskTags': riskTags,
      'risk_tags': riskTags,
      'parkingRange': parkingRange,
      'parking_range': parkingRange,
      'bestTime': bestTime,
      'best_time': bestTime,
      'facilities': facilities,
      'openingHours': openingHours,
      'opening_hours': openingHours,
      'mobile_signal': mobileSignal,
      'road_condition': roadCondition,
      'activities': activities,
      'tourist_popularity': touristPopularity,
      'family_friendly': familyFriendly,
      'budget_category': budgetCategory,
      'toilets': toilets,
      'food_nearby': foodNearby,
      'wheelchair_access': wheelchairAccess,
      'camping_allowed': campingAllowed,
      'safety_level': safetyLevel,
      'wildlife_hazard': wildlifeHazard,
      'guide_required': guideRequired,
      'rain_sensitivity': rainSensitivity,
      'monsoon_note': monsoonNote,
      'height_m': heightM,
      'length_km': lengthKm,
      'surfing': surfing,
      'updatedAt': updatedAt,
      'updated_at': updatedAt,
      'syncVersion': syncVersion,
      'sync_version': syncVersion,
      'arSupported': arSupported,
      'ar_supported': arSupported,
      'arTier': arTier,
      'ar_tier': arTier,
      'arBrandName': arBrandName,
      'ar_brand_name': arBrandName,
      'arModelUrl': arModelUrl,
      'ar_model_url': arModelUrl,
      'arHistoricalModelUrl': arHistoricalModelUrl,
      'ar_historical_model_url': arHistoricalModelUrl,
      'arModelScale': arModelScale,
      'ar_model_scale': arModelScale,
      'historicalPeriod': historicalPeriod,
      'historical_period': historicalPeriod,
      'ar_file_size_mb': arFileSizeMb,
      'ar_author': arAuthor,
      'ar_content_version': arContentVersion,
      'audio_guide_url_si': audioUrlSi,
      'audio_guide_url_en': audioUrlEn,
      'fallback_video_url': fallbackVideoUrl,
      'geohash': geohash,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'images': images.map((i) => i.toJson()).toList(),
    };
  }
}


