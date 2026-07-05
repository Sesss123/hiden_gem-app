import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/brute_force_service.dart';
import '../../core/utils/secure_logger.dart';
import 'user_preference_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      SecureLogger.error("Error during Google Sign-In", e);
      rethrow;
    }
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
      }
      return userCredential;
    } catch (e) {
      SecureLogger.error("Error during Email Sign-Up", e);
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
      
      SecureLogger.error("Error during Email Sign-In", e);
      rethrow;
    }
  }

  // Sync user data to Firestore
  Future<void> _syncUserData(User user, {String? name}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    final docSnapshot = await userDoc.get();
    
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
  }

  // Sign out
  Future<void> signOut() async {
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
      SecureLogger.error("Error during Account Deletion", e);
      rethrow;
    }
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
