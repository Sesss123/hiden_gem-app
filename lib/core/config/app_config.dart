import 'package:flutter/foundation.dart';

class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: kReleaseMode ? "https://api.hiddengemssl.com/api" : "http://10.0.2.2:8000/api",
  );

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
    defaultValue: "TRIPME_V1_STAGING_KEY_SHHH",
  );

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: kReleaseMode ? "https://proxy.hiddengemssl.com" : "http://10.0.2.2:3000",
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

  static void validate() {
    // In production, missing keys will fail hard.
    // In debug mode, if developers explicitly pass `--dart-define=BYPASS_KEY_CHECKS=true`, we allow it,
    // otherwise we also fail hard to prevent silent failures.
    const bypassChecks = bool.fromEnvironment('BYPASS_KEY_CHECKS', defaultValue: false);

    if (!bypassChecks || kReleaseMode) {
      if (hiddenGemsApiKey == "" || hiddenGemsApiKey == "dev-key-local") {
        throw AssertionError("CRITICAL: Must configure a valid HIDDEN_GEMS_API_KEY.");
      }
      if (geminiApiKey == "") {
        throw AssertionError("CRITICAL: Must configure a valid GEMINI_API_KEY.");
      }
      if (revenueCatApiKeyAndroid == "goog_example_key" || revenueCatApiKeyIos == "appl_example_key") {
        throw AssertionError("CRITICAL: Must configure valid RevenueCat API Keys.");
      }
      if (sharedSecret == "DEFAULT_NON_PROD_SECRET") {
        throw AssertionError("CRITICAL: Must configure a valid HMAC_SECRET.");
      }
      if (vaultSignKey == "TRIPME_V1_STAGING_KEY_SHHH") {
        throw AssertionError("CRITICAL: Must configure a valid VAULT_SIGN_KEY.");
      }
    }
  }
}

