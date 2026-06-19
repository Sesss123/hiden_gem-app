import 'package:flutter/material.dart';
import 'ar_artifact.dart';

/// Result of a server-side AR session validation.
class ArSessionValidation {
  final bool allowed;
  final String reason;
  final int? elapsedSeconds;

  const ArSessionValidation({
    required this.allowed,
    required this.reason,
    this.elapsedSeconds,
  });

  /// True if session ended because free limit was exceeded.
  bool get isFreeLimitExceeded => reason == 'free_limit_exceeded';
}

/// AR Hotspot data class.
class ARHotspot {
  final String id;
  final String label;
  final String description;
  final List<double> position;

  const ARHotspot({
    required this.id,
    required this.label,
    required this.description,
    required this.position,
  });

  factory ARHotspot.fromMap(Map<String, dynamic> map) {
    return ARHotspot(
      id: map['id'] as String,
      label: map['label'] as String,
      description: map['description'] as String? ?? '',
      position: List<double>.from(map['position'] as List),
    );
  }
}

/// AR-enabled place metadata.
class ARPlaceData {
  final bool arSupported;
  final int arTier;
  final String arBrandName;
  final String arModelUrl;
  final String arHistoricalModelUrl;
  final double arModelScale;
  final String historicalPeriod;
  final String audioUrlSi;
  final String audioUrlEn;
  final String fallbackVideoUrl;
  final int arContentVersion;
  final double modelFileSizeMb;
  final String authorName;
  final List<ARHotspot> hotspots;
  final List<ARArtifact> artifacts;
  final double targetLat;
  final double targetLng;

  const ARPlaceData({
    required this.arSupported,
    required this.arTier,
    required this.arBrandName,
    required this.arModelUrl,
    required this.arHistoricalModelUrl,
    required this.arModelScale,
    required this.historicalPeriod,
    required this.audioUrlSi,
    required this.audioUrlEn,
    required this.fallbackVideoUrl,
    required this.arContentVersion,
    this.modelFileSizeMb = 0.0,
    this.authorName = 'Hidden Gems SL',
    required this.hotspots,
    required this.artifacts,
    required this.targetLat,
    required this.targetLng,
  });

  factory ARPlaceData.fromMap(Map<String, dynamic> map) {
    return ARPlaceData(
      arSupported: map['ar_supported'] as bool? ?? false,
      arTier: map['ar_tier'] as int? ?? 3,
      arBrandName: map['ar_brand_name'] as String? ?? 'Story View',
      arModelUrl: map['ar_model_url'] as String? ?? '',
      arHistoricalModelUrl: map['ar_historical_model_url'] as String? ?? '',
      arModelScale: (map['ar_model_scale'] as num?)?.toDouble() ?? 0.01,
      historicalPeriod: map['historical_period'] as String? ?? '',
      audioUrlSi: map['audio_guide_url_si'] as String? ?? '',
      audioUrlEn: map['audio_guide_url_en'] as String? ?? '',
      fallbackVideoUrl: map['fallback_video_url'] as String? ?? '',
      arContentVersion: map['ar_content_version'] as int? ?? 1,
      modelFileSizeMb: (map['ar_file_size_mb'] as num?)?.toDouble() ?? 0.0,
      authorName: map['ar_author'] as String? ?? 'Hidden Gems SL',
      hotspots: (map['ar_hotspots'] as List<dynamic>? ?? [])
          .map((h) => ARHotspot.fromMap(h as Map<String, dynamic>))
          .toList(),
      artifacts: (map['ar_artifacts'] as List<dynamic>? ?? [])
          .map((a) => ARArtifact.fromMap(a as Map<String, dynamic>))
          .toList(),
      targetLat: (map['target_lat'] as num?)?.toDouble() ?? 0.0,
      targetLng: (map['target_lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get tierColor {
    switch (arTier) {
      case 1: return const Color(0xFFFFB300);
      case 2: return const Color(0xFF29B6F6);
      default: return const Color(0xFF66BB6A);
    }
  }

  String get tierIcon {
    switch (arTier) {
      case 1: return '🏛';
      case 2: return '🔭';
      default: return '📖';
    }
  }
}
