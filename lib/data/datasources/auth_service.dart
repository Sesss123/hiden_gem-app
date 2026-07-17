import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/config/app_config.dart';
import '../../core/services/brute_force_service.dart';
import '../../core/utils/secure_logger.dart';
import '../../core/notifications/notification_service.dart';
import 'user_preference_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // google_sign_in v7 requires an explicit one-time initialize() before
  // authenticate() can be called on Android/iOS.
  static bool _googleSignInInitialized = false;

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: use Firebase popup flow
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        final UserCredential userCredential =
            await _auth.signInWithPopup(googleProvider);
        if (userCredential.user != null) {
          await _syncUserData(userCredential.user!);
        }
        return userCredential;
      } else {
        // Mobile: google_sign_in v7 flow
        if (!_googleSignInInitialized) {
          await GoogleSignIn.instance.initialize(
            // Web client ID from google-services.json (client_type: 3) —
            // required so Firebase can verify the Google ID token server-side.
            serverClientId: '932776629360-8n1phprf43pdq41hsknog1t66peguiog.apps.googleusercontent.com',
          );
          _googleSignInInitialized = true;
        }
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(scopeHint: ['email']);

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        
        // Request authorization for scopes if accessToken is needed by Firebase
        final GoogleSignInClientAuthorization authz = 
            await googleUser.authorizationClient.authorizeScopes(['email']);

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authz.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _syncUserData(userCredential.user!);
        }
        return userCredential;
      }
    } catch (e) {
      SecureLogger.error("Error during Google Sign-In: $e");
      rethrow;
    }
  }


  // Sign in with Apple (App Store Guideline 4.8 — required alongside Google Sign-In)
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);
      if (userCredential.user != null) {
        // Apple only returns givenName/familyName on the FIRST authorization
        // ever — Firebase's displayName is usually null for Apple sign-ins,
        // so pass it through explicitly when available.
        final name = [appleCredential.givenName, appleCredential.familyName]
            .whereType<String>()
            .join(' ')
            .trim();
        await _syncUserData(userCredential.user!, name: name.isEmpty ? null : name);
      }
      return userCredential;
    } catch (e) {
      SecureLogger.error("Error during Apple Sign-In: $e");
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    // BUG-030 Fix: Clear local auth tokens upon triggering account recovery / password reset
    await UserPreferenceService.clearAuthToken();
  }

  // Sign up with Email
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);
        // Sync to Firestore
        await _syncUserData(userCredential.user!, name: name);
        // Email/password signups aren't pre-verified the way Google
        // Sign-In accounts are (Google's own email_verified claim is
        // already true) — send a verification email so this account can
        // later clear the email_verified_at gate the Laravel backend now
        // requires before a guide application can be submitted.
        try {
          await userCredential.user!.sendEmailVerification();
        } catch (e) {
          SecureLogger.warning("Failed to send verification email: $e");
        }
      }
      return userCredential;
    } catch (e) {
      SecureLogger.error("Error during Email Sign-Up: $e");
      rethrow;
    }
  }

  // Sign in with Email
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    final guard = BruteForceService();
    await guard.init();

    if (guard.isLockedOut) {
      throw Exception('ZENITH_LOCKOUT|${guard.remainingLockout.inSeconds}');
    }

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await guard.reset(); // Clear failures on success
        await _syncUserData(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      // Record failure if it's a password issue
      if (e is FirebaseAuthException && 
         (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'user-not-found')) {
        await guard.recordFailure();
      }
      
      SecureLogger.error("Error during Email Sign-In: $e");
      rethrow;
    }
  }

  // Sync user data to Firestore
  Future<void> _syncUserData(User user, {String? name}) async {
    // Force a fresh ID token before the first Firestore call after sign-in.
    // Without this, signInWithCredential()/signInWith*() can resolve before
    // the Firestore SDK's underlying gRPC/REST layer has actually picked up
    // the new auth token — firestore.rules' isSignedIn() (request.auth !=
    // null) then evaluates against a stale/absent auth context and every
    // call here fails with permission-denied, even though sign-in itself
    // succeeded and the rules are otherwise correct.
    try {
      await user.getIdToken(true);
    } catch (e) {
      SecureLogger.warning("ID token refresh before Firestore sync failed: $e", tag: "Auth");
    }

    final userDoc = _firestore.collection('users').doc(user.uid);

    // getIdToken(true) refreshes the token Firebase Auth hands out, but the
    // Firestore SDK's own gRPC/REST channel can still take a beat to pick up
    // that refreshed token internally — so the very first Firestore call
    // right after sign-in can still transiently see permission-denied even
    // though the token is now valid. Retry a few times with backoff rather
    // than surfacing this as a hard sign-in failure.
    final docSnapshot = await _withPermissionRetry(() => userDoc.get());
    
    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        'uid': user.uid,
        'displayName': name ?? user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'planCount': 0,
        'isPremium': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    // BUG-N02 Fix: Ensure FCM token is linked to user document on login/signup
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await userDoc.set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      SecureLogger.warning("Could not sync FCM token during login: $e", tag: "Auth", isBackground: true);
    }
    
    // BUG-QA-001 Fix: Sync Firebase Auth with Laravel Sanctum
    await _syncWithLaravelSanctum(user);
  }

  /// Retries [action] up to 3 times (250ms/750ms/1500ms backoff) when it
  /// throws Firestore permission-denied — used for the first Firestore call
  /// right after sign-in, where the SDK's auth channel can lag behind a
  /// just-completed sign-in by a few hundred milliseconds. Any other
  /// exception, or a permission-denied that persists past the last retry,
  /// propagates to the caller unchanged.
  Future<T> _withPermissionRetry<T>(Future<T> Function() action) async {
    const delays = [Duration(milliseconds: 250), Duration(milliseconds: 750), Duration(milliseconds: 1500)];
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied' || attempt >= delays.length) rethrow;
        SecureLogger.warning(
          "Transient permission-denied on attempt ${attempt + 1}, retrying in ${delays[attempt].inMilliseconds}ms",
          tag: "Auth",
        );
        await Future.delayed(delays[attempt]);
      }
    }
  }

  Future<void> _syncWithLaravelSanctum(User user) async {
    try {
      final idToken = await user.getIdToken();
      if (idToken == null) return;
      
      final response = await http.post(
        Uri.parse('${AppConfig.laravelUrl}/auth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': idToken}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['data']['access_token'];
        if (token != null) {
          await UserPreferenceService.saveAuthToken(token);
        }
      }
    } catch (e) {
      SecureLogger.error("Error syncing with Sanctum: $e");
    }
  }

  // Sign out
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    // Tear down the FCM topic subscription before the session is gone —
    // without this, the device keeps receiving pushes meant for the
    // account that just logged out (topic subscriptions are device-level
    // and outlive Firebase Auth sign-out).
    await NotificationService().stopWatchingUserNotifications(uid);

    if (!kIsWeb) {
      try { await GoogleSignIn.instance.signOut(); } catch (e) { SecureLogger.warning('Google sign out failed: $e'); }
    }
    await _auth.signOut();
    await UserPreferenceService.clearProfile();
    await UserPreferenceService.clearAuthToken();
  }
  
  // Delete Account (Permanent)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // BUG-014 Fix: Attempt Auth deletion FIRST to catch requires-recent-login before touching Firestore/profile
      await user.delete();
      
      // 2. Clear local profile, auth tokens, and sign out of providers
      await UserPreferenceService.clearProfile();
      await UserPreferenceService.clearAuthToken();
      if (!kIsWeb) {
        try { await GoogleSignIn.instance.signOut(); } catch (e) { SecureLogger.warning('Google sign out failed: $e'); }
      }

      // 3. Best effort Firestore cleanup (server-side Cloud Function / Admin SDK should handle deep cleanup)
      try {
        await _firestore.collection('users').doc(user.uid).delete();
      } catch (e) {
        SecureLogger.warning("Firestore doc deletion handled by backend Admin SDK: $e", tag: "Auth", isBackground: true);
      }
    } catch (e) {
      SecureLogger.error("Error during Account Deletion: $e");
      rethrow;
    }
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
