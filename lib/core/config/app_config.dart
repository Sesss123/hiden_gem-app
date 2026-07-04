import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

class AppConfig {
  // Audit #15: Helper to decode obfuscated credentials in memory.
  // NOTE: Base64 encoding is used here ONLY as a layer of basic obfuscation against
  // automated binary string scanners (e.g., strings/grep tools on compiled APK/IPA binaries),
  // NOT as cryptographic encryption. In CI/CD production builds, these default placeholders
  // are overridden via `--dart-define=KEY=VALUE` environment parameters.
  static String _decryptString(String base64Str) {
    try {
      return utf8.decode(base64.decode(base64Str));
    } catch (_) {
      return base64Str;
    }
  }

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
      final port = (uri.port == 8888 || uri.port == 80) ? 8080 : uri.port;
      return '$scheme://${uri.host}:$port/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false';
    } catch (_) {
      return kReleaseMode
          ? 'wss://api.hiddengemssl.com:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false'
          : 'ws://192.168.8.102:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false';
    }
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
  static final String hiddenGemsApiKey = _decryptString(const String.fromEnvironment(
    'HIDDEN_GEMS_API_KEY',
    defaultValue: "ZGV2LWtleS1sb2NhbA==", // Non-prod placeholder: "dev-key-local"
  ));

  static String get tripMeApiKey => hiddenGemsApiKey;

  static final String sharedSecret = _decryptString(const String.fromEnvironment(
    'HMAC_SECRET',
    defaultValue: "REVGQVVMVF9OT05fUFJPRF9TRUNSRVQ=", // Non-prod placeholder: "DEFAULT_NON_PROD_SECRET"
  ));

  static final String vaultSignKey = _decryptString(const String.fromEnvironment(
    'VAULT_SIGN_KEY',
    defaultValue: "SElEREVOX0dFTVNfVjFfU1RBR0lOR19LRVlfU0hISA==", // Non-prod placeholder: "HIDDEN_GEMS_V1_STAGING_KEY_SHHH"
  ));

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api/v1" : "http://192.168.8.102:8888/api/v1",
  );

  static const String cdnBaseUrl = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: "https://cdn.hiddengemssl.com",
  );

  static final String revenueCatApiKeyAndroid = _decryptString(const String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: "Z29vZ19leGFtcGxlX2tleQ==", // Non-prod placeholder: "goog_example_key"
  ));

  static final String revenueCatApiKeyIos = _decryptString(const String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: "YXBwbF9leGFtcGxlX2tleQ==", // Non-prod placeholder: "appl_example_key"
  ));

  static final String geminiApiKey = _decryptString(const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: "",
  ));

  static const String llmModelName = String.fromEnvironment(
    'LLM_MODEL_NAME',
    defaultValue: "gemini-2.0-flash",
  );

  static const String llmApiBaseUrl = String.fromEnvironment(
    'LLM_API_BASE_URL',
    defaultValue: "https://generativelanguage.googleapis.com/v1beta",
  );

  static final String weatherApiKey = _decryptString(const String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: "",
  ));

  static const bool ragEnabled = true;

  static final String sharedAesKey = _decryptString(const String.fromEnvironment(
    'SHARED_AES_KEY',
    defaultValue: "REVGQVVMVF9OT05fUFJPRF9BRVNfS0VZ", // Non-prod placeholder: "DEFAULT_NON_PROD_AES_KEY"
  ));

  static final String sharedHmacKey = _decryptString(const String.fromEnvironment(
    'SHARED_HMAC_KEY',
    defaultValue: "REVGQVVMVF9OT05fUFJPRF9ITUFDX0tFWQ==", // Non-prod placeholder: "DEFAULT_NON_PROD_HMAC_KEY"
  ));

  static final String hmacExpirySecret = _decryptString(const String.fromEnvironment(
    'HMAC_EXPIRY_SECRET',
    defaultValue: "REVGQVVMVF9OT05fUFJPRF9FWFBJUllfU0VDUkVU", // Non-prod placeholder: "DEFAULT_NON_PROD_EXPIRY_SECRET"
  ));

  static const String appStoreId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: "",
  );

  static void validate() {
    // In production (release mode), missing or placeholder keys will fail hard.
    // In debug/dev mode, allow default placeholder keys without crashing so developers/users can test locally.
    if (!kReleaseMode) {
      SecureLogger.info('[AppConfig] Running in debug/dev mode. Default/placeholder environment keys allowed.');
      return;
    }

    if (hiddenGemsApiKey == "" || hiddenGemsApiKey == "dev-key-local" || const String.fromEnvironment('HIDDEN_GEMS_API_KEY') == "") {
      throw AssertionError("CRITICAL: Must configure a valid HIDDEN_GEMS_API_KEY environment variable.");
    }
    if (revenueCatApiKeyAndroid == "goog_example_key" || revenueCatApiKeyIos == "appl_example_key") {
      throw AssertionError("CRITICAL: Must configure valid RevenueCat API Keys via secure environment variables (BUG-Q001).");
    }
    if (sharedSecret == "DEFAULT_NON_PROD_SECRET" || const String.fromEnvironment('HMAC_SECRET') == "") {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_SECRET environment variable.");
    }
    if (vaultSignKey == "HIDDEN_GEMS_V1_STAGING_KEY_SHHH" || const String.fromEnvironment('VAULT_SIGN_KEY') == "") {
      throw AssertionError("CRITICAL: Must configure a valid VAULT_SIGN_KEY environment variable.");
    }
    if (sharedAesKey == "DEFAULT_NON_PROD_AES_KEY" || const String.fromEnvironment('SHARED_AES_KEY') == "") {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_AES_KEY environment variable.");
    }
    if (sharedHmacKey == "DEFAULT_NON_PROD_HMAC_KEY" || const String.fromEnvironment('SHARED_HMAC_KEY') == "") {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_HMAC_KEY environment variable.");
    }
    if (hmacExpirySecret == "DEFAULT_NON_PROD_EXPIRY_SECRET" || const String.fromEnvironment('HMAC_EXPIRY_SECRET') == "") {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_EXPIRY_SECRET.");
    }
    if (appStoreId == "" || appStoreId == "6400000000") {
      throw AssertionError("CRITICAL: Must configure a valid APP_STORE_ID.");
    }
    if (const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'YOUR_REAL_BANNER_ID') == 'YOUR_REAL_BANNER_ID') {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_BANNER_ID.");
    }
    if (const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'YOUR_REAL_INTERSTITIAL_ID') == 'YOUR_REAL_INTERSTITIAL_ID') {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_INTERSTITIAL_ID.");
    }
    if (const String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: 'YOUR_REAL_REWARDED_ID') == 'YOUR_REAL_REWARDED_ID') {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_REWARDED_ID.");
    }
    if (const String.fromEnvironment('ADMOB_NATIVE_ID', defaultValue: 'YOUR_REAL_NATIVE_ID') == 'YOUR_REAL_NATIVE_ID') {
      throw AssertionError("CRITICAL: Must configure a valid ADMOB_NATIVE_ID.");
    }
  }
}



