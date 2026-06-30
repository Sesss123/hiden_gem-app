import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/brute_force_service.dart';
import 'user_preference_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // google_sign_in v6 — stable cross-platform constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
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
        // Mobile: google_sign_in v6 flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
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
      debugPrint("Error during Google Sign-In: $e");
      rethrow;
    }
  }


  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
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
      debugPrint("Error during Email Sign-Up: $e");
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
      
      debugPrint("Error during Email Sign-In: $e");
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
  }

  // Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      try { await _googleSignIn.signOut(); } catch (_) {}
    }
    await _auth.signOut();
    await UserPreferenceService.clearProfile();
  }
  
  // Delete Account (Permanent)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // 1. Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // 2. Delete the user in Firebase Auth
      await user.delete();
      
      // 3. Clear local profile
      await UserPreferenceService.clearProfile();
      if (!kIsWeb) {
        try { await _googleSignIn.signOut(); } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error during Account Deletion: $e");
      rethrow;
    }
  }
}
