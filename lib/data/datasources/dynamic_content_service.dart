import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/secure_http_client.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';
import 'trip_cache_service.dart';
import 'sri_lanka_event_dataset.dart';

class DynamicContentService {
  static final _client = SecureHttpClient(http.Client());

  static Future<List<Map<String, dynamic>>> fetchEvents() async {
    try {
      // Used to gate on Firebase Remote Config's "data_refresh_timestamp",
      // which nothing on the backend/admin side ever bumps — it stayed at
      // its default (0) forever, so localTimestamp (which grows on every
      // cache write) was always >= it, and the app never refetched events
      // from the API again after the very first successful fetch. An admin
      // could publish a brand-new event and it would stay invisible on
      // already-installed apps indefinitely. Switched to the same TTL-based
      // shouldCheckServer/markLastServerCheck pattern already used for
      // places (DiscoveryLocalDataSource.isCacheValid).
      final String? cachedData = TripCacheService.getGlobalData('events');
      final needsRefresh = TripCacheService.shouldCheckServer('events', ttl: const Duration(minutes: 15));

      if (cachedData != null && !needsRefresh) {
        final List<dynamic> data = json.decode(cachedData);
        SecureLogger.info("Events loaded from cache (Smart Refresh).");
        return List<Map<String, dynamic>>.from(data);
      } else {
        final response = await _client.get(
          Uri.parse('${AppConfig.baseUrl}/discovery/events'),
          headers: {'X-API-KEY': AppConfig.hiddenGemsApiKey},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          await TripCacheService.cacheGlobalData('events', response.body);
          TripCacheService.markLastServerCheck('events');
          SecureLogger.info("Events fetched from API and cached.");
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception("API returned ${response.statusCode}");
        }
      }
    } catch (e) {
      SecureLogger.error("Dynamic events fetch failed, checking cache or local: $e");
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
      final response = await _client.get(
        Uri.parse('${AppConfig.baseUrl}/config/remote'),
        headers: {'X-HiddenGems-Key': AppConfig.hiddenGemsApiKey},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      SecureLogger.error("Remote config fetch failed: $e");
    }
    
    // Default config
    return {
      'showBanner': false,
      'bannerText': '',
      'enableOracleVision': true,
      'aiModel': AppConfig.llmModelName,
    };
  }
}
