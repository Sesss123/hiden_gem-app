import 'package:weather/weather.dart';
import '../config/app_config.dart';
import '../utils/secure_logger.dart';

class SafetyGuardService {
  static final WeatherFactory? _wf = AppConfig.weatherApiKey.isNotEmpty 
      ? WeatherFactory(AppConfig.weatherApiKey) 
      : null;

  static Future<Map<String, dynamic>> checkSafetyStatus(double lat, double lng) async {
    final wf = _wf;
    if (wf == null) {
      return {
        'isThreat': false,
        'threatMessage': "Oracle is peering through the clouds...",
        'temp': 'N/A',
        'condition': 'Unknown',
      };
    }
    try {
      final weather = await wf.currentWeatherByLocation(lat, lng);
      
      bool isThreat = false;
      String threatMsg = "Path is clear, traveler.";
      
      if (weather.weatherMain?.toLowerCase().contains("storm") == true || 
          weather.weatherMain?.toLowerCase().contains("rain") == true) {
        isThreat = true;
        threatMsg = "Oracle Warning: Monsoon clouds are gathering. Seek shelter soon.";
      }

      if ((weather.tempMax?.celsius ?? 0) > 35) {
        isThreat = true;
        threatMsg = "Oracle Warning: Extreme heat detected. Stay hydrated and avoid open rocks.";
      }

      return {
        'isThreat': isThreat,
        'threatMessage': threatMsg,
        'temp': weather.temperature?.celsius?.toStringAsFixed(1),
        'condition': weather.weatherMain,
      };
    } catch (e) {
      SecureLogger.error('Safety Guard Error: $e');
      return {
        'isThreat': false,
        'threatMessage': "The Oracle cannot see the skies right now.",
      };
    }
  }

  static Future<void> triggerSOS() async {
    // In a real app, this would ping a backend and emergency services
    SecureLogger.warning('SOS TRIGGERED: Sending coordinates to the Oracle Guard!');
    await Future.delayed(const Duration(seconds: 2));
  }
}
