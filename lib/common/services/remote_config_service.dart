import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance =
      RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  RemoteConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig =
      FirebaseRemoteConfig.instance;

  // Keys
  static const String _kMaintenanceMode =
      'is_under_maintenance';

  static const String _kRequiredVersion =
      'required_version';

  static const String _kUpdateUrl =
      'update_url';

  final StreamController<bool> _maintenanceController =
      StreamController<bool>.broadcast();

  Timer? _webPollTimer;

  Future<void> initialize() async {
    try {
      debugPrint('🚀 REMOTE CONFIG INIT STARTED');

      /// DEFAULTS
      await _remoteConfig.setDefaults({
        _kMaintenanceMode: false,
        _kRequiredVersion: '1.0.0',
        _kUpdateUrl:
            'https://play.google.com/store/apps/details?id=com.boxcricket.booking',
      });

      debugPrint('✅ DEFAULTS SET');

      /// SETTINGS
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: Duration.zero,
        ),
      );

      debugPrint('✅ CONFIG SETTINGS APPLIED');

      /// FETCH
      try {
        debugPrint('🌐 FETCHING REMOTE CONFIG...');

        final updated =
            await _remoteConfig.fetchAndActivate();

        debugPrint(
            '🔥 FETCH AND ACTIVATE SUCCESS: $updated');

      } catch (e, stack) {
        debugPrint(
            '❌ FETCH AND ACTIVATE FAILED');
        debugPrint(e.toString());
        debugPrint(stack.toString());
      }

      /// PRINT VALUES
      _printAllRemoteValues();

      /// STREAM INITIAL VALUE
      _maintenanceController.add(isMaintenanceMode);

      /// REALTIME LISTENER
      if (!kIsWeb) {
        debugPrint(
            '📱 USING REALTIME REMOTE CONFIG LISTENER');

        _remoteConfig.onConfigUpdated.listen(
          (event) async {
            debugPrint(
                '🚀 CONFIG UPDATED: ${event.updatedKeys}');

            try {
              await _remoteConfig.activate();

              debugPrint('✅ CONFIG ACTIVATED');

              _printAllRemoteValues();

              _maintenanceController
                  .add(isMaintenanceMode);

            } catch (e) {
              debugPrint(
                  '❌ REALTIME ACTIVATE ERROR: $e');
            }
          },
        );
      } else {
        debugPrint(
            '🌐 WEB MODE DETECTED - STARTING POLLING');

        _startWebPolling();
      }
    } catch (e, stack) {
      debugPrint(
          '❌ REMOTE CONFIG INITIALIZATION FAILED');

      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
  }

  void _startWebPolling() {
    _webPollTimer?.cancel();

    _webPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        try {
          debugPrint(
              '🔄 WEB POLLING REMOTE CONFIG...');

          final updated =
              await _remoteConfig.fetchAndActivate();

          debugPrint(
              '🔥 WEB FETCH SUCCESS: $updated');

          _printAllRemoteValues();

          _maintenanceController
              .add(isMaintenanceMode);

        } catch (e) {
          debugPrint(
              '❌ WEB POLLING FETCH FAILED: $e');
        }
      },
    );
  }

  void _printAllRemoteValues() {
    try {

      debugPrint(
  '🔍 RAW VALUE: ${_remoteConfig.getValue(_kMaintenanceMode).asString()}',
);

debugPrint(
  '🔍 VALUE SOURCE: ${_remoteConfig.getValue(_kMaintenanceMode).source}',
);
      debugPrint('');
      debugPrint(
          '================ REMOTE CONFIG ================');

      debugPrint(
          '🔍 Maintenance Mode: ${_remoteConfig.getBool(_kMaintenanceMode)}');

      debugPrint(
          '🔍 Required Version: ${_remoteConfig.getString(_kRequiredVersion)}');

      debugPrint(
          '🔍 Update URL: ${_remoteConfig.getString(_kUpdateUrl)}');

      debugPrint(
          '🔍 Last Fetch Status: ${_remoteConfig.lastFetchStatus}');

      debugPrint(
          '🔍 Last Fetch Time: ${_remoteConfig.lastFetchTime}');

      debugPrint(
          '🔍 Maintenance Source: ${_remoteConfig.getValue(_kMaintenanceMode).source}');

      debugPrint(
          '================================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ PRINT VALUES ERROR: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      debugPrint(
          '🔄 MANUAL FETCH AND ACTIVATE CALLED');

      final updated =
          await _remoteConfig.fetchAndActivate();

      debugPrint(
          '🔥 MANUAL FETCH SUCCESS: $updated');

      _printAllRemoteValues();

      _maintenanceController.add(isMaintenanceMode);

    } catch (e) {
      debugPrint(
          '❌ MANUAL FETCH FAILED: $e');
    }
  }

  void dispose() {
    _webPollTimer?.cancel();
    _maintenanceController.close();
  }

  Stream<bool> get maintenanceModeStream =>
      _maintenanceController.stream;

  bool get isMaintenanceMode {
    final value =
        _remoteConfig.getBool(_kMaintenanceMode);

    debugPrint(
        '🔍 [REMOTE CONFIG] Maintenance Mode: $value');

    return value;
  }

  String get requiredVersion =>
      _remoteConfig.getString(_kRequiredVersion);

  String get updateUrl =>
      _remoteConfig.getString(_kUpdateUrl);

  Future<bool> isUpdateRequired() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      final currentVersion =
          packageInfo.version;

      return _isVersionGreaterThan(
        requiredVersion,
        currentVersion,
      );
    } catch (e) {
      debugPrint(
          '❌ VERSION CHECK ERROR: $e');

      return false;
    }
  }

  bool _isVersionGreaterThan(
    String v1,
    String v2,
  ) {
    List<int> v1List =
        v1.split('.').map(int.parse).toList();

    List<int> v2List =
        v2.split('.').map(int.parse).toList();

    int maxLength =
        v1List.length > v2List.length
            ? v1List.length
            : v2List.length;

    for (int i = 0; i < maxLength; i++) {
      int part1 =
          i < v1List.length ? v1List[i] : 0;

      int part2 =
          i < v2List.length ? v2List[i] : 0;

      if (part1 > part2) return true;

      if (part1 < part2) return false;
    }

    return false;
  }
}