import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

class AppCheckConfig {
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
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
        const siteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY', defaultValue: '6Lfm-GsqAAAAAHA_-Wj_P_X_X_X_X_X_X_X_X');
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(siteKey),
        );
        SecureLogger.info('[AppCheck] ✅ Web: reCAPTCHA v3 activated.');
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleDeviceCheckProvider(),
        );
        SecureLogger.info('[AppCheck] ✅ Release: Play Integrity + DeviceCheck activated.');
      }

      FirebaseAppCheck.instance.onTokenChange.listen((token) {
        if (token != null) {
          SecureLogger.info('[AppCheck] Token refreshed (length: ${token.length}).');
        } else {
          SecureLogger.warning('[AppCheck] ⚠️ Token became null — possible enforcement block.');
        }
      });
    } catch (e) {
      // Never let App Check failure crash the app — Firestore/Auth calls
      // simply fail for unverified clients once enforcement is on.
      SecureLogger.error('[AppCheck] ❌ Initialization error. Proceeding without App Check.', e);
    }
  }

  static Future<String?> getToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken(true);
    } catch (e) {
      SecureLogger.warning('[AppCheck] Token fetch failed: $e');
      return null;
    }
  }
}
