import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/discovery_place.dart';
import '../datasources/discovery_remote_datasource.dart';
import '../datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';
import '../../core/config/remote_config_service.dart';
import '../../core/services/delta_sync_service.dart';
import '../../core/services/sqlite_storage_service.dart';
import '../../core/utils/result.dart';

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

  Future<Result<List<DiscoveryPlace>, AppError>> getDiscoveryPlaces({
    double? userLat,
    double? userLng,
    bool forceRefresh = false,
  }) async {
    List<DiscoveryPlace> places = [];
    
    // 1. Memory Cache check (L0) - Rounded coordinates to 3 decimal places (~110m bucket)
    final latKey = userLat?.toStringAsFixed(3) ?? 'null';
    final lngKey = userLng?.toStringAsFixed(3) ?? 'null';
    final cacheKey = 'places_${latKey}_$lngKey';

    if (!forceRefresh) {
      final memCache = _localDataSource.getFromMemory(cacheKey);
      if (memCache != null && memCache.isNotEmpty) {
        SecureLogger.info("Discovery data loaded from Level-0 Memory Cache.");
        return Success(memCache);
      }
    }

    // 2. GeoHash Firestore check (L1) - if location available and Firebase is ready
    if (userLat != null && userLng != null && Firebase.apps.isNotEmpty) {
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
          places = await _processPlaces(places, userLat, userLng);
          _localDataSource.cacheInMemory(cacheKey, places);
          return Success(places);
        }
      } catch (e) {
        SecureLogger.warning("GeoHash Firestore fetch failed or offline, falling back to SQLite/REST: $e");
      }
    }

    // 3. SQLite / Delta Sync check (L2)
    try {
      final sqliteService = SqliteStorageService();
      final deltaService = DeltaSyncService();
      
      places = await sqliteService.getActivePlaces();

      // Exec #15: If SQLite is empty (first boot) or forceRefresh requested, await delta sync.
      // Otherwise, serve SQLite data immediately and run delta sync in background unawaited.
      if (places.isEmpty || forceRefresh) {
        SecureLogger.info("SQLite empty or forceRefresh requested. Awaiting delta sync...");
        await deltaService.performDeltaSync(forceFullResync: forceRefresh);
        places = await sqliteService.getActivePlaces();
      } else {
        unawaited(deltaService.performDeltaSync().catchError((e) {
          SecureLogger.warning("Background delta sync failed: $e");
          return 0;
        }));
      }

      if (places.isNotEmpty) {
        SecureLogger.info("Discovery data loaded from Level-2 SQLite Storage.");
      }
    } catch (e) {
      SecureLogger.warning("SQLite / Delta sync fetch failed, falling back to L3 REST: $e");
    }

    // 4. REST API / Persistent Cache check (L3) if SQLite returned empty
    if (places.isEmpty) {
      try {
        final String? cachedJson = _localDataSource.getCachedPlaces('places');
        final remoteConfig = await RemoteConfigService.getInstance();
        final remoteTimestamp = remoteConfig.dataRefreshTimestamp;
        final localTimestamp = _localDataSource.getCacheTimestamp('places');

        bool useCache = !forceRefresh && cachedJson != null;
        if (useCache && !_localDataSource.isCacheValid('places', const Duration(hours: 12))) {
          if (localTimestamp < remoteTimestamp) {
            useCache = false;
          }
        }

        if (useCache) {
          SecureLogger.info("Discovery data loaded from Level-3 Persistent Cache.");
          places = await _parsePlaces(json.decode(cachedJson!));
        } else {
          SecureLogger.info("Fetching discovery data from Level-3 REST API...");
          final String remoteJson = await _remoteDataSource.fetchPlacesRest();
          await _localDataSource.cachePlaces('places', remoteJson);
          places = await _parsePlaces(json.decode(remoteJson));
        }
      } catch (e) {
        SecureLogger.warning("REST/Cache fetch failed, falling back to Firestore places collection: $e");
        try {
          places = await _remoteDataSource.fetchAllPlacesFirestore();
          if (places.isNotEmpty) {
            SecureLogger.info("Discovery data loaded from Firestore 'places' collection.");
          } else {
            places = await _localDataSource.getAssetPlaces();
          }
        } catch (e2) {
          SecureLogger.warning("Firestore fetch failed, falling back to assets: $e2");
          places = await _localDataSource.getAssetPlaces();
        }
      }
    }

    if (places.isEmpty) {
      SecureLogger.error("All discovery tiers failed (including asset fallback). No data available.", null);
      return Failure(AppError("Unable to load discovery places from any data source."));
    }

    // 5. Processing (Distance measurement & Sorting)
    places = await _processPlaces(places, userLat, userLng);
    
    // 6. Update Memory Cache
    _localDataSource.cacheInMemory(cacheKey, places);
    return Success(places);
  }

  Future<List<DiscoveryPlace>> getAiRecommendations(List<DiscoveryPlace> places, {String? customQuery}) async {
    if (places.isEmpty) return [];
    
    final topNearest = places.take(10).toList();
    
    // 🚧 AI Recommendations Model & API Key in Development — Coming Soon!
    // Skip upstream network call completely to avoid 10s timeout and return local nearest places immediately.
    return topNearest.take(3).toList();

    /*
    final vibeText = customQuery ?? "default vibe";
    try {
      final List<Map<String, dynamic>> results = await _remoteDataSource.getAiRecommendationsRaw(
        nearbyPlaces: topNearest, 
        vibeText: vibeText
      );
      
      final recommended = <DiscoveryPlace>[];
      for (var result in results) {
        try {
          final place = topNearest.firstWhereOrNull((p) => p.id == result['id'].toString());
          if (place != null) {
            place.aiReason = result['reason']?.toString() ?? '';
            recommended.add(place);
          }
        } catch (e) {
          SecureLogger.warning('Could not match AI recommended place ID: ${result['id']} - $e');
        }
      }
      return recommended.isEmpty ? topNearest.take(3).toList() : recommended;
    } catch (e) {
      SecureLogger.info("AI recommendations model offline or in development ($e). Using local nearest places fallback.");
      return topNearest.take(3).toList();
    }
    */
  }

  // --- Private Helpers ---

  Future<List<DiscoveryPlace>> _parsePlaces(dynamic data) async {
    if (data is! List) return [];
    final list = data.whereType<Map<String, dynamic>>().toList();
    if (list.length > 50) {
      return await compute(_parsePlacesIsolate, list);
    } else {
      return list.map((j) => DiscoveryPlace.fromJson(j)).toList();
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

  static List<DiscoveryPlace> _parsePlacesIsolate(List<Map<String, dynamic>> data) {
    return data.map((json) => DiscoveryPlace.fromJson(json)).toList();
  }

  static double _haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  static List<DiscoveryPlace> _sortPlacesIsolate(Map<String, dynamic> params) {
    final List<DiscoveryPlace> places = params['places'];
    final double lat = params['lat'];
    final double lng = params['lng'];

    for (var place in places) {
      // Exec #3 / Audit #8: Pure Dart Haversine formula prevents platform channel
      // MissingPluginException inside background Dart isolates.
      place.distanceKm = _haversineDistanceKm(lat, lng, place.lat, place.lng);
    }
    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places;
  }
}
