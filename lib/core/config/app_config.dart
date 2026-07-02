import 'package:flutter/foundation.dart';

class AppConfig {
  static const String laravelUrl = String.fromEnvironment(
    'LARAVEL_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api/v1" : "http://10.0.2.2:8888/api/v1",
  );

  static const String pythonUrl = String.fromEnvironment(
    'PYTHON_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://ai.hiddengemssl.com/api" : "http://10.0.2.2:8000/api",
  );

  // Alias for backward compatibility (defaults to Laravel backend)
  static const String baseUrl = laravelUrl;

  static const String hiddenGemsApiKey = String.fromEnvironment(
    'HIDDEN_GEMS_API_KEY',
    defaultValue: "dev-key-local",
  );

  static String get tripMeApiKey => hiddenGemsApiKey;

  static const String sharedSecret = String.fromEnvironment(
    'HMAC_SECRET',
    defaultValue: "DEFAULT_NON_PROD_SECRET",
  );

  static const String vaultSignKey = String.fromEnvironment(
    'VAULT_SIGN_KEY',
    defaultValue: "HIDDEN_GEMS_V1_STAGING_KEY_SHHH",
  );

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api/v1" : "http://10.0.2.2:8888/api/v1",
  );

  static const String cdnBaseUrl = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: "https://cdn.hiddengemssl.com",
  );

  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'REVENUECAT_API_KEY_ANDROID',
    defaultValue: "goog_example_key",
  );

  static const String revenueCatApiKeyIos = String.fromEnvironment(
    'REVENUECAT_API_KEY_IOS',
    defaultValue: "appl_example_key",
  );

  static const String geminiApiKey = String.fromEnvironment(
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

  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: "",
  );

  static const bool ragEnabled = true;

  static const String sharedAesKey = String.fromEnvironment(
    'SHARED_AES_KEY',
    defaultValue: "DEFAULT_NON_PROD_AES_KEY",
  );

  static const String sharedHmacKey = String.fromEnvironment(
    'SHARED_HMAC_KEY',
    defaultValue: "DEFAULT_NON_PROD_HMAC_KEY",
  );

  static const String hmacExpirySecret = String.fromEnvironment(
    'HMAC_EXPIRY_SECRET',
    defaultValue: "DEFAULT_NON_PROD_EXPIRY_SECRET",
  );

  static const String appStoreId = String.fromEnvironment(
    'APP_STORE_ID',
    defaultValue: "6400000000",
  );

  static void validate() {
    // In production, missing keys will fail hard.
    // In debug mode, if developers explicitly pass `--dart-define=BYPASS_KEY_CHECKS=true`, we allow it,
    // otherwise we also fail hard to prevent silent failures.
    const bypassChecks = bool.fromEnvironment('BYPASS_KEY_CHECKS', defaultValue: false);

    if (!bypassChecks || kReleaseMode) {
      if (hiddenGemsApiKey == "" || hiddenGemsApiKey == "dev-key-local") {
        throw AssertionError("CRITICAL: Must configure a valid HIDDEN_GEMS_API_KEY.");
      }
      if (revenueCatApiKeyAndroid == "goog_example_key" || revenueCatApiKeyIos == "appl_example_key") {
        throw AssertionError("CRITICAL: Must configure valid RevenueCat API Keys.");
      }
      if (sharedSecret == "DEFAULT_NON_PROD_SECRET") {
        throw AssertionError("CRITICAL: Must configure a valid HMAC_SECRET.");
      }
      if (vaultSignKey == "HIDDEN_GEMS_V1_STAGING_KEY_SHHH" || vaultSignKey == "TRIPME_V1_STAGING_KEY_SHHH") {
        throw AssertionError("CRITICAL: Must configure a valid VAULT_SIGN_KEY.");
      }
      if (sharedAesKey == "DEFAULT_NON_PROD_AES_KEY" || sharedAesKey == "uN7U8L4f3k8P8m9Qz2Wp5X7r9tBy1C3v5X7r9tBy1C3=") {
        throw AssertionError("CRITICAL: Must configure a valid SHARED_AES_KEY.");
      }
      if (sharedHmacKey == "DEFAULT_NON_PROD_HMAC_KEY" || sharedHmacKey == "kP5v8N2m4Q9z1X3r7tBy9C1v3X5r7tBy9C1v3X5r7tB=") {
        throw AssertionError("CRITICAL: Must configure a valid SHARED_HMAC_KEY.");
      }
      if (hmacExpirySecret == "DEFAULT_NON_PROD_EXPIRY_SECRET" || hmacExpirySecret == "ZENITH_EXPIRY_SIGN_KEY_2026") {
        throw AssertionError("CRITICAL: Must configure a valid HMAC_EXPIRY_SECRET.");
      }
      if (appStoreId == "6400000000") {
        throw AssertionError("CRITICAL: Must configure a valid APP_STORE_ID.");
      }
    }
  }
}

