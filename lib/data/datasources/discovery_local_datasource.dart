import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/discovery_place.dart';
import 'trip_cache_service.dart';

class DiscoveryLocalDataSource {
  // Memory cache (equivalent to Level-0)
  static final Map<String, List<DiscoveryPlace>> _memCache = {};

  // BUG-066: Decoded model cache — avoids re-decoding the same JSON repeatedly
  static final Map<String, List<DiscoveryPlace>> _decodedCache = {};

  // BUG-126 / BUG-146: Debounce timer — coalesces rapid successive cachePlaces
  // calls into a single disk write, preventing UI frame skips caused by
  // serializing large payloads on every API response.
  static Timer? _diskWriteDebounce;
  static String? _pendingKey;
  static String? _pendingJson;

  Future<void> cachePlaces(String key, String jsonBody) async {
    // Update the server-check timestamp immediately (cheap operation)
    TripCacheService.markLastServerCheck(key);

    // Hold onto the latest values; cancel any pending write
    _pendingKey = key;
    _pendingJson = jsonBody;
    _diskWriteDebounce?.cancel();

    // BUG-126 / BUG-146: Schedule the actual disk write 400 ms after the last call
    _diskWriteDebounce = Timer(const Duration(milliseconds: 400), () async {
      final k = _pendingKey;
      final v = _pendingJson;
      if (k != null && v != null) {
        await TripCacheService.cacheGlobalData(k, v);
        _pendingKey = null;
        _pendingJson = null;
      }
    });
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

  static List<DiscoveryPlace> _decodeCachedPlaces(String cachedJson) {
    try {
      final List<dynamic> data = json.decode(cachedJson);
      return data.map((j) => DiscoveryPlace.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<DiscoveryPlace>> getAssetPlaces() async {
    // Option A: Zero-Bundle Strategy. No static JSON files are shipped in assets.
    // If remote fetches fail, check Level-1 cache or return empty list.

    // BUG-066: Return decoded model from cache if already processed
    if (_decodedCache.containsKey('places')) {
      return _decodedCache['places']!;
    }

    final String? cachedJson = TripCacheService.getGlobalData('places');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        // Exec #12: Offload JSON decode and model parsing to background isolate
        final places = await compute(_decodeCachedPlaces, cachedJson);
        _decodedCache['places'] = places; // Store decoded result for reuse
        return places;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void cacheInMemory(String key, List<DiscoveryPlace> places) {
    _memCache[key] = places;
    // BUG-066: Also update decoded cache so getAssetPlaces returns fresh data
    _decodedCache[key] = places;
  }

  List<DiscoveryPlace>? getFromMemory(String key) {
    return _memCache[key];
  }

  void clearMemory() {
    _memCache.clear();
    _decodedCache.clear(); // BUG-066: Clear decoded cache too
  }

  // BUG-045: Immediately invalidate L0 RAM cache and cancel pending debounces upon manual place mutation
  void invalidateCache() {
    clearMemory();
    _diskWriteDebounce?.cancel();
    _pendingKey = null;
    _pendingJson = null;
  }
}

