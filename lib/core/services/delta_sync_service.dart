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
import '../network/secure_http_client.dart';

class DeltaParseResult {
  final int newSyncVersion;
  final bool hasMore;
  final int nextCursor;
  final List<DiscoveryPlace> placesToUpsert;
  final List<String> deletedIds;
  final List<Map<String, dynamic>> failedItems;

  DeltaParseResult({
    required this.newSyncVersion,
    required this.hasMore,
    required this.nextCursor,
    required this.placesToUpsert,
    required this.deletedIds,
    required this.failedItems,
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
  final List<Map<String, dynamic>> failedItems = [];

  for (final item in upsertRaw) {
    if (item is Map<String, dynamic>) {
      try {
        placesToUpsert.add(DiscoveryPlace.fromJson(item));
      } catch (e, st) {
        // Requirement 1: Collect failed items alongside successful ones and log with SecureLogger
        final String placeId = item['id']?.toString() ?? 'unknown';
        final String placeName = item['name']?.toString() ?? 'Unknown Place';
        final int itemVersion = (item['sync_version'] as num?)?.toInt() ?? (item['syncVersion'] as num?)?.toInt() ?? nextCursor;
        
        SecureLogger.error(
          "Delta sync parse failure for Place ID: $placeId ($placeName). Reason: $e",
          e,
          st,
          "DeltaSync",
        );

        failedItems.add({
          'id': placeId,
          'name': placeName,
          'sync_version': itemVersion,
          'raw_json': item,
          'reason': 'JSON Parse Error: $e',
        });
      }
    } else {
      SecureLogger.error("Delta sync received non-map item in upsert_places: $item", null, null, "DeltaSync");
    }
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
    failedItems: failedItems,
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
  final SecureHttpClient _client = SecureHttpClient(http.Client());

  // BUG-055: Synchronization lock — prevents parallel sync executions on double-tap
  bool _isSyncing = false;

  Future<Duration> _getDynamicTimeout() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return const Duration(seconds: 15); // WiFi / Local dev server
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return const Duration(seconds: 15); // Mobile network (rural 2G/3G) needs more time
      }
    } catch (_) {}
    return const Duration(seconds: 15); // Fallback
  }

  /// Checks if server version is higher than local SQLite version.
  /// Enforces dynamic timeout based on network connection.
  Future<bool> checkForUpdates() async {
    try {
      final int localVersion = await _sqliteService.getLocalSyncVersion();
      final Uri url = Uri.parse('$baseUrl/check-version');
      final timeoutDuration = await _getDynamicTimeout();

      final http.Response response = await _client.get(
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
  /// When [forceFullResync] is true, resets cursor to 0 to self-heal any version tracking gaps.
  Future<int> performDeltaSync({bool forceFullResync = false}) async {
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

    int currentVersion = forceFullResync ? 0 : await _sqliteService.getLocalSyncVersion();
    bool hasMore = true;
    int totalUpserted = 0;
    int totalPurged = 0;

    SecureLogger.info("Starting Delta Sync loop from local version: $currentVersion (forceFullResync: $forceFullResync)");

    try {
      // IMPORTANT NOTE ON CURSOR ADVANCE & ERROR RECOVERY BEHAVIOR:
      // When performDeltaSync() executes, the sync cursor advances to nextCursor
      // after processing each chunk, regardless of whether individual items within
      // that chunk failed to parse or insert.
      //
      // Why? Because if we blocked cursor advancement due to a single malformed record
      // from MySQL (e.g. schema mismatch or missing non-null field), the ENTIRE delta sync
      // pipeline would halt indefinitely for all users, causing a complete denial-of-service
      // for any new places added after that malformed record!
      //
      // To prevent silent data loss while preserving sync progression:
      // 1. Any record that throws during DiscoveryPlace.fromJson() in parseDeltaPayload()
      //    is captured in `parseResult.failedItems` along with its raw JSON and reason.
      // 2. Any record that throws during SQLite insertion in upsertPlaces() is caught per-row.
      // 3. Both types of failures are immediately logged via SecureLogger and saved into a
      //    persistent SQLite `sync_quarantine` table (Strategy B & C).
      // 4. Quarantined records can be inspected via getSyncFailureLog() and retried later
      //    via retryQuarantinedItems() once the schema or backend data is fixed.
      // NEVER remove the quarantine mechanism or revert to silent catch (_) blocks!
      while (hasMore) {
        final Uri url = Uri.parse('$baseUrl/delta?since_version=$currentVersion&limit=100');
        final timeoutDuration = await _getDynamicTimeout();

        final http.Response response = await _client.get(
          url,
          headers: {
            'Accept': 'application/json',
            'X-API-KEY': apiKey,
          },
        ).timeout(timeoutDuration);

        if (response.statusCode != 200) {
          // Audit #4 & #6: Structured error logging and HTTP error code handling
          if (response.statusCode == 401 || response.statusCode == 403) {
            SecureLogger.error("Delta sync auth failure (${response.statusCode}) at url: $url");
          } else if (response.statusCode == 429) {
            SecureLogger.warning("Delta sync rate limited (429). Aborting loop gracefully to back off.");
          } else if (response.statusCode >= 500) {
            SecureLogger.error("Delta sync server error (${response.statusCode}) at url: $url | Body: ${response.body}");
          } else {
            SecureLogger.error("Delta endpoint returned HTTP ${response.statusCode} at url: $url");
          }
          break;
        }

        // Offload payload parsing and json decoding to background isolate
        final DeltaParseResult parseResult = await compute(parseDeltaPayload, response.body);
        final int nextCursor = parseResult.nextCursor;
        hasMore = parseResult.hasMore;
        final List<DiscoveryPlace> placesToUpsert = parseResult.placesToUpsert;
        final List<String> deletedIds = parseResult.deletedIds;
        final List<Map<String, dynamic>> failedItems = parseResult.failedItems;

        // Commit to SQLite
        if (placesToUpsert.isNotEmpty) {
          await _sqliteService.upsertPlaces(placesToUpsert, nextCursor);
          totalUpserted += placesToUpsert.length;
        }
        if (deletedIds.isNotEmpty) {
          await _sqliteService.purgeDeletedPlaces(deletedIds);
          totalPurged += deletedIds.length;
        }
        if (failedItems.isNotEmpty) {
          await _sqliteService.quarantineItems(failedItems);
          SecureLogger.warning("Quarantined ${failedItems.length} malformed places during sync chunk at cursor $nextCursor.");
        }

        currentVersion = nextCursor;

        // Audit #9: Checkpoint sync version after each chunk so progress is preserved on interruption.
        await _sqliteService.setLocalSyncVersion(currentVersion);

        SecureLogger.info('Chunk synced: +$totalUpserted places, -$totalPurged purged -> cursor committed: $currentVersion');
      }

      SecureLogger.info('Delta Sync complete -> Final version: $currentVersion');
    } on TimeoutException {
      SecureLogger.warning('Delta sync timed out during chunk fetch at version $currentVersion. Progress up to previous chunk was saved.');
    } catch (e) {
      SecureLogger.error('Exception during delta synchronization loop at version $currentVersion', e);
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

  /// Requirement 4: Diagnostic/debug method to list places that failed to sync.
  Future<List<Map<String, dynamic>>> getSyncFailureLog() {
    return _sqliteService.getSyncFailureLog();
  }

  /// Retries parsing and inserting items previously saved in the quarantine table.
  Future<int> retryQuarantinedItems() {
    return _sqliteService.retryQuarantinedItems();
  }
}
