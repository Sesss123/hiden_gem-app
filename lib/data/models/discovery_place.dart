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
    this.imageUrl = 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
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

    return DiscoveryPlace(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      category: json['category'] as String? ?? '',
      lat: parseCoord(json['lat']),
      lng: parseCoord(json['lng']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ticketRange: json['ticketRange'] as String? ?? json['ticket_range'] as String? ?? 'Free',
      roadType: json['roadType'] as String? ?? json['road_type'] as String? ?? '',
      vehicleAccess: json['vehicleAccess'] as String? ?? json['vehicle_access'] as String? ?? '',
      riskTags: List<String>.from(json['riskTags'] ?? json['risk_tags'] ?? []),
      parkingRange: json['parkingRange'] as String? ?? json['parking_range'] as String? ?? '',
      bestTime: json['bestTime'] as String? ?? json['best_time'] as String? ?? '',
      facilities: List<String>.from(json['facilities'] ?? []),
      openingHours: json['openingHours'] as String? ?? json['opening_hours'] as String? ?? '',
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
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
      images: (json['images'] is List && (json['images'] as List).isNotEmpty)
          ? (json['images'] as List).map((i) => PlaceImageModel.fromJson(i as Map<String, dynamic>)).toList()
          : [
              PlaceImageModel(
                id: 0,
                thumbPath: json['imageUrl'] as String? ?? json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
                fullPath: json['imageUrl'] as String? ?? json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
                isCover: true,
              )
            ],
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
      imageUrl: data['imageUrl'] ?? data['image_url'] ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
      images: (data['images'] is List && (data['images'] as List).isNotEmpty)
          ? (data['images'] as List).map((i) => PlaceImageModel.fromJson(i as Map<String, dynamic>)).toList()
          : [
              PlaceImageModel(
                id: 0,
                thumbPath: data['imageUrl'] ?? data['image_url'] ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
                fullPath: data['imageUrl'] ?? data['image_url'] ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
                isCover: true,
              )
            ],
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


