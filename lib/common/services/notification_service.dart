import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await updateFcmToken();
    } else {
      if (!kIsWeb) {
        await _localNotifications.cancelAll();
      }
      await clearFcmToken();
    }
  }

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

    if (!kIsWeb) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
          'booking_reminders',
          'Booking Reminders',
          description: 'Notifications for upcoming bookings',
          importance: Importance.max,
          playSound: true,
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

  static final Map<String, DateTime> _recentNotificationKeys = {};

  static void _handleForegroundMessage(RemoteMessage message) async {
    if (!await areNotificationsEnabled()) {
      debugPrint('Foreground message received, but notifications are disabled by user. Suppressing.');
      return;
    }
    debugPrint('Foreground message: ${message.messageId} data: ${message.data}');

    final notification = message.notification;
    String title = notification?.title ?? message.data['title']?.toString() ?? '';
    String body = notification?.body ?? message.data['message']?.toString() ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) return;

    // Deduplicate rapid duplicate foreground pushes for the same notification/booking
    final notifKey = message.data['notification_id']?.toString() ??
        message.data['booking_id']?.toString() ??
        '${title}_$body';

    final now = DateTime.now();
    _recentNotificationKeys.removeWhere((k, t) => now.difference(t).inSeconds > 30);
    if (_recentNotificationKeys.containsKey(notifKey)) {
      debugPrint('Skipping duplicate foreground notification for key: $notifKey');
      return;
    }
    _recentNotificationKeys[notifKey] = now;

    final type = message.data['type']?.toString() ?? '';
    final isBookingSound = type == 'booking_confirmed' || type == 'booking_approved' || type == 'new_booking';

    final int localId = notifKey.hashCode & 0x7FFFFFFF;

    _showLocalNotification(
      id: localId,
      tag: notifKey,
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
    String? tag,
    required String title,
    required String body,
    String? payload,
    bool isBookingSound = false,
  }) async {
    // Booking confirmed → dedicated channel with cricket sound
    // Other notifications → default channel
    final AndroidNotificationDetails androidDetails = isBookingSound
        ? AndroidNotificationDetails(
            'booking_confirmed_channel',
            'Booking Confirmed',
            channelDescription: 'Plays a cricket sound when a slot is booked',
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('booking_confirmed'),
            playSound: true,
            tag: tag,
            onlyAlertOnce: true,
          )
        : AndroidNotificationDetails(
            'user_notifications',
            'User Notifications',
            channelDescription: 'General notifications for users',
            importance: Importance.high,
            priority: Priority.high,
            tag: tag,
            onlyAlertOnce: true,
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
    if (!await areNotificationsEnabled()) {
      debugPrint("DEBUG: [NotificationService] Notifications are disabled, skipping reminder scheduling.");
      return;
    }

    final now = DateTime.now();
    if (bookingStartTime.isBefore(now)) {
      debugPrint("DEBUG: [NotificationService] Booking time is already in the past: $bookingStartTime");
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'Booking Reminders',
      channelDescription: 'Notifications for upcoming bookings',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = bookingStartTime.subtract(const Duration(minutes: 30));

    // If game starts in 30 minutes or less, show an immediate notification
    if (scheduledDate.isBefore(now)) {
      final minutesLeft = bookingStartTime.difference(now).inMinutes;
      final immediateBody = minutesLeft > 0
          ? "Your game starts in $minutesLeft minute${minutesLeft == 1 ? '' : 's'}!"
          : "Your game starts now!";
      try {
        await _localNotifications.show(
          id,
          title,
          immediateBody,
          details,
        );
        debugPrint("DEBUG: [NotificationService] Showed immediate reminder because game starts in $minutesLeft minutes");
      } catch (e) {
        debugPrint("DEBUG: [NotificationService] Failed to show immediate reminder: $e");
      }
      return;
    }

    // Convert DateTime to TZDateTime in local timezone
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      // Attempt exact alarm first
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("DEBUG: [NotificationService] Scheduled exact reminder for $tzScheduledDate");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Exact alarm failed ($e), falling back to inexact");
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint("DEBUG: [NotificationService] Scheduled inexact reminder for $tzScheduledDate");
      } catch (fallbackError) {
        debugPrint("DEBUG: [NotificationService] Failed to schedule reminder: $fallbackError");
      }
    }
  }

  static Future<void> updateFcmToken() async {
    try {
      if (!await areNotificationsEnabled()) {
        debugPrint("DEBUG: [NotificationService] Notifications disabled by user, skipping token registration");
        return;
      }

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

      final platform = 'user_${kIsWeb ? 'web' : defaultTargetPlatform.name}';

      // 1. Remove stale mappings for this device token
      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('token', token);

      // 2. Remove any previous token for this user (respects unique user_id constraint)
      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('user_id', user.uid);

      // 3. Insert fresh token directly into Supabase
      await Supabase.instance.client.from('fcm_tokens').insert({
        'user_id': user.uid,
        'token': token,
        'platform': platform,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("DEBUG: [NotificationService] Token updated successfully in Supabase for user: ${user.uid}");
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
