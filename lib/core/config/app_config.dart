import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

class AppConfig {
  // Audit #15: Replaced pseudo-encryption Base64 with direct strings.
  // In CI/CD production builds, these default placeholders
  // are overridden via `--dart-define=KEY=VALUE` environment parameters.

  static const String laravelUrl = String.fromEnvironment(
    'LARAVEL_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://api.hidengem.xyz/api/v1" : "http://192.168.8.168:8888/api/v1",
  );

  static const String pythonUrl = String.fromEnvironment(
    'PYTHON_BACKEND_URL',
    defaultValue: kReleaseMode ? "https://ai.hiddengemssl.com/api" : "http://192.168.8.168:8000/api",
  );

  // Alias for backward compatibility (defaults to Laravel backend)
  static const String baseUrl = laravelUrl;

  /// Web root of the Laravel backend (laravelUrl minus the `/api/v1` API
  /// prefix) — used for links meant to be opened in a browser by someone
  /// without the app, e.g. family-sharing "join" links.
  static String get webBaseUrl {
    const suffix = '/api/v1';
    return laravelUrl.endsWith(suffix)
        ? laravelUrl.substring(0, laravelUrl.length - suffix.length)
        : laravelUrl;
  }

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
          ? 'wss://api.hidengem.xyz:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false'
          : 'ws://192.168.8.102:8080/app/hiddengems_reverb_key?protocol=7&client=js&version=8.0.0&flash=false';
    }
  }

  // Android has no native "Sign in with Apple" UI — the sign_in_with_apple
  // package instead opens a web-based OAuth redirect (Custom Tab) through
  // these two values, both created in Apple Developer Console:
  //  1. appleServiceId — a "Services ID" (distinct from the app's Bundle ID),
  //     registered with this app's associated domain.
  //  2. appleRedirectUri — an endpoint on YOUR OWN backend/web domain that
  //     Apple redirects back to after sign-in; it must be registered as a
  //     "Return URL" for the Services ID above, and must relay the auth
  //     result back to the app (deep link / postMessage) for
  //     SignInWithApple.getAppleIDCredential to pick up.
  // REPLACE_WITH_REAL_VALUE placeholders — Apple Sign-In on Android will not
  // work until both are set via --dart-define, e.g.:
  //   --dart-define=APPLE_SERVICE_ID=com.hidden.gems.web
  //   --dart-define=APPLE_REDIRECT_URI=https://hiddengems.lk/callback/apple
  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'REPLACE_WITH_REAL_VALUE.apple.service.id',
  );

  static const String appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: 'REPLACE_WITH_REAL_VALUE/callback/apple',
  );

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
    if (lower.contains('replace_with')) return true;
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
          : 'ws://192.168.8.168:8000/ws/scan';
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
    defaultValue: kReleaseMode ? "https://api.hidengem.xyz/api/v1" : "http://192.168.8.102:8888/api/v1",
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

  // Commercial Gemini integration has been removed — AI is served by the
  // self-hosted model (Oracle chat / Trip Planner via pythonUrl, food scan
  // via the BYOM /food/scan endpoint). llmModelName is kept only as a
  // metadata label sent to the backend (dynamic_content_service,
  // remote_config_service); it no longer selects a Google model.
  static const String llmModelName = String.fromEnvironment(
    'LLM_MODEL_NAME',
    defaultValue: "self-hosted",
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

    // Each secret below is already read once via its static field (e.g.
    // hiddenGemsApiKey = String.fromEnvironment('HIDDEN_GEMS_API_KEY',
    // defaultValue: ...)) — that single read is what's checked. An earlier
    // version of this method re-read the same --dart-define a second time
    // inline (isPlaceholder(const String.fromEnvironment('HIDDEN_GEMS_API_KEY')))
    // with no defaultValue, which resolves to "" and is always a placeholder
    // regardless of what's actually passed at build time, permanently
    // failing validation no matter how the real secret was supplied. Removed.
    if (isPlaceholder(hiddenGemsApiKey)) {
      throw AssertionError("CRITICAL: Must configure a valid HIDDEN_GEMS_API_KEY environment variable.");
    }
    if (isPlaceholder(revenueCatApiKeyAndroid) || isPlaceholder(revenueCatApiKeyIos)) {
      throw AssertionError("CRITICAL: Must configure valid RevenueCat API Keys via secure environment variables (BUG-Q001).");
    }
    if (isPlaceholder(sharedSecret)) {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_SECRET environment variable.");
    }
    if (isPlaceholder(vaultSignKey)) {
      throw AssertionError("CRITICAL: Must configure a valid VAULT_SIGN_KEY environment variable.");
    }
    if (isPlaceholder(sharedAesKey)) {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_AES_KEY environment variable.");
    }
    if (isPlaceholder(sharedHmacKey)) {
      throw AssertionError("CRITICAL: Must configure a valid SHARED_HMAC_KEY environment variable.");
    }
    if (isPlaceholder(hmacExpirySecret)) {
      throw AssertionError("CRITICAL: Must configure a valid HMAC_EXPIRY_SECRET.");
    }
    // App Store ID only exists for the iOS listing (used to build the App
    // Store review-request/update-check link) — Android has no equivalent,
    // so this check would otherwise force every Android release build to
    // fake a value just to pass validation.
    if (Platform.isIOS && isPlaceholder(appStoreId)) {
      throw AssertionError("CRITICAL: Must configure a valid APP_STORE_ID.");
    }
    // Apple Sign-In on Android goes through a web-based OAuth flow (Apple has
    // no native Android SDK) via appleServiceId/appleRedirectUri — see
    // signInWithApple() in auth_service.dart. Warn rather than throw: unlike
    // the secrets above, this is one of several sign-in options (Google,
    // email, Apple), not something the whole app depends on to function —
    // hard-failing every release build over one unconfigured secondary
    // button would be disproportionate. Leaving it unset just means that
    // button fails cleanly at tap time instead of at launch.
    if (Platform.isAndroid && (isPlaceholder(appleServiceId) || isPlaceholder(appleRedirectUri))) {
      SecureLogger.warning(
        "Apple Sign-In is not configured (APPLE_SERVICE_ID/APPLE_REDIRECT_URI still placeholder) — "
        "the Apple Sign-In button will fail for any user who taps it on Android.",
        tag: "AppConfig",
      );
    }
    if (isPlaceholder(weatherApiKey)) {
      throw AssertionError("CRITICAL: Must configure a valid WEATHER_API_KEY environment variable.");
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



