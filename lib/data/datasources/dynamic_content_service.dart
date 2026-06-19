import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/config/remote_config_service.dart';
import '../../core/utils/secure_logger.dart';
import 'trip_cache_service.dart';
import 'sri_lanka_event_dataset.dart';

class DynamicContentService {
  static Future<List<Map<String, dynamic>>> fetchEvents() async {
    try {
      final remoteConfig = await RemoteConfigService.getInstance();
      final remoteTimestamp = remoteConfig.dataRefreshTimestamp;
      final localTimestamp = TripCacheService.getGlobalDataTimestamp('events');
      
      final String? cachedData = TripCacheService.getGlobalData('events');

      if (cachedData != null && localTimestamp >= remoteTimestamp) {
        final List<dynamic> data = json.decode(cachedData);
        SecureLogger.info("Events loaded from cache (Smart Refresh).");
        return List<Map<String, dynamic>>.from(data);
      } else {
        final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/discovery/events'),
          headers: {'X-TripMe-Key': AppConfig.tripMeApiKey},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          await TripCacheService.cacheGlobalData('events', response.body);
          SecureLogger.info("Events fetched from API and cached.");
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception("API returned ${response.statusCode}");
        }
      }
    } catch (e) {
      SecureLogger.error("Dynamic events fetch failed, checking cache or local", e);
      final String? cachedData = TripCacheService.getGlobalData('events');
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(json.decode(cachedData));
      }
      return SriLankaEvents.events;
    }
  }

  static Future<Map<String, dynamic>> fetchRemoteConfig() async {
    try {
      // Mock remote config endpoint - can be implemented in main.py later
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/config/remote'),
        headers: {'X-TripMe-Key': AppConfig.tripMeApiKey},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      SecureLogger.error("Remote config fetch failed", e);
    }
    
    // Default config
    return {
      'showBanner': false,
      'bannerText': '',
      'enableOracleVision': true,
      'aiModel': 'gemini-1.5-flash',
    };
  }
}
