import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static Future<void> init(String userId) async {
    final messaging = FirebaseMessaging.instance;

    // Request permission from user
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return; // user denied, nothing to do
    }

    // Get this device's token and save to Firestore token list
    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Token can change over time — update when it does
    messaging.onTokenRefresh.listen((newToken) {
      _saveToken(userId, newToken);
    });
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      // arrayUnion adds token only if not already in list
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }
}