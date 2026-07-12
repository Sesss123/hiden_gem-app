import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/discovery_place.dart';
import '../datasources/discovery_remote_datasource.dart';
import '../datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';
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

    // Level-1 (Firestore GeoHash) has been REMOVED to eliminate massive Firestore billing costs.
    // The app now relies entirely on Level-2 SQLite + Background Delta Sync for all geo-spatial queries.

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
        // Background sync may pull in places added/changed on the server
        // after this session's RAM cache was already warmed. Once it
        // completes with real progress, invalidate the L0 memory cache so
        // the next getDiscoveryPlaces() call re-reads the updated SQLite
        // data instead of silently serving the pre-sync snapshot forever.
        final versionBeforeSync = await sqliteService.getLocalSyncVersion();
        unawaited(deltaService.performDeltaSync().then((newVersion) {
          if (newVersion != versionBeforeSync) {
            _localDataSource.invalidateCache();
            SecureLogger.info("Background delta sync brought new data (v$versionBeforeSync -> v$newVersion). Memory cache invalidated.");
          }
          return newVersion;
        }).catchError((e) {
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

    // 4. Fallback to Firestore / Assets if SQLite is completely empty and delta sync failed
    if (places.isEmpty) {
      try {
        SecureLogger.warning("SQLite / Delta Sync empty, falling back to Firestore 'places' collection");
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

  Future<List<DiscoveryPlace>> _processPlaces(List<DiscoveryPlace> places, double? lat, double? lng) async {
    if (lat == null || lng == null) return places;

    return await compute(_sortPlacesIsolate, {
      'places': places,
      'lat': lat,
      'lng': lng,
    });
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
