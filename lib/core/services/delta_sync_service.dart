import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';
import 'sqlite_storage_service.dart';
import '../config/app_config.dart';

class DeltaParseResult {
  final int newSyncVersion;
  final bool hasMore;
  final int nextCursor;
  final List<DiscoveryPlace> placesToUpsert;
  final List<String> deletedIds;

  DeltaParseResult({
    required this.newSyncVersion,
    required this.hasMore,
    required this.nextCursor,
    required this.placesToUpsert,
    required this.deletedIds,
  });
}

DeltaParseResult parseDeltaPayload(String body) {
  final Map<String, dynamic> payload = jsonDecode(body);
  final int newSyncVersion = payload['sync_version'] as int? ?? 0;
  final bool hasMore = payload['has_more'] as bool? ?? false;
  final int nextCursor = payload['next_cursor'] as int? ?? newSyncVersion;

  // Parse upserts
  final List<dynamic> upsertRaw = payload['upsert_places'] ?? [];
  final List<DiscoveryPlace> placesToUpsert = [];
  for (final item in upsertRaw) {
    try {
      placesToUpsert.add(DiscoveryPlace.fromJson(item as Map<String, dynamic>));
    } catch (_) {}
  }

  // Parse deletions
  final List<dynamic> deletedRaw = payload['deleted_ids'] ?? [];
  final List<String> deletedIds = deletedRaw.map((e) => e.toString()).toList();

  return DeltaParseResult(
    newSyncVersion: newSyncVersion,
    hasMore: hasMore,
    nextCursor: nextCursor,
    placesToUpsert: placesToUpsert,
    deletedIds: deletedIds,
  );
}

class DeltaSyncService {
  static final DeltaSyncService _instance = DeltaSyncService._internal();
  factory DeltaSyncService() => _instance;
  DeltaSyncService._internal();

  // Configurable base URL for Laravel backend
  static String get baseUrl => '${AppConfig.baseUrl}/places';
  static String get apiKey => AppConfig.hiddenGemsApiKey;

  final SqliteStorageService _sqliteService = SqliteStorageService();
  final DiscoveryLocalDataSource _localDataSource = DiscoveryLocalDataSource();

  // BUG-055: Synchronization lock — prevents parallel sync executions on double-tap
  bool _isSyncing = false;

  Future<Duration> _getDynamicTimeout() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return const Duration(seconds: 4); // WiFi is faster
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return const Duration(seconds: 10); // Mobile network (rural 2G/3G) needs more time
      }
    } catch (_) {}
    return const Duration(seconds: 5); // Fallback
  }

  /// Checks if server version is higher than local SQLite version.
  /// Enforces dynamic timeout based on network connection.
  Future<bool> checkForUpdates() async {
    try {
      final int localVersion = await _sqliteService.getLocalSyncVersion();
      final Uri url = Uri.parse('$baseUrl/check-version');
      final timeoutDuration = await _getDynamicTimeout();

      final http.Response response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': apiKey,
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final int serverVersion = data['version'] as int? ?? 0;
        SecureLogger.info("Version check — Local: $localVersion | Server: $serverVersion");
        return serverVersion > localVersion;
      }
    } on TimeoutException {
      SecureLogger.warning("Version check timed out. Proceeding in offline mode.");
    } catch (e) {
      SecureLogger.error("Failed version check ping", e);
    }
    return false;
  }

  /// BUG-150: Verifies local SQLite storage is accessible before any sync
  /// loop begins. Returns false if the DB cannot be queried, allowing callers
  /// to exit gracefully instead of crashing mid-loop.
  Future<bool> _isStorageReady() async {
    try {
      await _sqliteService.getLocalSyncVersion();
      return true;
    } catch (e) {
      SecureLogger.error('Delta sync: local SQLite storage is not ready — aborting sync.', e);
      return false;
    }
  }

  /// Executes chunked paginated delta sync from server.
  /// Handles first-boot full sync (since_version=0) and incremental updates.
  Future<int> performDeltaSync() async {
    // BUG-055: Guard against concurrent sync executions
    if (_isSyncing) {
      SecureLogger.warning('Delta sync already in progress — skipping duplicate invocation.');
      return await _sqliteService.getLocalSyncVersion();
    }

    // BUG-150: Verify local storage is ready before starting the sync loop.
    // If the SQLite DB is not accessible, abort early and return current version.
    if (!await _isStorageReady()) {
      SecureLogger.warning('Delta sync aborted: local storage not ready.');
      return 0;
    }

    _isSyncing = true;


    int currentVersion = await _sqliteService.getLocalSyncVersion();
    bool hasMore = true;
    int totalUpserted = 0;
    int totalPurged = 0;

    SecureLogger.info("Starting Delta Sync loop from local version: $currentVersion");

    try {
      while (hasMore) {
        final Uri url = Uri.parse('$baseUrl/delta?since_version=$currentVersion&limit=100');
        final timeoutDuration = await _getDynamicTimeout();

        final http.Response response = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            'X-API-KEY': apiKey,
          },
        ).timeout(timeoutDuration);

        if (response.statusCode != 200) {
          SecureLogger.error("Delta endpoint returned status: ${response.statusCode}");
          break;
        }

        // Offload payload parsing and json decoding to background isolate
        final DeltaParseResult parseResult = await compute(parseDeltaPayload, response.body);
        final int nextCursor = parseResult.nextCursor;
        hasMore = parseResult.hasMore;
        final List<DiscoveryPlace> placesToUpsert = parseResult.placesToUpsert;
        final List<String> deletedIds = parseResult.deletedIds;

        // Commit to SQLite
        if (placesToUpsert.isNotEmpty) {
          await _sqliteService.upsertPlaces(placesToUpsert, nextCursor);
          totalUpserted += placesToUpsert.length;
        }
        if (deletedIds.isNotEmpty) {
          await _sqliteService.purgeDeletedPlaces(deletedIds);
          totalPurged += deletedIds.length;
        }

        // BUG-070: Only advance the cursor in memory during the loop;
        // the final version is committed once after all chunks complete.
        currentVersion = nextCursor;

        SecureLogger.info('Chunk synced: +$totalUpserted places, -$totalPurged purged -> cursor: $currentVersion');
      }

      // BUG-070: Persist the sync version only after the full batch completes
      // to prevent partial data from being seen as fully synced on interruption.
      await _sqliteService.setLocalSyncVersion(currentVersion);
      SecureLogger.info('Delta Sync complete -> Version committed: $currentVersion');
    } on TimeoutException {
      SecureLogger.warning('Delta sync timed out during chunk fetch. Stopping sync gracefully.');
    } catch (e) {
      SecureLogger.error('Exception during delta synchronization loop', e);
    } finally {
      // BUG-055: Always release the lock when done
      _isSyncing = false;
    }

    return currentVersion;
  }

  /// Hydrates active SQLite records into Level-0 RAM cache (_memCache)
  /// for estimated <50ms UI response times.
  Future<List<DiscoveryPlace>> hydrateMemoryCache() async {
    SecureLogger.info("Hydrating SQLite records into memory cache...");
    final List<DiscoveryPlace> places = await _sqliteService.getActivePlaces();
    _localDataSource.cacheInMemory('places', places);
    SecureLogger.info("RAM cache hydrated with ${places.length} active places.");
    return places;
  }
}
