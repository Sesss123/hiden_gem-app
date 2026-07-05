import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/secure_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _foregroundMessageController = StreamController<RemoteMessage>.broadcast();
  StreamSubscription? _notifSub;
  final Set<String> _seenNotifIds = {};

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
      SecureLogger.info("User granted push notification permission.", tag: "Notifications");
    }

    // BUG-N01 Fix: Enable native presentation options for foreground notifications on Apple/Web
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM Token for server-side targeting
    String? token = await _fcm.getToken();
    if (token != null) {
      SecureLogger.info("FCM Token acquired: ${token.length > 8 ? '${token.substring(0, 8)}...' : token}", tag: "Notifications");
    }
    
    // BUG-N02 Fix: Sync token to backend/Firestore for targeted user pushes
    await syncTokenToServer(token);

    // BUG-N03 Fix: Listen for token rotation and re-sync automatically
    _fcm.onTokenRefresh.listen((newToken) {
      SecureLogger.bgTask("FCM Token refreshed: ${newToken.substring(0, 8)}...", tag: "Notifications");
      syncTokenToServer(newToken);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SecureLogger.uiEvent("Foreground Push Received: ${message.notification?.title ?? message.messageId}", tag: "Notifications");

      // BUG-N01 Fix: Broadcast to listeners so active screens can show Heads-Up Snackbars/Toasts
      _foregroundMessageController.add(message);
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      startWatchingUserNotifications(currentUser.uid);
      subscribeToTopic('guide_${currentUser.uid}');
    }
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
        startWatchingUserNotifications(user.uid);
        subscribeToTopic('guide_${user.uid}');
        SecureLogger.info("FCM Token synced to Firestore for user: ${user.uid}", tag: "Notifications", isBackground: true);
      }
    } catch (e) {
      SecureLogger.warning("Failed to sync FCM token: $e", tag: "Notifications", isBackground: true);
    }
  }

  void startWatchingUserNotifications(String uid) {
    _notifSub?.cancel();
    _notifSub = FirebaseFirestore.instance
        .collection('user_notifications')
        .where('recipientId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && !_seenNotifIds.contains(change.doc.id)) {
            _seenNotifIds.add(change.doc.id);
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            // Only trigger alert for notifications created within the last 15 minutes
            if (DateTime.now().difference(createdAt).inMinutes < 15) {
              final title = data['title'] as String? ?? 'New Notification';
              final body = data['body'] as String? ?? '';
              _foregroundMessageController.add(RemoteMessage(
                notification: RemoteNotification(title: title, body: body),
                data: {'bookingId': data['bookingId'] ?? '', 'type': data['type'] ?? ''},
              ));
            }
          }
        }
      }
    }, onError: (e) {
      SecureLogger.warning("Error watching user notifications: $e", tag: "Notifications");
    });
  }

  void stopWatchingUserNotifications() {
    _notifSub?.cancel();
    _notifSub = null;
    _seenNotifIds.clear();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    SecureLogger.bgTask("Handling background push message: ${message.messageId} (Title: ${message.notification?.title ?? 'No Title'})", tag: "Notifications");
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    SecureLogger.info("Subscribed to topic: $topic", tag: "Notifications");
  }

  void dispose() {
    _foregroundMessageController.close();
  }
}
