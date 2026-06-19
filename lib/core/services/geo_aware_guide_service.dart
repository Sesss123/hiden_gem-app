import 'package:geolocator/geolocator.dart';
import 'voice_assistant_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../../core/utils/secure_logger.dart';
import 'dart:async';

class GeoAwareGuideService {
  static StreamSubscription<Position>? _positionStream;
  static String? _lastTriggeredPlaceId;
  static const double _triggerRadius = 150.0; // 150 meters

  static double _currentFilter = 10.0;

  static void startMonitoring(List<ItineraryItem> plannedItems) {
    _monitorAdaptive(plannedItems, initialFilter: 10.0);
  }

  static void _monitorAdaptive(List<ItineraryItem> items, {required double initialFilter}) {
    _positionStream?.cancel();
    _currentFilter = initialFilter;
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
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

    // Adaptive Strategy:
    // Close (< 1km) -> High Precision (10m filter)
    // Far (> 1km) -> Power Saving (100m filter)
    double targetFilter = minDistance < 1000 ? 10.0 : 100.0;

    if (targetFilter != _currentFilter) {
      SecureLogger.info('Adaptive GPS: Switching to ${targetFilter == 10.0 ? "High Precision" : "Power Saving"} mode.');
      _monitorAdaptive(items, initialFilter: targetFilter);
    }
  }

  static void stopMonitoring() {
    _positionStream?.cancel();
  }

  static Future<void> _checkProximity(Position userPos, List<ItineraryItem> items) async {
    for (var item in items) {
      final distance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        item.lat,
        item.lng,
      );

      if (distance < _triggerRadius && _lastTriggeredPlaceId != item.title) {
        _lastTriggeredPlaceId = item.title;
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
