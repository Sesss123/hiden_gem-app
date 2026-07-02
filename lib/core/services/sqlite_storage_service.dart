import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../data/models/discovery_place.dart';
import '../../core/utils/secure_logger.dart';

class SqliteStorageService {
  static final SqliteStorageService _instance = SqliteStorageService._internal();
  factory SqliteStorageService() => _instance;
  SqliteStorageService._internal();

  static Database? _database;

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
    );
  }

  Future<int> getLocalSyncVersion() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'sync_counter',
      columns: ['current_version'],
      where: 'id = ?',
      whereArgs: [1],
    );
    if (result.isNotEmpty) {
      return result.first['current_version'] as int? ?? 0;
    }
    return 0;
  }

  Future<void> setLocalSyncVersion(int version) async {
    final db = await database;
    await db.insert(
      'sync_counter',
      {'id': 1, 'current_version': version},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertPlaces(List<DiscoveryPlace> places, int syncVersion) async {
    if (places.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final place in places) {
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
      }
    });
  }

  Future<void> purgeDeletedPlaces(List<String> deletedIds) async {
    if (deletedIds.isEmpty) return;
    final db = await database;
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
        final String rawJson = row['raw_json'] as String;
        final Map<String, dynamic> data = jsonDecode(rawJson);
        places.add(DiscoveryPlace.fromJson(data));
      } catch (e) {
        SecureLogger.error("Failed to decode SQLite place row: ${row['id']}", e);
      }
    }
    return places;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('places');
    await db.delete('place_images');
    await db.update('sync_counter', {'current_version': 0}, where: 'id = ?', whereArgs: [1]);
  }
}
