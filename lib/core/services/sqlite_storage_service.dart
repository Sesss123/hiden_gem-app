import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/discovery_place.dart';
import '../../data/datasources/discovery_local_datasource.dart';
import '../../core/utils/secure_logger.dart';

class SqliteStorageService {
  static final SqliteStorageService _instance = SqliteStorageService._internal();
  factory SqliteStorageService() => _instance;
  SqliteStorageService._internal();

  static Database? _database;

  // BUG-087 / BUG-107 / BUG-127 / BUG-147:
  // Write queue that serialises all database write operations so that
  // concurrent callers never overlap. Uses a Future chain (Dart's lock-free
  // mutex idiom) — no external packages required.
  Future<void> _writeQueue = Future.value();

  /// Enqueue [operation] so it runs only after every previously-queued
  /// write has finished. Errors are caught and re-thrown but do NOT
  /// poison the queue for subsequent writers (Exec #4 / Audit #22).
  Future<T> _enqueueWrite<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final result = await operation();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    }).catchError((e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    });
    return completer.future;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, 'hidden_gems_sl_v1.db');

    SecureLogger.info("Initializing SQLite Storage Engine at: $path");

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.rawQuery('PRAGMA journal_mode = WAL;');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_quarantine (
            id TEXT PRIMARY KEY,
            name TEXT,
            sync_version INTEGER DEFAULT 0,
            raw_json TEXT NOT NULL,
            reason TEXT NOT NULL,
            failed_at TEXT NOT NULL
          );
        ''');
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_counter (
            id INTEGER PRIMARY KEY DEFAULT 1,
            current_version INTEGER DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_quarantine (
            id TEXT PRIMARY KEY,
            name TEXT,
            sync_version INTEGER DEFAULT 0,
            raw_json TEXT NOT NULL,
            reason TEXT NOT NULL,
            failed_at TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS places (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            district TEXT,
            category TEXT,
            lat REAL,
            lng REAL,
            sync_version INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            raw_json TEXT NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS place_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            place_id TEXT NOT NULL,
            image_path TEXT NOT NULL,
            thumb_path TEXT NOT NULL,
            is_cover INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            sync_version INTEGER DEFAULT 0,
            FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_places_sync_version ON places(sync_version);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_places_is_deleted ON places(is_deleted);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_place_images_place_id ON place_images(place_id);');

        // Initialize sync_counter row
        await db.insert('sync_counter', {'id': 1, 'current_version': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        SecureLogger.info("Upgrading SQLite database from $oldVersion to $newVersion");
      },
    );
  }

  Future<int> getLocalSyncVersion() {
    // BUG-090 / Exec #4: Query inside the writeQueue to block read until all pending writes finish,
    // avoiding reading old version status due to write commits delay.
    return _enqueueWrite(() async {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'sync_counter',
        columns: ['current_version'],
        where: 'id = ?',
        whereArgs: [1],
      );
      if (result.isNotEmpty) {
        return result.first['current_version'] as int? ?? 0;
      } else {
        return 0;
      }
    });
  }

  // BUG-087: Wrap sync version update in a write-queue + explicit transaction
  // so concurrent callers cannot interleave and produce state mismatches.
  Future<void> setLocalSyncVersion(int version) {
    return _enqueueWrite(() async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert(
          'sync_counter',
          {'id': 1, 'current_version': version},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    });
  }

  static List<String> _encodePlaces(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((m) => jsonEncode(m)).toList();
  }

  // BUG-107 / BUG-127 / BUG-147 / Exec #7 / Exec #9: Serialised through write queue.
  // Uses background isolate compute for JSON encoding to prevent UI thread ANRs.
  Future<void> upsertPlaces(List<DiscoveryPlace> places, int syncVersion) {
    if (places.isEmpty) return Future.value();
    return _enqueueWrite(() async {
      final db = await database;
      final List<Map<String, dynamic>> mapList = places.map((p) => p.toJson()).toList();
      final List<String> encodedList = await compute(_encodePlaces, mapList);

      await db.transaction((txn) async {
        for (int i = 0; i < places.length; i++) {
          final place = places[i];
          final rawJson = encodedList[i];
          try {
            await txn.insert(
              'places',
              {
                'id': place.id,
                'name': place.name,
                'district': place.district,
                'category': place.category,
                'lat': place.lat,
                'lng': place.lng,
                'sync_version': place.syncVersion > 0 ? place.syncVersion : syncVersion,
                'is_deleted': 0,
                'raw_json': rawJson,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            await txn.delete('place_images', where: 'place_id = ?', whereArgs: [place.id]);
            for (int imgIdx = 0; imgIdx < place.images.length; imgIdx++) {
              final img = place.images[imgIdx];
              await txn.insert(
                'place_images',
                {
                  'place_id': place.id,
                  'image_path': img.fullPath,
                  'thumb_path': img.thumbPath,
                  'is_cover': img.isCover ? 1 : 0,
                  'sort_order': imgIdx + 1,
                  'sync_version': place.syncVersion > 0 ? place.syncVersion : syncVersion,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

            // If insertion succeeded, remove from quarantine if previously quarantined
            try {
              await txn.delete('sync_quarantine', where: 'id = ?', whereArgs: [place.id]);
            } catch (_) {}
          } catch (e) {
            SecureLogger.error("Failed to insert place ID: ${place.id}", e);
            try {
              await txn.insert(
                'sync_quarantine',
                {
                  'id': place.id,
                  'name': place.name,
                  'sync_version': place.syncVersion > 0 ? place.syncVersion : syncVersion,
                  'raw_json': rawJson,
                  'reason': 'SQLite insert error: $e',
                  'failed_at': DateTime.now().toIso8601String(),
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            } catch (qErr) {
              SecureLogger.error("Failed to quarantine place ID: ${place.id}", qErr);
            }
          }
        }
      });
    });
  }

  /// Quarantines multiple failed items in a single transaction.
  Future<void> quarantineItems(List<Map<String, dynamic>> failedItems) {
    if (failedItems.isEmpty) return Future.value();
    return _enqueueWrite(() async {
      final db = await database;
      await db.transaction((txn) async {
        for (final item in failedItems) {
          await txn.insert(
            'sync_quarantine',
            {
              'id': item['id']?.toString() ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
              'name': item['name']?.toString() ?? 'Unknown Place',
              'sync_version': (item['sync_version'] as num?)?.toInt() ?? 0,
              'raw_json': item['raw_json'] is String ? item['raw_json'] : jsonEncode(item['raw_json'] ?? item),
              'reason': item['reason']?.toString() ?? 'Unknown error',
              'failed_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    });
  }

  /// Requirement 4: Diagnostic/debug method to list places that failed to sync.
  Future<List<Map<String, dynamic>>> getSyncFailureLog() {
    return _enqueueWrite(() async {
      final db = await database;
      return await db.query(
        'sync_quarantine',
        orderBy: 'failed_at DESC',
      );
    });
  }

  /// Retries parsing and inserting quarantined items.
  /// Returns the number of items successfully recovered.
  Future<int> retryQuarantinedItems() {
    return _enqueueWrite(() async {
      final db = await database;
      final List<Map<String, dynamic>> quarantined = await db.query('sync_quarantine');
      if (quarantined.isEmpty) return 0;

      int recoveredCount = 0;
      for (final row in quarantined) {
        final String id = row['id'] as String;
        final String rawJsonStr = row['raw_json'] as String;
        final int syncVer = (row['sync_version'] as num?)?.toInt() ?? 0;

        try {
          final Map<String, dynamic> data = jsonDecode(rawJsonStr);
          final place = DiscoveryPlace.fromJson(data);

          // Attempt insertion
          await db.transaction((txn) async {
            await txn.insert(
              'places',
              {
                'id': place.id,
                'name': place.name,
                'district': place.district,
                'category': place.category,
                'lat': place.lat,
                'lng': place.lng,
                'sync_version': place.syncVersion > 0 ? place.syncVersion : syncVer,
                'is_deleted': 0,
                'raw_json': rawJsonStr,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            await txn.delete('place_images', where: 'place_id = ?', whereArgs: [place.id]);
            for (int imgIdx = 0; imgIdx < place.images.length; imgIdx++) {
              final img = place.images[imgIdx];
              await txn.insert(
                'place_images',
                {
                  'place_id': place.id,
                  'image_path': img.fullPath,
                  'thumb_path': img.thumbPath,
                  'is_cover': img.isCover ? 1 : 0,
                  'sort_order': imgIdx + 1,
                  'sync_version': place.syncVersion > 0 ? place.syncVersion : syncVer,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          });

          // Successfully inserted! Remove from quarantine
          await db.delete('sync_quarantine', where: 'id = ?', whereArgs: [id]);
          recoveredCount++;
          SecureLogger.info("Successfully recovered quarantined place ID: $id");
        } catch (e) {
          SecureLogger.warning("Retry failed for quarantined place ID: $id ($e)");
        }
      }
      return recoveredCount;
    });
  }

  Future<List<Map<String, dynamic>>> getPlaceImages(String placeId) {
    return _enqueueWrite(() async {
      final db = await database;
      return await db.query(
        'place_images',
        where: 'place_id = ?',
        whereArgs: [placeId],
        orderBy: 'sort_order ASC',
      );
    });
  }

  // Exec #11 / Audit #10: Replace soft-delete update with physical delete to prevent SQLite bloat
  Future<void> purgeDeletedPlaces(List<String> deletedIds) {
    if (deletedIds.isEmpty) return Future.value();
    return _enqueueWrite(() async {
      final db = await database;

      // Write physical deletions to SQLite — serialised via write queue
      await db.transaction((txn) async {
        for (final id in deletedIds) {
          await txn.delete(
            'places',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });

      // BUG-052: Also evict purged items from in-memory cache so UI stays consistent
      final localDataSource = DiscoveryLocalDataSource();
      final cached = localDataSource.getFromMemory('places');
      if (cached != null) {
        final deletedSet = deletedIds.toSet();
        final updated = cached.where((p) => !deletedSet.contains(p.id)).toList();
        localDataSource.cacheInMemory('places', updated);
        SecureLogger.info('BUG-052: Evicted ${deletedIds.length} purged places from memory cache.');
      }
    });
  }

  static List<DiscoveryPlace> _decodePlaces(List<String> rawJsonList) {
    final List<DiscoveryPlace> places = [];
    for (final rawJson in rawJsonList) {
      try {
        if (rawJson.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(rawJson);
          places.add(DiscoveryPlace.fromJson(data));
        }
      } catch (e) {
        // ignore malformed rows during background decode
      }
    }
    return places;
  }

  // Exec #7: Move JSON decoding to background isolate using compute
  Future<List<DiscoveryPlace>> getActivePlaces() {
    return _enqueueWrite(() async {
      final db = await database;
      final List<Map<String, dynamic>> rows = await db.query(
        'places',
        where: 'is_deleted = ?',
        whereArgs: [0],
      );
      
      final List<String> rawJsonList = rows
          .map((row) => row['raw_json'] as String?)
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();

      return await compute(_decodePlaces, rawJsonList);
    });
  }

  // Exec #18: Wrap clearDatabase operations in db.transaction
  Future<void> clearDatabase() {
    return _enqueueWrite(() async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('places');
        await txn.delete('place_images');
        await txn.delete('sync_quarantine');
        await txn.update('sync_counter', {'current_version': 0}, where: 'id = ?', whereArgs: [1]);
      });
      // BUG-067: Close the database connection after cleanup to prevent lock races
      await db.close();
      _database = null;
    });
  }
}
