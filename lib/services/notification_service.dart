import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
    }
  }

  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      _messaging.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    await FirebaseFirestore.instance
        .collection('device_tokens')
        .doc(token)
        .set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('device_tokens')
            .doc(token)
            .delete();
      }
    } catch (e) {
      debugPrint('Failed to remove FCM token: $e');
    }
  }

  static void setupForegroundHandler(
      void Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  static void setupOpenedAppHandler(
      void Function(RemoteMessage) onMessageOpenedApp) {
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }
}
