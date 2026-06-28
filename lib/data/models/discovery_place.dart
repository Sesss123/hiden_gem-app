import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/encryption_util.dart';
import 'ar_artifact.dart';

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

    return DiscoveryPlace(
      id: json['id'].toString(),
      name: json['name'] as String,
      district: json['district'] as String,
      category: json['category'] as String,
      lat: double.tryParse(decryptVal(json['lat'])) ?? 0.0,
      lng: double.tryParse(decryptVal(json['lng'])) ?? 0.0,
      rating: (json['rating'] as num).toDouble(),
      ticketRange: json['ticketRange'] as String,
      roadType: json['roadType'] as String? ?? '',
      vehicleAccess: json['vehicleAccess'] as String? ?? '',
      riskTags: List<String>.from(json['riskTags'] ?? []),
      parkingRange: json['parkingRange'] as String? ?? '',
      bestTime: json['bestTime'] as String? ?? '',
      facilities: List<String>.from(json['facilities'] ?? []),
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
      imageUrl: json['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
    );
  }

  factory DiscoveryPlace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['geoPoint'] as GeoPoint?;
    
    return DiscoveryPlace(
      id: doc.id,
      name: data['name'] ?? '',
      district: data['district'] ?? '',
      category: data['category'] ?? '',
      lat: geoPoint?.latitude ?? (data['lat'] is String ? double.tryParse(data['lat']) : (data['lat'] as num?)?.toDouble()) ?? 0.0,
      lng: geoPoint?.longitude ?? (data['lng'] is String ? double.tryParse(data['lng']) : (data['lng'] as num?)?.toDouble()) ?? 0.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      ticketRange: data['ticketRange'] ?? '',
      roadType: data['roadType'] ?? '',
      vehicleAccess: data['vehicleAccess'] ?? '',
      riskTags: List<String>.from(data['riskTags'] ?? []),
      parkingRange: data['parkingRange'] ?? '',
      bestTime: data['bestTime'] ?? '',
      facilities: List<String>.from(data['facilities'] ?? []),
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
      imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop',
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
      'roadType': roadType,
      'vehicleAccess': vehicleAccess,
      'riskTags': riskTags,
      'parkingRange': parkingRange,
      'bestTime': bestTime,
      'facilities': facilities,
      'arSupported': arSupported,
      'arTier': arTier,
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
    };
  }
}
