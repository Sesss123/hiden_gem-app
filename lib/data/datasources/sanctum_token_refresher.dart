import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';
import 'user_preference_service.dart';

/// Silently mints a fresh Sanctum token from the already-signed-in Firebase
/// user, with no UI. Used by SecureHttpClient to recover from a 401 caused
/// by Sanctum token expiry (config/sanctum.php `expiration`) as long as the
/// underlying Firebase session is still valid.
///
/// Deliberately duplicates the request shape of
/// AuthService._syncWithLaravelSanctum rather than importing AuthService,
/// which pulls in Firestore/FCM/UI-adjacent dependencies this low-level
/// network layer shouldn't depend on. Uses a plain `http.post` (not
/// SecureHttpClient) to avoid re-entrant signing/retry recursion --
/// /auth/firebase-login isn't behind the zenith middleware anyway.
class SanctumTokenRefresher {
  /// Returns the new bearer token on success, or null if refresh failed
  /// (e.g. the Firebase session itself is invalid/expired) -- callers treat
  /// null as "let the original 401 propagate".
  static Future<String?> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final idToken = await user.getIdToken(true); // force-refresh
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('${AppConfig.laravelUrl}/auth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': idToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final token = data['data']?['access_token'] as String?;
      if (token == null) return null;

      await UserPreferenceService.saveAuthToken(token);
      return token;
    } catch (e) {
      SecureLogger.warning('Silent Sanctum refresh failed: $e', tag: 'Auth');
      return null;
    }
  }
}
