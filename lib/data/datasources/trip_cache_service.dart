import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/trip_plan_model.dart';
import '../../core/utils/secure_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cache Read Result
// ─────────────────────────────────────────────────────────────────────────────

enum CacheReadResult { fresh, stale, miss }

class CachedPlanResult {
  final TripPlan? plan;
  final CacheReadResult state;
  const CachedPlanResult({required this.state, this.plan});

  bool get hasData => plan != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// TripMe.ai Offline Cache Service
//
// Privacy guarantee:
//   • ONLY stores: origin city (string), destination city (string), days (int),
//     budget (int), style (string), interests (list), transport (string), date (string).
//   • NEVER stores: raw GPS coordinates, device ID, account info, or any PII.
//   • Saved plans are user-initiated only (explicit bookmark action).
// ─────────────────────────────────────────────────────────────────────────────

class TripCacheService {
  static const String _lastPlanBox = 'tripme_last_plans';
  static const String _savedPlansBox = 'tripme_saved_plans';
  static const String _interestedEventsBox = 'tripme_interested_events';
  static const String _globalDataBox = 'tripme_global_data';
  static const String _savedFoodsBox = 'savor_lanka_saved_foods'; // Added for SL 2.0
  static const Duration _cacheTtl = Duration(days: 7);

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // ─── Initialisation ─────────────────────────────────────────────────────

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Setup AES Encryption using Secure Storage
      const secureStorage = FlutterSecureStorage();
      String? encryptionKeyString;
      
      try {
        // 🛡️ Safety: FlutterSecureStorage can fail on non-secure Web contexts or incognito
        encryptionKeyString = await secureStorage.read(key: 'tripme_hive_aes').timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint("Secure Storage failed: $e. Falling back to unencrypted storage for local development.");
      }

      HiveAesCipher? cipher;
      if (encryptionKeyString != null) {
        final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);
        cipher = HiveAesCipher(encryptionKeyUint8List);
      } else if (!kDebugMode) {
        // In release, if secure storage fails, we generate a new one if possible
        try {
          final key = Hive.generateSecureKey();
          await secureStorage.write(key: 'tripme_hive_aes', value: base64UrlEncode(key));
          cipher = HiveAesCipher(key);
        } catch (_) {}
      }

