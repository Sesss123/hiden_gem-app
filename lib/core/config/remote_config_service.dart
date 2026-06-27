import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  static RemoteConfigService? _instance;

  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      _instance = RemoteConfigService(remoteConfig);
    }
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig.setDefaults({
        // Existing
        'api_version': '1.0.0',
        'min_app_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'model_name': AppConfig.llmModelName,
        'is_rag_enabled': true,
        'theme_config': 'default',
        'data_refresh_timestamp': 0,

        // 🛡️ ZENITH STRESS DEFENSE: Emergency Kill Switches
        // These can be toggled in the Firebase Console without a release.

        /// Kills marketplace search instantly (e.g., under abuse/DDoS)
        'kill_marketplace_search': false,

        /// Kills AI trip generation (cost protection during viral spike)
        'kill_ai_generation': false,

        /// Kills new user registration temporarily
        'kill_new_registrations': false,

        /// Put app in slow mode — forces user to wait between actions
        'slow_mode_enabled': false,

        /// Max searches per user per minute. 0 = unlimited
        'search_rate_limit_per_minute': 10,

        /// Minimum search query length (client-side enforcement)
        'search_min_chars': 2,

        /// Per-user AI trip quota per month (overrides local defaults)
        'ai_trips_monthly_limit': 5,

        /// Force all users to re-login (security incident response)
        'force_relogin': false,

        /// Blocked app build versions (comma-separated, e.g., "1.0.0+1,1.0.1+2")
        'blocked_build_versions': '',
      });

      await fetchAndActivate();
    } catch (e) {
      SecureLogger.error('RemoteConfig initialization failed', e);
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      SecureLogger.error('RemoteConfig fetch failed', e);
    }
  }

  String getString(String key) => _remoteConfig.getString(key);
  bool getBool(String key) => _remoteConfig.getBool(key);
  int getInt(String key) => _remoteConfig.getInt(key);
  double getDouble(String key) => _remoteConfig.getDouble(key);

  // ── Existing Helpers ──────────────────────────────────────────────────────
  String get apiVersion => getString('api_version');
  String get minAppVersion => getString('min_app_version');
  String get latestAppVersion => getString('latest_app_version');
  String get modelName => getString('model_name');
  bool get isRagEnabled => getBool('is_rag_enabled');
  String get themeConfig => getString('theme_config');
  int get dataRefreshTimestamp => getInt('data_refresh_timestamp');

  // ── 🛡️ Emergency Kill Switches ────────────────────────────────────────────
  bool get isMarketplaceSearchKilled => getBool('kill_marketplace_search');
  bool get isAiGenerationKilled => getBool('kill_ai_generation');
  bool get isNewRegistrationsKilled => getBool('kill_new_registrations');
  bool get isSlowModeEnabled => getBool('slow_mode_enabled');
  bool get forceRelogin => getBool('force_relogin');

  // ── Rate Limiting ────────────────────────────────────────────────────────
  int get searchRateLimitPerMinute => getInt('search_rate_limit_per_minute');
  int get searchMinChars => getInt('search_min_chars');
  int get aiTripsMonthlyLimit => getInt('ai_trips_monthly_limit');

  // ── Blocked Build Versions ────────────────────────────────────────────────
  List<String> get blockedBuildVersions {
    final raw = getString('blocked_build_versions');
    if (raw.isEmpty) return [];
    return raw.split(',').map((v) => v.trim()).toList();
  }
}

