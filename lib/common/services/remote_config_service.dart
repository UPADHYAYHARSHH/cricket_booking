import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  RemoteConfigService._internal();

  bool _isMaintenanceMode = false;
  String _requiredVersionAndroid = '1.0.0';
  String _requiredVersionIos = '1.0.0';
  String _updateUrlAndroid = '';
  String _updateUrlIos = '';
  double _platformFee = 0.0;
  double _commissionRate = 0.0;
  bool _commissionIsPercentage = true;

  final StreamController<bool> _maintenanceController = StreamController<bool>.broadcast();

  Future<void> initialize() async {
    try {
      debugPrint('🚀 REMOTE CONFIG INIT STARTED (Supabase)');

      await fetchAndActivate();

      _maintenanceController.add(isMaintenanceMode);

      if (!kIsWeb) {
        Supabase.instance.client
            .channel('public:app_config')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'app_config',
              callback: (payload) async {
                debugPrint('🚀 CONFIG UPDATED: ${payload.newRecord}');
                await fetchAndActivate();
                _maintenanceController.add(isMaintenanceMode);
              },
            )
            .subscribe();
      }
    } catch (e, stack) {
      debugPrint('❌ REMOTE CONFIG INITIALIZATION FAILED');
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      final rows = await Supabase.instance.client.from('app_config').select('key, value');
      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
            _platformFee = double.tryParse(val) ?? 0.0;
            break;
          case 'commission_rate':
            _commissionRate = double.tryParse(val) ?? 0.0;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'user_app_maintenance':
            _isMaintenanceMode = val == 'true' || val == '1';
            break;
          case 'user_android_min_version':
            _requiredVersionAndroid = val;
            break;
          case 'user_ios_min_version':
            _requiredVersionIos = val;
            break;
          case 'user_android_store_url':
            _updateUrlAndroid = val;
            break;
          case 'user_ios_store_url':
            _updateUrlIos = val;
            break;
        }
      }
      debugPrint('🔥 FETCH AND ACTIVATE SUCCESS');
    } catch (e) {
      debugPrint('❌ FETCH AND ACTIVATE FAILED: $e');
    }
  }

  void dispose() {
    _maintenanceController.close();
  }

  Stream<bool> get maintenanceModeStream => _maintenanceController.stream;

  bool get isMaintenanceMode => _isMaintenanceMode;

  String get requiredVersion {
    if (kIsWeb) return _requiredVersionAndroid;
    if (Platform.isIOS) return _requiredVersionIos;
    return _requiredVersionAndroid;
  }

  String get updateUrl {
    if (kIsWeb) return _updateUrlAndroid;
    if (Platform.isIOS) return _updateUrlIos;
    return _updateUrlAndroid;
  }

  double get platformFee => _platformFee;

  double get commissionRate => _commissionRate;

  bool get commissionIsPercentage => _commissionIsPercentage;

  Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      return _isVersionGreaterThan(requiredVersion, currentVersion);
    } catch (e) {
      debugPrint('❌ VERSION CHECK ERROR: $e');
      return false;
    }
  }

  bool _isVersionGreaterThan(String v1, String v2) {
    if (v1.isEmpty) return false;
    if (v2.isEmpty) return false;
    List<int> v1List = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> v2List = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

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