      _isInitialized = await _openBoxes(cipher);
    } catch (e) {
      SecureLogger.error("CRITICAL: Hive init failed", e);
      _isInitialized = false;
    }
  }

  static Future<bool> _openBoxes(HiveAesCipher? cipher) async {
    try {
      if (!Hive.isBoxOpen(_lastPlanBox)) {
        await Hive.openBox<String>(_lastPlanBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_savedPlansBox)) {
        await Hive.openBox<String>(_savedPlansBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_interestedEventsBox)) {
        await Hive.openBox<String>(_interestedEventsBox, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(_globalDataBox)) {
        await Hive.openBox<String>(_globalDataBox, encryptionCipher: cipher);
      }
      // Open the saved foods box
      if (!Hive.isBoxOpen(_savedFoodsBox)) {
        await Hive.openBox<String>(_savedFoodsBox, encryptionCipher: cipher);
      }
      return true;
    } catch (e) {
      SecureLogger.error("Failed to open encrypted Hive boxes. Deleting existing unencrypted data to upgrade.", e);
      try {
        await Hive.deleteBoxFromDisk(_lastPlanBox);
        await Hive.deleteBoxFromDisk(_savedPlansBox);
        await Hive.deleteBoxFromDisk(_interestedEventsBox);
        await Hive.deleteBoxFromDisk(_globalDataBox);
        await Hive.deleteBoxFromDisk(_savedFoodsBox); // Added
        
        await Hive.openBox<String>(_lastPlanBox, encryptionCipher: cipher);
        await Hive.openBox<String>(_savedPlansBox, encryptionCipher: cipher);
        await Hive.openBox<String>(_interestedEventsBox, encryptionCipher: cipher);
        await Hive.openBox<String>(_globalDataBox, encryptionCipher: cipher);
        await Hive.openBox<String>(_savedFoodsBox, encryptionCipher: cipher); // Added
        return true;
      } catch (e2) {
        SecureLogger.error("Hard failure opening storage.", e2);
        return false;
      }
    }
  }

  // ─── Deterministic Cache Key ─────────────────────────────────────────────
  // Hash of all request params so different trips never collide.

  static String buildCacheKey({
    required String origin,
    required String destination,
    required int days,
    required int budgetLkr,
    required String style,
    required List<String> interests,
    required String transport,
    required String startDate,
  }) {
    final raw =
        '${origin.toLowerCase()}|${destination.toLowerCase()}|$days|$budgetLkr|${style.toLowerCase()}|${interests.join(",").toLowerCase()}|${transport.toLowerCase()}|$startDate';
    // Lightweight deterministic hash using dart:convert only (no external dep)
    final bytes = utf8.encode(raw);
    int hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash + b) & 0xFFFFFFFF;
    }
    return base64Url.encode(utf8.encode(hash.toString())).replaceAll('=', '').substring(0, 12);
  }

  // ─── Last-Plan Cache (auto TTL + schema versioning) ──────────────────────

  static Future<void> cacheLastPlan(TripPlan plan, String cacheKey) async {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final payload = json.encode(plan.toJson());
      await box.put(cacheKey, payload);
    } catch (e) {
      SecureLogger.error('[TripCache] Write error (non-fatal)', e);
    }
  }

  static CachedPlanResult getLastPlan(String cacheKey) {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final raw = box.get(cacheKey);
      if (raw == null) return const CachedPlanResult(state: CacheReadResult.miss);

      final data = json.decode(raw) as Map<String, dynamic>;
      final plan = TripPlan.fromJson(data);

      // Schema version check
      if (plan.schemaVersion < TripPlan.currentSchemaVersion) {
        box.delete(cacheKey); // evict incompatible schema
        return const CachedPlanResult(state: CacheReadResult.stale);
      }

      // TTL check
      if (plan.cachedAt != null &&
          DateTime.now().difference(plan.cachedAt!) > _cacheTtl) {
        // Return stale but DO NOT delete, so offline scenarios still have access to it.
        return CachedPlanResult(state: CacheReadResult.stale, plan: plan);
      }

      return CachedPlanResult(state: CacheReadResult.fresh, plan: plan);
    } catch (e) {
      SecureLogger.error('[TripCache] Read error', e);
      return const CachedPlanResult(state: CacheReadResult.miss);
    }
  }

  // ─── Saved Plans (user-explicit, no TTL) ─────────────────────────────────

  static Future<String> savePlan(TripPlan plan) async {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      final id = '${plan.destination}_${DateTime.now().millisecondsSinceEpoch}';
      final payload = json.encode(plan.toJson());
      await box.put(id, payload);
      return id;
    } catch (e) {
      debugPrint('[TripCache] Save error (non-fatal): $e');
      return '';
    }
  }

  static Future<void> updateSavedPlan(String id, TripPlan plan) async {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      if (box.containsKey(id)) {
        final payload = json.encode(plan.toJson());
        await box.put(id, payload);
      }
    } catch (e) {
      SecureLogger.error('[TripCache] Update error', e);
    }
  }

  static Future<String?> saveOfflineMap(String id, Uint8List imageBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/map_$id.png');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      SecureLogger.error('[TripCache] Save Offline Map error', e);
      return null;
    }
  }

  static List<TripPlan> getAllTrips() {
    try {
      final box = Hive.box<String>(_lastPlanBox);
      final plans = <TripPlan>[];
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            plans.add(TripPlan.fromJson(json.decode(raw)));
          } catch (_) {}
        }
      }
      // Newest first
      plans.sort((a, b) => (b.cachedAt ?? DateTime(0)).compareTo(a.cachedAt ?? DateTime(0)));
      return plans;
    } catch (e) {
      SecureLogger.error('[TripCache] GetAll error', e);
      return [];
    }
  }

  static List<({String id, TripPlan plan})> getSavedPlans() {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      final entries = <({String id, TripPlan plan})>[];
      for (final key in box.keys) {
        final raw = box.get(key as String);
        if (raw == null) continue;
        try {
          entries.add((id: key, plan: TripPlan.fromJson(json.decode(raw))));
        } catch (_) {}
      }
      // Newest first
      entries.sort((a, b) =>
          (b.plan.cachedAt ?? DateTime(0)).compareTo(a.plan.cachedAt ?? DateTime(0)));
      return entries;
    } catch (e) {
      SecureLogger.error('[TripCache] List error', e);
      return [];
    }
  }

  static Future<void> deleteSavedPlan(String id) async {
    try {
      final box = Hive.box<String>(_savedPlansBox);
      final raw = box.get(id);
      if (raw != null) {
        final plan = TripPlan.fromJson(json.decode(raw));
        if (plan.offlineMapPath != null) {
          final file = File(plan.offlineMapPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      await box.delete(id);
    } catch (e) {
      SecureLogger.error('[TripCache] Delete error', e);
    }
  }

  // ─── Interested Events (Offline Support) ──────────────────────────────────
  
  static Future<void> toggleInterestedEvent(String eventId, String eventJson) async {
    try {
      final box = Hive.box<String>(_interestedEventsBox);
      if (box.containsKey(eventId)) {
        await box.delete(eventId);
      } else {
        await box.put(eventId, eventJson);
      }
    } catch (e) {
      SecureLogger.error('[TripCache] Toggle Event error', e);
    }
  }

  static List<String> getInterestedEvents() {
    try {
      final box = Hive.box<String>(_interestedEventsBox);
      return box.values.toList();
    } catch (_) {
      return [];
    }
  }

  static bool isEventPinned(String eventId) {
    try {
      return Hive.box<String>(_interestedEventsBox).containsKey(eventId);
    } catch (_) {
      return false;
    }
  }

  // ─── Stats ───────────────────────────────────────────────────────────────

  static int get savedPlanCount {
    try {
      return Hive.box<String>(_savedPlansBox).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearAll() async {
    try {
      await Hive.box<String>(_lastPlanBox).clear();
      // Keep user-saved plans intact to prevent data loss (Bug C-06 Fix)
    } catch (e) {
      debugPrint('[TripCache] ClearAll error (non-fatal): $e');
    }
  }

  // ─── Global Data Cache (Smart Refresh Support) ──────────────────────────

  static Future<void> cacheGlobalData(String key, String jsonString) async {
    try {
      final box = Hive.box<String>(_globalDataBox);
      await box.put(key, jsonString);
      await box.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch.toString());
    } catch (e) {
      SecureLogger.error('[TripCache] Global data cache error', e);
    }
  }

  static void markLastServerCheck(String key) {
    try {
      final box = Hive.box<String>(_globalDataBox);
      box.put('${key}_last_check', DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  static bool shouldCheckServer(String key, {Duration ttl = const Duration(hours: 12)}) {
    try {
      final box = Hive.box<String>(_globalDataBox);
      final raw = box.get('${key}_last_check');
      if (raw == null) return true;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
      return DateTime.now().difference(lastCheck) > ttl;
    } catch (_) {
      return true;
    }
  }

  static String? getGlobalData(String key) {
    try {
      final box = Hive.box<String>(_globalDataBox);
      return box.get(key);
    } catch (e) {
      SecureLogger.error('[TripCache] Global data read error', e);
      return null;
    }
  }

  static int getGlobalDataTimestamp(String key) {
    try {
      final box = Hive.box<String>(_globalDataBox);
      final raw = box.get('${key}_timestamp');
      return raw != null ? int.parse(raw) : 0;
    } catch (_) {
      return 0;
    }
  }

  static Box<String> get savedFoodsBox => Hive.box<String>(_savedFoodsBox);
}
