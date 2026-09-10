import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      await updateFcmToken();
      return;
    }
    _isInitialized = true;
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

    // 5. Keep token synced when user logs in or auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await updateFcmToken();
      }
    });

    // 6. Handle foreground messages (mobile only)
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }

    // 7. Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 8. Check if app opened from a notification
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

    // Explicitly create notification channels on Android
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'user_notifications',
          'User Notifications',
          description: 'General notifications for users',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'booking_confirmed_channel',
          'Booking Confirmed',
          description: 'Plays sound when a booking is confirmed or approved',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('booking_confirmed'),
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'owner_notifications',
          'Owner Notifications',
          description: 'Notifications for venue owners',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.messageId} data: ${message.data}');

    final notification = message.notification;
    String title = notification?.title ?? message.data['title']?.toString() ?? '';
    String body = notification?.body ?? message.data['message']?.toString() ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final type = message.data['type']?.toString() ?? '';
    final isBookingSound = type == 'booking_confirmed' || type == 'booking_approved' || type == 'new_booking';

    _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data.toString(),
      isBookingSound: isBookingSound,
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
    bool isBookingSound = false,
  }) async {
    // Booking confirmed → dedicated channel with cricket sound
    // Other notifications → default channel
    final AndroidNotificationDetails androidDetails = isBookingSound
        ? const AndroidNotificationDetails(
            'booking_confirmed_channel',
            'Booking Confirmed',
            channelDescription: 'Plays a cricket sound when a slot is booked',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('booking_confirmed'),
            playSound: true,
          )
        : const AndroidNotificationDetails(
            'user_notifications',
            'User Notifications',
            channelDescription: 'General notifications for users',
            importance: Importance.high,
            priority: Priority.high,
          );

    final DarwinNotificationDetails iosDetails = isBookingSound
        ? const DarwinNotificationDetails(sound: 'booking_confirmed.mp3')
        : const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> scheduleBookingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime bookingStartTime,
  }) async {
    if (kIsWeb) return;
    
    // Make sure timezones are initialized! (Done in main.dart)
    final scheduledDate = bookingStartTime.subtract(const Duration(minutes: 30));
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = const AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Notifications for upcoming bookings',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          scheduledDate.hour,
          scheduledDate.minute,
        ),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("DEBUG: [NotificationService] Scheduled reminder for $scheduledDate");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to schedule reminder: $e");
    }
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

      // Check if token already exists to bypass strict unique constraints on upsert
      final platform = 'user_${kIsWeb ? 'web' : defaultTargetPlatform.name}';
      final existingTokens = await Supabase.instance.client
          .from('fcm_tokens')
          .select('id')
          .eq('token', token)
          .limit(1);

      if (existingTokens.isNotEmpty) {
        await Supabase.instance.client.from('fcm_tokens').update({
          'user_id': user.uid,
          'platform': platform,
          'last_used_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('token', token);
      } else {
        await Supabase.instance.client.from('fcm_tokens').insert({
          'user_id': user.uid,
          'token': token,
          'platform': platform,
          'last_used_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // Also keep legacy column in sync
      await Supabase.instance.client
          .from('users')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.uid);
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to update token in Supabase: $e");
      try {
        final user = FirebaseAuth.instance.currentUser;
        await Supabase.instance.client.from('fcm_tokens').insert({
          'user_id': user?.uid ?? 'unknown',
          'token': 'ERROR: ${e.toString().substring(0, e.toString().length > 200 ? 200 : e.toString().length)}',
          'platform': 'error_log',
          'last_used_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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
