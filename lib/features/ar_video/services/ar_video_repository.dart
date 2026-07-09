import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/ar_video_content.dart';
import '../../../core/utils/secure_logger.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/secure_http_client.dart';
import '../../../core/services/reverb_channel_service.dart';

/// Repository for fetching AR Cinematic content from Firestore.
/// Collection: 'locations'
class ARVideoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for the AR library list (TTL: 10 minutes, mirrors the
  // Laravel-side cache window). Avoids a network round-trip on every
  // AR Video Library screen open within the window. A Reverb push (see
  // `_reverb`) refreshes this ahead of the TTL when the backend's
  // marketplace:broadcast-updates command detects a real change — the HTTP
  // path remains the initial-load + offline/socket-down fallback.
  List<ARVideoContent>? _enabledCache;
  DateTime? _enabledCacheExpiry;

  ReverbChannelService? _reverb;
  StreamSubscription<ReverbEvent>? _reverbSub;

  /// Fetches a single AR video content by location ID.
  /// Falls back to Sigiriya demo if the document doesn't exist or is offline.
  Future<ARVideoContent> fetchContent(String locationId) async {
    try {
      final doc = await _firestore.collection('locations').doc(locationId).get();

      if (!doc.exists) {
        SecureLogger.info('AR Content for $locationId not found, falling back to demo.');
        return ARVideoContent.sigiriyaDemo();
      }

      return ARVideoContent.fromMap(doc.id, doc.data()!);
    } catch (e) {
      SecureLogger.error('Error fetching AR content for $locationId: $e');
      return ARVideoContent.sigiriyaDemo();
    }
  }

  /// Fetches all AR-enabled locations via the Laravel backend's shared
  /// 10-min cache — previously this ran a full `locations` collection scan
  /// directly against Firestore on every screen open, with no shared cache.
  Future<List<ARVideoContent>> getAllEnabled() async {
    _ensureLiveUpdatesConnected();

    if (_enabledCache != null &&
        _enabledCacheExpiry != null &&
        DateTime.now().isBefore(_enabledCacheExpiry!)) {
      return _enabledCache!;
    }

    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/ar/enabled-locations');
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['locations'] as List<dynamic>? ?? [])
            .map((l) => ARVideoContent.fromMap(
                  (l as Map<String, dynamic>)['id'] as String? ?? '',
                  l,
                ))
            .toList();

        _enabledCache = list.isEmpty ? [ARVideoContent.sigiriyaDemo()] : list;
        _enabledCacheExpiry = DateTime.now().add(const Duration(minutes: 10));
        return _enabledCache!;
      }
      SecureLogger.warning("AR enabled-locations fetch returned ${response.statusCode}", tag: "ARVideo");
    } catch (e) {
      SecureLogger.error('Error getting AR library from backend: $e');
    }
    return _enabledCache ?? [ARVideoContent.sigiriyaDemo()];
  }

  /// Connects (once) to the `ar-enabled-locations` Reverb channel so a push
  /// from the backend can refresh `_enabledCache` ahead of its 10-min TTL.
  void _ensureLiveUpdatesConnected() {
    if (_reverb != null) return;

    _reverb = ReverbChannelService(channelName: 'ar-enabled-locations');
    _reverbSub = _reverb!.events.listen((event) {
      if (event.name != 'ArEnabledLocationsUpdated') return;
      try {
        final payload = event.data as Map<String, dynamic>;
        final list = (payload['locations'] as List<dynamic>? ?? [])
            .map((l) => ARVideoContent.fromMap(
                  (l as Map<String, dynamic>)['id'] as String? ?? '',
                  l,
                ))
            .toList();
        _enabledCache = list.isEmpty ? [ARVideoContent.sigiriyaDemo()] : list;
        _enabledCacheExpiry = DateTime.now().add(const Duration(minutes: 10));
        SecureLogger.info("AR enabled locations updated via Reverb push.", tag: "ARVideo");
      } catch (e) {
        SecureLogger.warning("Failed to apply Reverb ar-enabled-locations push: $e", tag: "ARVideo");
      }
    });
    _reverb!.connect();
  }

  void disposeLiveUpdates() {
    _reverbSub?.cancel();
    _reverb?.dispose();
    _reverb = null;
    _reverbSub = null;
  }
}
