import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
  /// write has finished.  Errors are caught and re-thrown but do NOT
  /// poison the queue for subsequent writers.
  Future<T> _enqueueWrite<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
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
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_counter (
            id INTEGER PRIMARY KEY DEFAULT 1,
            current_version INTEGER DEFAULT 0
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

  Future<int> getLocalSyncVersion() async {
    // BUG-090: Query inside the writeQueue to block read until all pending writes finish,
    // avoiding reading old version status due to write commits delay.
    final completer = Completer<int>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final db = await database;
        final List<Map<String, dynamic>> result = await db.query(
          'sync_counter',
          columns: ['current_version'],
          where: 'id = ?',
          whereArgs: [1],
        );
        if (result.isNotEmpty) {
          completer.complete(result.first['current_version'] as int? ?? 0);
        } else {
          completer.complete(0);
        }
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
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

  // BUG-107 / BUG-127 / BUG-147: Serialised through write queue so that
  // simultaneous sync calls never write over each other.
  Future<void> upsertPlaces(List<DiscoveryPlace> places, int syncVersion) {
    if (places.isEmpty) return Future.value();
    return _enqueueWrite(() async {
      final db = await database;
      await db.transaction((txn) async {
        for (final place in places) {
          try {
            final String rawJson = jsonEncode(place.toJson());
            await txn.insert(
              'places',
              {
                'id': place.id,
                'name': place.name,
                'district': place.district,
                'category': place.category,
                'lat': place.lat,
                'lng': place.lng,
                'sync_version': syncVersion,
                'is_deleted': 0,
                'raw_json': rawJson,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            SecureLogger.error("Failed to serialize or insert place ID: ${place.id}", e);
          }
        }
      });
    });
  }

  Future<void> purgeDeletedPlaces(List<String> deletedIds) {
    if (deletedIds.isEmpty) return Future.value();
    return _enqueueWrite(() async {
      final db = await database;

      // Write deletions to SQLite — serialised via write queue (BUG-107/127/147)
      await db.transaction((txn) async {
        for (final id in deletedIds) {
          await txn.update(
            'places',
            {'is_deleted': 1},
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

  Future<List<DiscoveryPlace>> getActivePlaces() async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'places',
      where: 'is_deleted = ?',
      whereArgs: [0],
    );
    
    final List<DiscoveryPlace> places = [];
    for (final row in rows) {
      try {
        final rawJson = row['raw_json'];
        if (rawJson is String && rawJson.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(rawJson);
          places.add(DiscoveryPlace.fromJson(data));
        } else {
          SecureLogger.warning("Corrupted or empty raw_json in SQLite place row: ${row['id']}");
        }
      } catch (e) {
        SecureLogger.error("Failed to decode SQLite place row: ${row['id']}", e);
      }
    }
    return places;
  }

  Future<void> clearDatabase() {
    return _enqueueWrite(() async {
      final db = await database;
      await db.delete('places');
      await db.delete('place_images');
      await db.update('sync_counter', {'current_version': 0}, where: 'id = ?', whereArgs: [1]);
      // BUG-067: Close the database connection after cleanup to prevent lock races
      await db.close();
      _database = null;
    });
  }
}
