import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';

  static Future<void> initialize() async {
    // 1. Initial Update
    await updateFcmToken();

    // 2. Listen for Token Refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _updateTokenInSupabase(newToken);
    });

    // 3. Request Permissions (especially for iOS)
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> updateFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Get FCM Token
      String? token;
      if (!kIsWeb) {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token == null) return;

      debugPrint("\n🚀 [FCM TOKEN]: $token\n");

      await _updateTokenInSupabase(token);
      
      debugPrint("DEBUG: [NotificationService] Token updated successfully");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Error updating token: $e");
    }
  }

  static Future<void> _updateTokenInSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Store locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      // Update in Supabase
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to update token in Supabase: $e");
    }
  }

  static Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }
}
