import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'voice_assistant_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../../core/utils/secure_logger.dart';
import 'dart:async';

class GeoAwareGuideService {
  static StreamSubscription<Position>? _positionStream;
  static String? _lastTriggeredPlaceId;
  static const double _triggerRadius = 150.0; // 150 meters
  static double _currentFilter = 10.0; // Added missing variable check
  static LocationAccuracy _currentAccuracy = LocationAccuracy.high;
  static AppLifecycleListener? _lifecycleListener;
  static DateTime? _lastStrategyRearm;
  static const Duration _minRearmInterval = Duration(seconds: 20);

  static void startMonitoring(List<ItineraryItem> plannedItems) {
    // BUG-077: Add AppLifecycleListener to release GPS sensor when app is closed or paused
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onPause: () {
        SecureLogger.info("App paused: Stopping GPS sensor updates.");
        stopMonitoring();
      },
      onResume: () {
        SecureLogger.info("App resumed: Restarting GPS sensor updates.");
        _monitorAdaptive(plannedItems, initialFilter: _currentFilter, accuracy: _currentAccuracy);
      },
      onDetach: () {
        SecureLogger.info("App detached: Cleaning up GPS sensor updates.");
        stopMonitoring();
      },
    );

    _monitorAdaptive(plannedItems, initialFilter: 10.0, accuracy: LocationAccuracy.high);
  }


  /// Composite key for de-duping narration triggers. ItineraryItem has no
  /// unique id field — using [ItineraryItem.title] alone would mean two
  /// stops that happen to share a name (e.g. two "Rest Stop" entries) are
  /// treated as the same place, so a real arrival at the second one would
  /// silently never narrate. Coordinates make the key unique per location.
  static String _placeKey(ItineraryItem item) => '${item.title}@${item.lat},${item.lng}';

  static void _monitorAdaptive(
    List<ItineraryItem> items, {
    required double initialFilter,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    _positionStream?.cancel();
    _currentFilter = initialFilter;
    _currentAccuracy = accuracy;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        // BUG-137: Use adaptive accuracy — low power when stationary, high when moving
        accuracy: _currentAccuracy,
        distanceFilter: _currentFilter.toInt(),
      ),
    ).listen((Position position) {
      _checkProximity(position, items);
      _evaluateBatteryStrategy(position, items);
    });
  }

  static void _evaluateBatteryStrategy(Position pos, List<ItineraryItem> items) {
    if (items.isEmpty) return;
    
    double minDistance = double.infinity;
    for (var item in items) {
      final d = Geolocator.distanceBetween(pos.latitude, pos.longitude, item.lat, item.lng);
      if (d < minDistance) minDistance = d;
    }

    // BUG-137: Switch GPS accuracy based on movement state AND proximity.
    // BUG-097: Downgrade accuracy when indoors (poor location accuracy signals > 30m)
    final bool isStationary = pos.speed < 0.5;
    final bool isIndoors = pos.accuracy > 30.0;
    double targetFilter;
    LocationAccuracy targetAccuracy;

    if (isStationary || isIndoors) {
      targetFilter = minDistance < 1000 ? 50.0 : 250.0;
      targetAccuracy = LocationAccuracy.low; // BUG-137 & BUG-097: Low power when stationary/indoors
    } else if (minDistance < 1000) {

      targetFilter = 10.0;
      targetAccuracy = LocationAccuracy.high;
    } else {
      targetFilter = 100.0;
      targetAccuracy = LocationAccuracy.medium;
    }

    if (targetFilter != _currentFilter || targetAccuracy != _currentAccuracy) {
      // BUG-20: If speed/accuracy readings oscillate right around a
      // threshold (e.g. speed hovering near 0.5 m/s), this branch can fire
      // on almost every position update, tearing down and recreating the
      // GPS stream in a tight loop. A minimum re-arm interval debounces
      // that churn without blocking a genuine, sustained strategy change.
      final now = DateTime.now();
      if (_lastStrategyRearm != null && now.difference(_lastStrategyRearm!) < _minRearmInterval) {
        return;
      }
      _lastStrategyRearm = now;

      SecureLogger.info(
        'Adaptive GPS: filter=${targetFilter}m accuracy=$targetAccuracy '
        '(speed=${pos.speed.toStringAsFixed(1)} m/s, dist=${minDistance.toStringAsFixed(0)}m).',
      );
      _monitorAdaptive(items, initialFilter: targetFilter, accuracy: targetAccuracy);
    }
  }


  static void stopMonitoring() {
    _positionStream?.cancel();
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }


  static Future<void> _checkProximity(Position userPos, List<ItineraryItem> items) async {
    for (var item in items) {
      final distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        item.lat,
        item.lng,
      );

      if (distance < _triggerRadius && _lastTriggeredPlaceId != _placeKey(item)) {
        _lastTriggeredPlaceId = _placeKey(item);
        _triggerAutonomousNarration(item);
        break; 
      }
    }
  }

  static Future<void> _triggerAutonomousNarration(ItineraryItem item) async {
    SecureLogger.info('Geo-Aware Trigger: Entering ${item.title}');
    
    final response = await VoiceAssistantService.getOracleLogic(
      "I am approaching ${item.title}. Tell me its secret history.",
      "Entrance to ${item.title}",
    );

    // Using the advanced (placeholder) synthesis for cinematic immersion
    await VoiceAssistantService.speakAdvanced(response, accent: 'lk_cinematic');
  }
}
