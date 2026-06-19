import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permissions for iOS/Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('[Notifications] User granted permission.');
    }

    // Get FCM Token for server-side targeting
    String? token = await _fcm.getToken();
    debugPrint("[Notifications] FCM Token: $token");

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[Notifications] Got a message whilst in the foreground!');
      debugPrint('[Notifications] Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('[Notifications] Message also contained a notification: ${message.notification}');
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint("[Notifications] Handling a background message: ${message.messageId}");
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint("[Notifications] Subscribed to $topic");
  }
}
