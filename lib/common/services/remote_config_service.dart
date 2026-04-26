import 'dart:convert';
import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Keys
  static const String _kMaintenanceMode = 'is_under_maintenance';
  static const String _kRequiredVersion = 'required_version';
  static const String _kUpdateUrl = 'update_url';

  Timer? _webPollTimer;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults({
        _kMaintenanceMode: false,
        _kRequiredVersion: '1.0.0',
        _kUpdateUrl: 'https://play.google.com/store/apps/details?id=com.boxcricket.booking',
      });

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      await _remoteConfig.fetchAndActivate();

      // Listen for real-time updates (Supported in newer Firebase SDKs, but avoid on Web due to stream-errors)
      if (!kIsWeb) {
        _remoteConfig.onConfigUpdated.listen((event) async {
          await _remoteConfig.activate();
          debugPrint('Remote Config updated: ${event.updatedKeys}');
        });
      } else {
        // Fallback for Web: Periodic polling every 5 minutes in background
        _webPollTimer?.cancel();
        _webPollTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
          await fetchAndActivate();
        });
      }
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    await _remoteConfig.fetchAndActivate();
  }

  void dispose() {
    _webPollTimer?.cancel();
  }

  Stream<bool> get maintenanceModeStream {
    if (kIsWeb) {
      // On web, we don't have onConfigUpdated, so we can use a simpler stream or just rely on the polling above
      // For a stream that reacts to the polling:
      return Stream.periodic(const Duration(minutes: 5)).asyncMap((_) async {
        return isMaintenanceMode;
      });
    }
    return _remoteConfig.onConfigUpdated.asyncMap((event) async {
      await _remoteConfig.activate();
      return isMaintenanceMode;
    });
  }

  bool get isMaintenanceMode => _remoteConfig.getBool(_kMaintenanceMode);
  String get requiredVersion => _remoteConfig.getString(_kRequiredVersion);
  String get updateUrl => _remoteConfig.getString(_kUpdateUrl);

  Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      return _isVersionGreaterThan(requiredVersion, currentVersion);
    } catch (e) {
      return false;
    }
  }

  bool _isVersionGreaterThan(String v1, String v2) {
    List<int> v1List = v1.split('.').map(int.parse).toList();
    List<int> v2List = v2.split('.').map(int.parse).toList();

    int maxLength = v1List.length > v2List.length ? v1List.length : v2List.length;

    for (int i = 0; i < maxLength; i++) {
      int part1 = i < v1List.length ? v1List[i] : 0;
      int part2 = i < v2List.length ? v2List[i] : 0;

      if (part1 > part2) return true;
      if (part1 < part2) return false;
    }
    return false;
  }
}
