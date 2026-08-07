import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permissions
    await _requestPermissions();

    // 2. Initialize local notifications (mobile only)
    if (!kIsWeb) {
      await _initializeLocalNotifications();
    }

    // 3. Initial token update
    await updateFcmToken();

    // 4. Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _updateTokenInSupabase(newToken);
    });

    // 5. Handle foreground messages (mobile only)
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }

    // 6. Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 7. Check if app opened from a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Local notification tapped: ${details.payload}');
      },
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    _showLocalNotification(
      id: notification.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('Message tapped: ${message.data}');
    // Navigation will be handled by the app's router based on notification type
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'user_notifications',
      'User Notifications',
      channelDescription: 'Notifications for users',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> updateFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Store locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      // Upsert into fcm_tokens table
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': user.uid,
        'token': token,
        'platform': platform,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');

      // Also keep legacy column in sync
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.uid);
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to update token in Supabase: $e");
    }
  }

  static Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<void> clearFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fcmTokenKey);

      if (user != null && token != null) {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .match({'user_id': user.uid, 'token': token});
      }

      await prefs.remove(_fcmTokenKey);
      debugPrint("DEBUG: [NotificationService] FCM token cleared");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to clear token: $e");
    }
  }
}
