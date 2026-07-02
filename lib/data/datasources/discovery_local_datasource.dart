import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/discovery_place.dart';
import 'trip_cache_service.dart';

class DiscoveryLocalDataSource {
  // Memory cache (equivalent to Level-0)
  static final Map<String, List<DiscoveryPlace>> _memCache = {};

  Future<void> cachePlaces(String key, String jsonBody) async {
    await TripCacheService.cacheGlobalData(key, jsonBody);
    TripCacheService.markLastServerCheck(key);
  }

  String? getCachedPlaces(String key) {
    return TripCacheService.getGlobalData(key);
  }

  bool isCacheValid(String key, Duration ttl) {
    return !TripCacheService.shouldCheckServer(key, ttl: ttl);
  }

  int getCacheTimestamp(String key) {
    return TripCacheService.getGlobalDataTimestamp(key);
  }

  Future<List<DiscoveryPlace>> getAssetPlaces() async {
    // Option A: Zero-Bundle Strategy. No static JSON files are shipped in assets.
    // If remote fetches fail, check Level-1 cache or return empty list.
    final String? cachedJson = TripCacheService.getGlobalData('places');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final List<dynamic> data = json.decode(cachedJson);
        return data.map((j) => DiscoveryPlace.fromJson(j)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void cacheInMemory(String key, List<DiscoveryPlace> places) {
    _memCache[key] = places;
  }

  List<DiscoveryPlace>? getFromMemory(String key) {
    return _memCache[key];
  }

  void clearMemory() {
    _memCache.clear();
  }
}
