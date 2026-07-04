import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/secure_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _foregroundMessageController = StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground push notifications for UI banners/toasts
  Stream<RemoteMessage> get onForegroundMessage => _foregroundMessageController.stream;

  Future<void> init() async {
    // Request permissions for iOS/Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        debugPrint('[Notifications] User granted permission.');
      }
    }

    // BUG-N01 Fix: Enable native presentation options for foreground notifications on Apple/Web
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM Token for server-side targeting
    String? token = await _fcm.getToken();
    if (kDebugMode && token != null) {
      // BUG-N04 Fix: Truncate token in debug logs and never log in release mode
      debugPrint("[Notifications] FCM Token acquired: ${token.length > 8 ? '${token.substring(0, 8)}...' : token}");
    }
    
    // BUG-N02 Fix: Sync token to backend/Firestore for targeted user pushes
    await syncTokenToServer(token);

    // BUG-N03 Fix: Listen for token rotation and re-sync automatically
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint("[Notifications] FCM Token refreshed: ${newToken.substring(0, 8)}...");
      }
      syncTokenToServer(newToken);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[Notifications] Got a message whilst in the foreground!');
      }
      SecureLogger.uiEvent("Foreground Push Received: ${message.notification?.title ?? message.messageId}", tag: "Notifications");

      // BUG-N01 Fix: Broadcast to listeners so active screens can show Heads-Up Snackbars/Toasts
      _foregroundMessageController.add(message);
    });
  }

  /// BUG-N02 Fix: Upload FCM token to authenticated user's Firestore profile
  Future<void> syncTokenToServer(String? token) async {
    if (token == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        SecureLogger.info("FCM Token synced to Firestore for user: ${user.uid}", tag: "Notifications", isBackground: true);
      }
    } catch (e) {
      SecureLogger.warning("Failed to sync FCM token: $e", tag: "Notifications", isBackground: true);
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint("[Notifications] Handling a background message: ${message.messageId}");
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    if (kDebugMode) {
      debugPrint("[Notifications] Subscribed to $topic");
    }
  }
}
