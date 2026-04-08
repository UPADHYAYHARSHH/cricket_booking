import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log when a user views a specific ground
  Future<void> logGroundView({required String groundId, required String groundName}) async {
    await _analytics.logEvent(
      name: 'ground_viewed',
      parameters: {
        'ground_id': groundId,
        'ground_name': groundName,
      },
    );
  }

  /// Log when a user starts the booking flow
  Future<void> logBookingStarted({required String groundId, required String groundName}) async {
    await _analytics.logEvent(
      name: 'booking_started',
      parameters: {
        'ground_id': groundId,
        'ground_name': groundName,
      },
    );
  }

  /// Log when a booking is successfully completed
  Future<void> logBookingSuccess({
    required String bookingId,
    required double amount,
    required String groundName,
  }) async {
    await _analytics.logEvent(
      name: 'booking_success',
      parameters: {
        'booking_id': bookingId,
        'amount': amount,
        'ground_name': groundName,
      },
    );
  }

  /// Log when a booking fails
  Future<void> logBookingFailure({required String error}) async {
    await _analytics.logEvent(
      name: 'booking_failed',
      parameters: {
        'error_message': error,
      },
    );
  }

  /// Log user login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Set user ID for cross-device tracking
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
