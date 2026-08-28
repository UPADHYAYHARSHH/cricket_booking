import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';

class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  final LiveActivities _liveActivitiesPlugin = LiveActivities();
  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    try {
      await _liveActivitiesPlugin.init(
        appGroupId: 'group.com.example.app', // Update this if you have an app group
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint("Failed to initialize live activities: $e");
    }
  }

  Future<String?> startBookingActivity({
    required String groundName,
    required DateTime startTime,
  }) async {
    if (kIsWeb) return null;
    
    // Check if live activities are supported (iOS 16.1+)
    final areActivitiesEnabled = await _liveActivitiesPlugin.areActivitiesEnabled();
    if (!areActivitiesEnabled) return null;

    try {
      final activityId = "booking_${DateTime.now().millisecondsSinceEpoch}";
      final resultId = await _liveActivitiesPlugin.createActivity(
        activityId,
        {'groundName': groundName, 'startTime': startTime.toIso8601String()},
      );
      debugPrint("Started live activity: $resultId");
      return resultId;
    } catch (e) {
      debugPrint("Failed to start live activity: $e");
      return null;
    }
  }

  Future<void> endBookingActivity(String activityId) async {
    if (kIsWeb) return;
    try {
      await _liveActivitiesPlugin.endActivity(activityId);
    } catch (e) {
      debugPrint("Failed to end live activity: $e");
    }
  }
}
