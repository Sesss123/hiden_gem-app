import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/discovery_place.dart';
import '../datasources/discovery_remote_datasource.dart';
import '../datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';
import '../../core/config/remote_config_service.dart';

final discoveryRemoteDataSourceProvider = Provider((ref) => DiscoveryRemoteDataSource());
final discoveryLocalDataSourceProvider = Provider((ref) => DiscoveryLocalDataSource());

final discoveryRepositoryProvider = Provider((ref) => DiscoveryRepository(
  remoteDataSource: ref.watch(discoveryRemoteDataSourceProvider),
  localDataSource: ref.watch(discoveryLocalDataSourceProvider),
));

class DiscoveryRepository {
  final DiscoveryRemoteDataSource _remoteDataSource;
  final DiscoveryLocalDataSource _localDataSource;

  DiscoveryRepository({
    required DiscoveryRemoteDataSource remoteDataSource,
    required DiscoveryLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  Future<Position?> getCurrentLocation() => _remoteDataSource.getCurrentLocation();

  Future<List<DiscoveryPlace>> getDiscoveryPlaces({
    double? userLat,
    double? userLng,
    bool forceRefresh = false,
  }) async {
    List<DiscoveryPlace> places = [];
    
    // 1. Memory Cache check (L0)
    final cacheKey = 'places_${userLat}_$userLng';
    if (!forceRefresh) {
      final memCache = _localDataSource.getFromMemory(cacheKey);
      if (memCache != null) {
        SecureLogger.info("Discovery data loaded from Level-0 Memory Cache.");
        return memCache;
      }
    }

    // 2. GeoHash Firestore check (L1) - if location available
    if (userLat != null && userLng != null) {
      try {
        final position = Position(
          latitude: userLat, 
          longitude: userLng, 
          timestamp: DateTime.now(), 
          accuracy: 0, 
          altitude: 0, 
          heading: 0, 
          speed: 0, 
          speedAccuracy: 0, 
          altitudeAccuracy: 0, 
          headingAccuracy: 0
        );
        places = await _remoteDataSource.fetchNearbyPlacesFirestore(center: position);
        if (places.isNotEmpty) {
          SecureLogger.info("Discovery data loaded from Level-1 GeoHash Firestore.");
          // Still need to sort and cache
          places = await _processPlaces(places, userLat, userLng);
          _localDataSource.cacheInMemory(cacheKey, places);
          return places;
        }
      } catch (e) {
        SecureLogger.error("GeoHash Firestore fetch failed, falling back to REST", e);
      }
    }

    // 3. REST API / Persistent Cache check (L2/L3)
    try {
      final String? cachedJson = _localDataSource.getCachedPlaces('places');
      final remoteConfig = await RemoteConfigService.getInstance();
      final remoteTimestamp = remoteConfig.dataRefreshTimestamp;
      final localTimestamp = _localDataSource.getCacheTimestamp('places');

      bool useCache = !forceRefresh && cachedJson != null;
      if (useCache && !_localDataSource.isCacheValid('places', const Duration(hours: 12))) {
        // TTL expired, check remote config timestamp
        if (localTimestamp < remoteTimestamp) {
          useCache = false; // Need hard refresh
        }
      }

      if (useCache) {
        SecureLogger.info("Discovery data loaded from Level-2 Persistent Cache.");
        places = await _parsePlaces(json.decode(cachedJson!));
      } else {
        SecureLogger.info("Fetching discovery data from Level-3 REST API...");
        final String remoteJson = await _remoteDataSource.fetchPlacesRest();
        await _localDataSource.cachePlaces('places', remoteJson);
        places = await _parsePlaces(json.decode(remoteJson));
      }
    } catch (e) {
      SecureLogger.error("REST/Cache fetch failed, falling back to assets", e);
      places = await _localDataSource.getAssetPlaces();
    }

    // 4. Processing (Distance measurement & Sorting)
    places = await _processPlaces(places, userLat, userLng);
    
    // 5. Update Memory Cache
    _localDataSource.cacheInMemory(cacheKey, places);
    return places;
  }

  Future<List<DiscoveryPlace>> getAiRecommendations(List<DiscoveryPlace> places, {String? customQuery}) async {
    if (places.isEmpty) return [];
    
    // In a real app, this logic might be more complex, but we'll follow similar logic to service
    final topNearest = places.take(10).toList();
    final vibeText = customQuery ?? "default vibe"; // Normally from preference service
    
    try {
      final List<Map<String, dynamic>> results = await _remoteDataSource.getAiRecommendationsRaw(
        nearbyPlaces: topNearest, 
        vibeText: vibeText
      );
      
      final recommended = <DiscoveryPlace>[];
      for (var result in results) {
        try {
          final place = topNearest.firstWhere((p) => p.id == result['id'].toString());
          place.aiReason = result['reason']?.toString() ?? '';
          recommended.add(place);
        } catch (_) {}
      }
      return recommended.isEmpty ? topNearest.take(3).toList() : recommended;
    } catch (e) {
      SecureLogger.error("AI recommendations failed", e);
      return topNearest.take(3).toList();
    }
  }

  // --- Private Helpers ---

  Future<List<DiscoveryPlace>> _parsePlaces(dynamic data) async {
    if (data is List && data.length > 50) {
      return await compute(_parsePlacesIsolate, data);
    } else {
      return (data as List).map((j) => DiscoveryPlace.fromJson(j)).toList();
    }
  }

  Future<List<DiscoveryPlace>> _processPlaces(List<DiscoveryPlace> places, double? lat, double? lng) async {
    if (lat == null || lng == null) return places;

    return await compute(_sortPlacesIsolate, {
      'places': places,
      'lat': lat,
      'lng': lng,
    });
  }

  static List<DiscoveryPlace> _parsePlacesIsolate(dynamic data) {
    return (data as List).map((json) => DiscoveryPlace.fromJson(json)).toList();
  }

  static List<DiscoveryPlace> _sortPlacesIsolate(Map<String, dynamic> params) {
    final List<DiscoveryPlace> places = params['places'];
    final double lat = params['lat'];
    final double lng = params['lng'];

    for (var place in places) {
      final distanceMeters = Geolocator.distanceBetween(
        lat, lng, place.lat, place.lng,
      );
      place.distanceKm = distanceMeters / 1000.0;
    }
    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places;
  }
}
