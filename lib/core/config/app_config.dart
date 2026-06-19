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

  static void validate() {
    if (kReleaseMode && (hiddenGemsApiKey == "" || hiddenGemsApiKey == "dev-key-local")) {
      throw AssertionError("CRITICAL: Production builds must configure a valid HIDDEN_GEMS_API_KEY.");
    }
  }

  static const String nodeProxyUrl = String.fromEnvironment(
    'NODE_PROXY_URL',
    defaultValue: "http://localhost:8000/api",
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

  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: "",
  );

  static const bool ragEnabled = true;
}

