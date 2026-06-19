import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

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
      if (kIsWeb) {
        // Web: reCAPTCHA v3
        // Note: Site key matched with web/index.html
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider('6Lfm-GsqAAAAAHA_-Wj_P_X_X_X_X_X_X_X_X'),
        );
        debugPrint('[AppCheck] ✅ Web: reCAPTCHA v3 activated.');
      } else if (kDebugMode) {
        // Debug Mode: Use debug provider — no real attestation needed
        // This allows testing without Play Integrity setup.
        // The debug token will be printed to the console.
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('[AppCheck] ⚠️ DEBUG: Using debug providers (not for production).');
      } else {
        // Release Mode: Real attestation
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
        );
        debugPrint('[AppCheck] ✅ Release: Play Integrity + DeviceCheck activated.');
      }

      // Set up a token refresh listener for logging/monitoring
      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        if (token != null) {
          debugPrint('[AppCheck] Token refreshed (length: ${token.length}).');
        } else {
          debugPrint('[AppCheck] ⚠️ Token became null — possible enforcement block.');
        }
      });
    } catch (e) {
      // CRITICAL: Never crash the app if App Check fails.
      // In non-enforcement mode, the app continues normally.
      // In enforcement mode, Firestore/Auth calls will fail for unverified clients.
      debugPrint('[AppCheck] ❌ Initialization error: $e. Proceeding without App Check.');
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
      debugPrint('[AppCheck] Token fetch failed: $e');
      return null;
    }
  }
}
