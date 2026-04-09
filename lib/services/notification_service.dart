import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _tokenRefreshListenerRegistered = false;

  static Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<bool> syncCurrentUserToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final settings = await _messaging.getNotificationSettings();
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) return false;

      final token = await _messaging.getToken();
      if (token == null) return false;

      await _saveToken(
        token: token,
        uid: user.uid,
        email: user.email,
      );

      if (!_tokenRefreshListenerRegistered) {
        _tokenRefreshListenerRegistered = true;
        _messaging.onTokenRefresh.listen((nextToken) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) return;
          _saveToken(
            token: nextToken,
            uid: currentUser.uid,
            email: currentUser.email,
          );
        });
      }
      return true;
    } catch (e) {
      debugPrint('Failed to sync notification token: $e');
      return false;
    }
  }

  static Future<void> _saveToken({
    required String token,
    required String uid,
    required String? email,
  }) async {
    await FirebaseFirestore.instance.collection('device_tokens').doc(token).set({
      'token': token,
      'uid': uid,
      'email': email?.trim().toLowerCase(),
      'platform': defaultTargetPlatform.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeCurrentUserToken() async {
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
    void Function(RemoteMessage) onMessage,
  ) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  static void setupOpenedAppHandler(
    void Function(RemoteMessage) onMessageOpenedApp,
  ) {
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
  }

  static Future<RemoteMessage?> getInitialMessage() async {
    return _messaging.getInitialMessage();
  }
}
