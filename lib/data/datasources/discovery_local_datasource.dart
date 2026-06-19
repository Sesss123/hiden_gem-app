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
    final String localResponse = await rootBundle.loadString('assets/places.json');
    final List<dynamic> data = json.decode(localResponse);
    return data.map((j) => DiscoveryPlace.fromJson(j)).toList();
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
