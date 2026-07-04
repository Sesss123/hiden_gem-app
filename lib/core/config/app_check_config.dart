import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

/// [AppCheckConfig] — Centralized Firebase App Check configuration.
///
/// ROLLOUT STRATEGY (as per plan):
///   Step 1: Integrate ✅ (this file)
///   Step 2: Debug Provider for testing ✅ (enabled below in debug mode)
///   Step 3: Monitor in Firebase Console → then enable enforcement
///
/// PROVIDERS BY PLATFORM:
///   Android → Play Integrity (production) / Debug Provider (debug)
///   iOS     → DeviceCheck (production) / Debug Provider (debug)
///   Web     → reCAPTCHA v3 (requires site key from Firebase Console)
///
/// TO ENABLE ENFORCEMENT:
///   Firebase Console → App Check → Apps → [Your App] → Enforce
///   Only do this AFTER monitoring for a few days with no false positives.
class AppCheckConfig {
  /// Initialize App Check. Call this during Firebase initialization.
  ///
  /// In debug mode: uses the debug token provider (no real device attestation).
  /// In release mode: uses Play Integrity / DeviceCheck for genuine device verification.
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        // BUG-A03 Fix: Enable AndroidDebugProvider / AppleDebugProvider in debug sessions
        // when explicitly configured via --dart-define=ENABLE_DEBUG_APP_CHECK=true
        const useDebugProvider = bool.fromEnvironment('ENABLE_DEBUG_APP_CHECK', defaultValue: false);
        if (!useDebugProvider) {
          SecureLogger.warning('[AppCheck] ⚠️ DEBUG: Skipping App Check in debug mode (pass --dart-define=ENABLE_DEBUG_APP_CHECK=true to enable AndroidDebugProvider/AppleDebugProvider).');
          return;
        }
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        );
        SecureLogger.info('[AppCheck] ✅ Debug mode: AndroidDebugProvider + AppleDebugProvider activated.');
      } else if (kIsWeb) {
        // Web: reCAPTCHA v3
        // Note: Site key matched with web/index.html. Fetched from env variables.
        const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY', defaultValue: '6Lfm-GsqAAAAAHA_-Wj_P_X_X_X_X_X_X_X_X');
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(siteKey),
        );
        SecureLogger.info('[AppCheck] ✅ Web: reCAPTCHA v3 activated.');
      } else {
        // Release Mode: Real attestation
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleDeviceCheckProvider(),
        );
        SecureLogger.info('[AppCheck] ✅ Release: Play Integrity + DeviceCheck activated.');
      }

      // Set up a token refresh listener for logging/monitoring
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        if (token != null) {
          SecureLogger.info('[AppCheck] Token refreshed (length: ${token.length}).');
        } else {
          SecureLogger.warning('[AppCheck] ⚠️ Token became null — possible enforcement block.');
        }
      });
    } catch (e) {
      // CRITICAL: Never crash the app if App Check fails.
      // In non-enforcement mode, the app continues normally.
      // In enforcement mode, Firestore/Auth calls will fail for unverified clients.
      SecureLogger.error('[AppCheck] ❌ Initialization error. Proceeding without App Check.', e);
    }
  }

  /// Manually fetch a fresh App Check token.
  /// 
  /// Use this to pre-warm the token before a sensitive operation,
  /// or to verify App Check is working in debug sessions.
  static Future<String?> getToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken(true);
    } catch (e) {
      SecureLogger.warning('[AppCheck] Token fetch failed: $e');
      return null;
    }
  }
}
