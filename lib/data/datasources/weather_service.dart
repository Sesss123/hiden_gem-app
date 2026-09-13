import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';

class WeatherSnapshot {
  final double tempC;
  final String condition;
  final String iconCode;
  final String locationName;

  const WeatherSnapshot({
    required this.tempC,
    required this.condition,
    required this.iconCode,
    required this.locationName,
  });

  factory WeatherSnapshot.fromOpenWeatherMap(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final weather = weatherList.isNotEmpty ? weatherList.first as Map<String, dynamic> : {};
    return WeatherSnapshot(
      tempC: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      condition: weather['main'] as String? ?? '',
      iconCode: weather['icon'] as String? ?? '',
      locationName: json['name'] as String? ?? '',
    );
  }
}

/// Thin client for OpenWeatherMap's current-weather endpoint. Requires
/// AppConfig.weatherApiKey to be a real key (passed via --dart-define at
/// build time) — with no key configured, getCurrentWeather() returns null
/// rather than throwing, so the home screen can simply hide the widget.
class WeatherService {
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<WeatherSnapshot?> getCurrentWeather({
    required double lat,
    required double lng,
  }) async {
    if (AppConfig.isPlaceholder(AppConfig.weatherApiKey)) {
      return null;
    }
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'appid': AppConfig.weatherApiKey,
        'units': 'metric',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherSnapshot.fromOpenWeatherMap(json.decode(response.body));
      }
      SecureLogger.warning('Weather API returned ${response.statusCode}', tag: 'WeatherService');
      return null;
    } catch (e) {
      SecureLogger.warning('Weather fetch failed: $e', tag: 'WeatherService');
      return null;
    }
  }
}
