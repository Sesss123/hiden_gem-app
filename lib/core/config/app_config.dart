import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

class AppConfig {
  // Audit #15: Replaced pseudo-encryption Base64 with direct strings.
  // In CI/CD production builds, these default placeholders
  // are overridden via `--dart-define=KEY=VALUE` environment parameters.

  static const String laravelUrl = String.fromEnvironment(
    'LARAVEL_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api/v1" : "http://192.168.8.102:8888/api/v1",
  );

  static const String pythonUrl = String.fromEnvironment(
    'PYTHON_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://ai.hiddengemssl.com/api" : "http://192.168.8.102:8000/api",
  );

  // Alias for backward compatibility (defaults to Laravel backend)
  static const String baseUrl = laravelUrl;

  static String get reverbWsUrl {
    final customWs = const String.fromEnvironment('REVERB_WS_URL');
    if (customWs.isNotEmpty) return customWs;
    try {
      final uri = Uri.parse(laravelUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final explicitPort = const String.fromEnvironment('REVERB_PORT');
      final port = explicitPort.isNotEmpty 
          ? int.parse(explicitPort) 
          : ((uri.port == 8888 || uri.port == 80) ? 8080 : uri.port);
      return '$scheme://${uri.host}:$port/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false';
    } catch (_) {
      return kReleaseMode
          ? 'wss://api.hiddengemssl.com:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false'
          : 'ws://192.168.8.102:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false';
    }
  }

  static bool isPlaceholder(String value) {
    if (value.isEmpty) return true;
    final lower = value.toLowerCase();
    if (lower.contains('placeholder')) return true;
    if (lower.contains('default_non_prod')) return true;
    if (lower.contains('example_key')) return true;
    if (lower == 'dev-key-local') return true;
    if (lower == 'hidden_gems_v1_staging_key_shhh') return true;
    if (lower == '6400000000') return true;
    if (lower.contains('your_real_')) return true;
    return false;
  }

  static String get foodScannerWsUrl {
    final customWs = const String.fromEnvironment('FOOD_SCANNER_WS_URL');
    if (customWs.isNotEmpty) return customWs;
    try {
      final uri = Uri.parse(pythonUrl);
      final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
      return '$scheme://${uri.host}:${uri.port}/ws/scan';
    } catch (_) {
      return kReleaseMode
          ? 'wss://ai.hiddengemssl.com/ws/scan'
          : 'ws://192.168.8.102:8000/ws/scan';
    }
  }

  // BUG-113 / Audit #15: Obfuscate raw API keys using base64 wrapper string constants.
  // The default values below are non-production development placeholders overridden by CI/CD.
  static final String hiddenGemsApiKey = const String.fromEnvironment(
    'HIDDEN_GEMS_API_KEY',
    defaultValue: "dev-key-local", // Non-prod placeholder
  );

  static String get tripMeApiKey => hiddenGemsApiKey;

  static final String sharedSecret = const String.fromEnvironment(
    'HMAC_SECRET',
    defaultValue: "DEFAULT_NON_PROD_SECRET", // Non-prod placeholder
  );

  static final String vaultSignKey = const String.fromEnvironment(
    'VAULT_SIGN_KEY',
    defaultValue: "HIDDEN_GEMS_V1_STAGING_KEY_SHHH", // Non-prod placeholder
  );

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api/v1" : "http://192.168.8.102:8888/api/v1",
  );

  static const String cdnBaseUrl = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: "https://cdn.hiddengemssl.com",
  );

  static final String revenueCatApiKeyAndroid = const String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: "goog_example_key", // Non-prod placeholder
  );

  static final String revenueCatApiKeyIos = const String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: "appl_example_key", // Non-prod placeholder
  );

  static final String geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: "",
  );

  static const String llmModelName = String.fromEnvironment(
    'LLM_MODEL_NAME',
    defaultValue: "gemini-2.0-flash",
  );

  static const String llmApiBaseUrl = String.fromEnvironment(
    'LLM_API_BASE_URL',
    defaultValue: "https://generativelanguage.googleapis.com/v1beta",
  );

  static final String weatherApiKey = const String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: "",
  );

  static const bool ragEnabled = true;

  static final String sharedAesKey = const String.fromEnvironment(
    'SHARED_AES_KEY',
    defaultValue: "DEFAULT_NON_PROD_AES_KEY", // Non-prod placeholder
  );

  static final String sharedHmacKey = const String.fromEnvironment(
    'SHARED_HMAC_KEY',
    defaultValue: "DEFAULT_NON_PROD_HMAC_KEY", // Non-prod placeholder
  );

  static final String hmacExpirySecret = const String.fromEnvironment(
    'HMAC_EXPIRY_SECRET',
    defaultValue: "DEFAULT_NON_PROD_EXPIRY_SECRET", // Non-prod placeholder
  );

  static const String appStoreId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: "",
  );

  static void validate() {
    // In production and profile modes, missing or placeholder keys will fail hard.
    // In debug mode, allow default placeholder keys without crashing so developers/users can test locally.
    if (kDebugMode) {
      SecureLogger.info('[AppConfig] Running in debug mode. Default/placeholder environment keys allowed.');
      return;
    }

    if (isPlaceholder(hiddenGemsApiKey) || isPlaceholder(const String.fromEnvironment('HIDDEN_GEMS_API_KEY'))) {
      throw AssertionError("CRITICAL: Must configure a valid HIDDEN_GEMS_API_KEY environment variable.");
    }
    if (isPlaceholder(revenueCatApiKeyAndroid) || isPlaceholder(revenueCatApiKeyIos)) {
      throw AssertionError("CRITICAL: Must configure valid RevenueCat API Keys via secure environment variables (BUG-Q001).");
    }
    if (isPlaceholder(sharedSecret) || isPlaceholder(const String.fromEnvironment('HMAC_SECRET'))) {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_SECRET environment variable.");
    }
    if (isPlaceholder(vaultSignKey) || isPlaceholder(const String.fromEnvironment('VAULT_SIGN_KEY'))) {
      throw AssertionError("CRITICAL: Must configure a valid VAULT_SIGN_KEY environment variable.");
    }
    if (isPlaceholder(sharedAesKey) || isPlaceholder(const String.fromEnvironment('SHARED_AES_KEY'))) {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_AES_KEY environment variable.");
    }
    if (isPlaceholder(sharedHmacKey) || isPlaceholder(const String.fromEnvironment('SHARED_HMAC_KEY'))) {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_HMAC_KEY environment variable.");
    }
    if (isPlaceholder(hmacExpirySecret) || isPlaceholder(const String.fromEnvironment('HMAC_EXPIRY_SECRET'))) {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_EXPIRY_SECRET.");
    }
    if (isPlaceholder(appStoreId)) {
      throw AssertionError("CRITICAL: Must configure a valid APP_STORE_ID.");
    }
    if (isPlaceholder(const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'YOUR_REAL_BANNER_ID'))) {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_BANNER_ID.");
    }
    if (isPlaceholder(const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'YOUR_REAL_INTERSTITIAL_ID'))) {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_INTERSTITIAL_ID.");
    }
    if (isPlaceholder(const String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: 'YOUR_REAL_REWARDED_ID'))) {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_REWARDED_ID.");
    }
    if (isPlaceholder(const String.fromEnvironment('ADMOB_NATIVE_ID', defaultValue: 'YOUR_REAL_NATIVE_ID'))) {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_NATIVE_ID.");
    }
  }
}



