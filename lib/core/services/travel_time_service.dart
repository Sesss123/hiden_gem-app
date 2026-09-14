import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/secure_logger.dart';

class TravelEstimate {
  final double straightLineKm;
  final double estimatedRoadKm;
  final bool isMountainous;
  final String roadType;
  final String roadConditionNote;
  final Duration carDuration;
  final Duration tukTukDuration;
  final Duration bikeDuration;
  final Duration walkDuration;
  final String estimationBadge;

  const TravelEstimate({
    required this.straightLineKm,
    required this.estimatedRoadKm,
    required this.isMountainous,
    required this.roadType,
    required this.roadConditionNote,
    required this.carDuration,
    required this.tukTukDuration,
    required this.bikeDuration,
    required this.walkDuration,
    required this.estimationBadge,
  });

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes <= 0) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return '$hours hr';
    return '${hours}h ${remainingMins}m';
  }
}

class TravelTimeService {
  // Hill Country & Montane districts in Sri Lanka with hairpin bends and elevation drops
  static const Set<String> _mountainousDistricts = {
    'nuwara eliya',
    'badulla',
    'kandy',
    'matale',
    'ratnapura',
    'kegalle',
    'monaragala',
  };

  /// Calculates a local approximation from straight-line distance. This is
  /// not a route, traffic or navigation-provider ETA.
  static TravelEstimate calculateEstimate({
    required double straightLineDistanceKm,
    required String district,
    String? roadType,
    String? roadCondition,
    String? vehicleAccess,
  }) {
    final distLower = district.trim().toLowerCase();
    final isMountainous = _mountainousDistricts.contains(distLower);

    final roadTypeLower = (roadType ?? '').toLowerCase();
    final isGravelOrDirt = roadTypeLower.contains('gravel') ||
        roadTypeLower.contains('dirt') ||
        roadTypeLower.contains('track') ||
        roadTypeLower.contains('unpaved');

    // 1. Road Distance Factor (Straight-line distance -> Road trajectory multiplier)
    double roadMultiplier = 1.25; // Standard Sri Lankan road curvature
    if (isMountainous) {
      roadMultiplier = 1.40; // Steep elevation & hairpin bends
    } else if (distLower == 'colombo' || distLower == 'gampaha' || distLower == 'galle') {
      roadMultiplier = 1.20; // Denser road network / expressway availability
    }

    final estimatedRoadKm = straightLineDistanceKm * roadMultiplier;

    // 2. Average Speeds (km/h) factoring in terrain and road conditions
    double carSpeed = 36.0;
    double tukTukSpeed = 28.0;
    double bikeSpeed = 32.0;
    double walkSpeed = 4.5;

    String conditionNote = 'Paved roads';

    if (isMountainous) {
      carSpeed = 26.0; // Hill country winding speeds
      tukTukSpeed = 20.0;
      bikeSpeed = 24.0;
      walkSpeed = 3.2;
      conditionNote = 'Mountainous terrain with curves';
    }

    if (isGravelOrDirt) {
      carSpeed = carSpeed.clamp(15.0, 20.0);
      tukTukSpeed = tukTukSpeed.clamp(14.0, 18.0);
      bikeSpeed = bikeSpeed.clamp(16.0, 22.0);
      walkSpeed = 3.5;
      conditionNote = 'Unpaved / gravel road (4WD / slow pace recommended)';
    }

    final carMinutes = (estimatedRoadKm / carSpeed * 60).round().clamp(1, 1440);
    final tukTukMinutes = (estimatedRoadKm / tukTukSpeed * 60).round().clamp(1, 1440);
    final bikeMinutes = (estimatedRoadKm / bikeSpeed * 60).round().clamp(1, 1440);
    final walkMinutes = (estimatedRoadKm / walkSpeed * 60).round().clamp(1, 1440);

    return TravelEstimate(
      straightLineKm: straightLineDistanceKm,
      estimatedRoadKm: estimatedRoadKm,
      isMountainous: isMountainous,
      roadType: roadType?.isNotEmpty == true ? roadType! : 'Standard Road',
      roadConditionNote: conditionNote,
      carDuration: Duration(minutes: carMinutes),
      tukTukDuration: Duration(minutes: tukTukMinutes),
      bikeDuration: Duration(minutes: bikeMinutes),
      walkDuration: Duration(minutes: walkMinutes),
      estimationBadge: isMountainous
          ? 'Straight-line mountain approximation'
          : 'Straight-line travel approximation',
    );
  }

  /// Directly launches native turn-by-turn navigation in Google Maps or Apple Maps.
  static Future<bool> launchLiveDirections({
    double? destinationLat,
    double? destinationLng,
    double? lat,
    double? lng,
    required String placeName,
  }) async {
    final targetLat = destinationLat ?? lat ?? 0.0;
    final targetLng = destinationLng ?? lng ?? 0.0;
    final encodedName = Uri.encodeComponent(placeName);
    // Google Maps Universal Direct Navigation Intent
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&destination_place_id=$encodedName&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      SecureLogger.warning('Failed to launch Google Maps URL: $e', tag: 'TravelTime');
    }

    // Fallback to geo URI
    final geoUri = Uri.parse('geo:$targetLat,$targetLng?q=$targetLat,$targetLng($encodedName)');
    if (await canLaunchUrl(geoUri)) {
      return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Calculates a TravelTimeResult matching the UI requirements in place details screen.
  static TravelTimeResult calculate({
    required double distanceKm,
    required String district,
    String? roadType,
    String? roadCondition,
  }) {
    final est = calculateEstimate(
      straightLineDistanceKm: distanceKm,
      district: district,
      roadType: roadType,
      roadCondition: roadCondition,
    );
    return TravelTimeResult(
      straightLineKm: est.straightLineKm,
      estimatedRoadKm: est.estimatedRoadKm,
      // This is a local heuristic derived from straight-line distance, not a
      // route returned by a directions provider. Keep the UI truthful.
      isStraightLineEstimate: true,
      carTime: TravelEstimate.formatDuration(est.carDuration),
      tukTukTime: TravelEstimate.formatDuration(est.tukTukDuration),
      bikeTime: TravelEstimate.formatDuration(est.bikeDuration),
      walkTime: TravelEstimate.formatDuration(est.walkDuration),
      terrainNote: est.roadConditionNote,
    );
  }

  /// Launches Google Maps to search for nearby essentials around destination coordinates.
  static Future<bool> launchNearbySearch({
    required double lat,
    required double lng,
    required String query,
  }) async {
    final encodedQuery = Uri.encodeComponent('$query near $lat,$lng');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      SecureLogger.warning('Failed to launch nearby search URL: $e', tag: 'TravelTime');
    }

    final geoUri = Uri.parse('geo:$lat,$lng?q=$encodedQuery');
    if (await canLaunchUrl(geoUri)) {
      return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}

class TravelTimeResult {
  final double straightLineKm;
  final double estimatedRoadKm;
  final bool isStraightLineEstimate;
  final String carTime;
  final String tukTukTime;
  final String bikeTime;
  final String walkTime;
  final String terrainNote;

  const TravelTimeResult({
    required this.straightLineKm,
    required this.estimatedRoadKm,
    required this.isStraightLineEstimate,
    required this.carTime,
    required this.tukTukTime,
    required this.bikeTime,
    required this.walkTime,
    required this.terrainNote,
  });
}
