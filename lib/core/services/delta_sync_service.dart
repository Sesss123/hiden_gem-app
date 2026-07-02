import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/discovery_place.dart';
import '../../data/datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';
import 'sqlite_storage_service.dart';
import '../config/app_config.dart';

class DeltaSyncService {
  static final DeltaSyncService _instance = DeltaSyncService._internal();
  factory DeltaSyncService() => _instance;
  DeltaSyncService._internal();

  // Configurable base URL for Laravel backend
  static String get baseUrl => '${AppConfig.baseUrl}/places';
  static String get apiKey => AppConfig.hiddenGemsApiKey;

  final SqliteStorageService _sqliteService = SqliteStorageService();
  final DiscoveryLocalDataSource _localDataSource = DiscoveryLocalDataSource();

  /// Checks if server version is higher than local SQLite version.
  /// Enforces strict 2.5-second timeout for rural 2G/3G networks.
  Future<bool> checkForUpdates() async {
    try {
      final int localVersion = await _sqliteService.getLocalSyncVersion();
      final Uri url = Uri.parse('$baseUrl/check-version');

      final http.Response response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': apiKey,
        },
      ).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final int serverVersion = data['version'] as int? ?? 0;
        SecureLogger.info("Version check — Local: $localVersion | Server: $serverVersion");
        return serverVersion > localVersion;
      }
    } on TimeoutException {
      SecureLogger.warning("Version check timed out (2.5s limit). Proceeding in offline mode.");
    } catch (e) {
      SecureLogger.error("Failed version check ping", e);
    }
    return false;
  }

  /// Executes chunked paginated delta sync from server.
  /// Handles first-boot full sync (since_version=0) and incremental updates.
  Future<int> performDeltaSync() async {
    int currentVersion = await _sqliteService.getLocalSyncVersion();
    bool hasMore = true;
    int totalUpserted = 0;
    int totalPurged = 0;

    SecureLogger.info("Starting Delta Sync loop from local version: $currentVersion");

    try {
      while (hasMore) {
        final Uri url = Uri.parse('$baseUrl/delta?since_version=$currentVersion&limit=100');

        final http.Response response = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            'X-API-KEY': apiKey,
          },
        ).timeout(const Duration(milliseconds: 2500));

        if (response.statusCode != 200) {
          SecureLogger.error("Delta endpoint returned status: \${response.statusCode}");
          break;
        }

        final Map<String, dynamic> payload = jsonDecode(response.body);
        final int newSyncVersion = payload['sync_version'] as int? ?? currentVersion;
        hasMore = payload['has_more'] as bool? ?? false;
        final int nextCursor = payload['next_cursor'] as int? ?? newSyncVersion;

        // Parse upserts
        final List<dynamic> upsertRaw = payload['upsert_places'] ?? [];
        final List<DiscoveryPlace> placesToUpsert = [];
        for (final item in upsertRaw) {
          try {
            placesToUpsert.add(DiscoveryPlace.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            SecureLogger.error("Error parsing delta place item", e);
          }
        }

        // Parse deletions (Omitted/empty if since_version == 0 per Rule 3 optimization)
        final List<dynamic> deletedRaw = payload['deleted_ids'] ?? [];
        final List<String> deletedIds = deletedRaw.map((e) => e.toString()).toList();

        // Commit to SQLite
        if (placesToUpsert.isNotEmpty) {
          await _sqliteService.upsertPlaces(placesToUpsert, nextCursor);
          totalUpserted += placesToUpsert.length;
        }
        if (deletedIds.isNotEmpty) {
          await _sqliteService.purgeDeletedPlaces(deletedIds);
          totalPurged += deletedIds.length;
        }

        // Advance sequence counter
        currentVersion = nextCursor;
        await _sqliteService.setLocalSyncVersion(currentVersion);

        SecureLogger.info("Chunk synced: +$totalUpserted places, -$totalPurged purged -> Version: $currentVersion");
      }
    } on TimeoutException {
      SecureLogger.warning("Delta sync timed out during chunk fetch. Stopping sync gracefully.");
    } catch (e) {
      SecureLogger.error("Exception during delta synchronization loop", e);
    }

    return currentVersion;
  }

  /// Hydrates active SQLite records into Level-0 RAM cache (_memCache)
  /// for estimated <50ms UI response times.
  Future<List<DiscoveryPlace>> hydrateMemoryCache() async {
    SecureLogger.info("Hydrating SQLite records into memory cache...");
    final List<DiscoveryPlace> places = await _sqliteService.getActivePlaces();
    _localDataSource.cacheInMemory('places', places);
    SecureLogger.info("RAM cache hydrated with \${places.length} active places.");
    return places;
  }
}
