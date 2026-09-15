import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
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
  double _convenienceFee = 20.0;
  bool _isConvenienceFeeFree = true;
  double _gstRate = 0.0;
  bool _gstIsPercentage = true;
  bool _gstIsFree = false;

  final StreamController<bool> _maintenanceController = StreamController<bool>.broadcast();
  final StreamController<void> _configUpdateController = StreamController<void>.broadcast();
  StreamSubscription? _remoteConfigSubscription;

  Future<void> initialize() async {
    try {
      debugPrint('🚀 REMOTE CONFIG INIT STARTED (Firebase & Supabase)');

      // 1. Initialize Firebase Remote Config
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        ));
        await remoteConfig.fetchAndActivate();
        _readFromFirebase(remoteConfig);

        _remoteConfigSubscription = remoteConfig.onConfigUpdated.listen((event) async {
          debugPrint('🚀 FIREBASE REMOTE CONFIG UPDATED (User App)');
          await remoteConfig.activate();
          _readFromFirebase(remoteConfig);
          _maintenanceController.add(isMaintenanceMode);
          _configUpdateController.add(null);
        });
      } catch (e) {
        debugPrint('⚠️ FIREBASE REMOTE CONFIG INIT NOTICE: $e');
      }

      // 2. Fetch Supabase App Config (Realtime Sync & Fallback)
      await fetchAndActivate();

      _maintenanceController.add(isMaintenanceMode);
      _configUpdateController.add(null);

      Supabase.instance.client
          .channel('public:app_config')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'app_config',
            callback: (payload) async {
              debugPrint('🚀 SUPABASE CONFIG UPDATED: ${payload.newRecord}');
              await fetchAndActivate();
              _maintenanceController.add(isMaintenanceMode);
              _configUpdateController.add(null);
            },
          )
          .subscribe((status, [error]) {
            debugPrint('🚀 REALTIME STATUS: $status');
            if (error != null) {
              debugPrint('❌ REALTIME ERROR: $error');
            }
          });
    } catch (e, stack) {
      debugPrint('❌ REMOTE CONFIG INITIALIZATION FAILED');
      debugPrint(e.toString());
      debugPrint(stack.toString());
    }
  }

  void _readFromFirebase(FirebaseRemoteConfig remoteConfig) {
    try {
      final keys = remoteConfig.getAll();
      if (keys.containsKey('platform_fee')) {
        final feeNum = remoteConfig.getDouble('platform_fee');
        if (feeNum > 0) {
          _platformFee = feeNum;
        } else {
          _platformFee = double.tryParse(remoteConfig.getString('platform_fee')) ?? _platformFee;
        }
      }
      if (keys.containsKey('commission_rate')) {
        final commNum = remoteConfig.getDouble('commission_rate');
        if (commNum > 0) {
          _commissionRate = commNum;
        } else {
          _commissionRate = double.tryParse(remoteConfig.getString('commission_rate')) ?? _commissionRate;
        }
      }
      if (keys.containsKey('commission_is_percentage')) {
        _commissionIsPercentage = remoteConfig.getBool('commission_is_percentage') ||
            remoteConfig.getString('commission_is_percentage') == 'true';
      }
      if (keys.containsKey('convenience_fee')) {
        final feeNum = remoteConfig.getDouble('convenience_fee');
        if (feeNum > 0) {
          _convenienceFee = feeNum;
        } else {
          _convenienceFee = double.tryParse(remoteConfig.getString('convenience_fee')) ?? _convenienceFee;
        }
      }
      if (keys.containsKey('convenience_fee_is_free')) {
        _isConvenienceFeeFree = remoteConfig.getBool('convenience_fee_is_free') ||
            remoteConfig.getString('convenience_fee_is_free') == 'true';
      }
      if (keys.containsKey('platform_fee_is_free')) {
        _isConvenienceFeeFree = remoteConfig.getBool('platform_fee_is_free') ||
            remoteConfig.getString('platform_fee_is_free') == 'true';
      }
      if (keys.containsKey('gst_rate')) {
        final gstNum = remoteConfig.getDouble('gst_rate');
        if (gstNum >= 0) {
          _gstRate = gstNum;
        } else {
          _gstRate = double.tryParse(remoteConfig.getString('gst_rate')) ?? _gstRate;
        }
      }
      if (keys.containsKey('gst_is_percentage')) {
        _gstIsPercentage = remoteConfig.getBool('gst_is_percentage') ||
            remoteConfig.getString('gst_is_percentage') == 'true';
      }
      if (keys.containsKey('gst_is_free')) {
        _gstIsFree = remoteConfig.getBool('gst_is_free') ||
            remoteConfig.getString('gst_is_free') == 'true';
      }
      if (keys.containsKey('user_app_maintenance')) {
        _isMaintenanceMode = remoteConfig.getBool('user_app_maintenance') ||
            remoteConfig.getString('user_app_maintenance') == 'true';
      }
      if (keys.containsKey('user_android_min_version')) {
        _requiredVersionAndroid = remoteConfig.getString('user_android_min_version');
      }
      if (keys.containsKey('user_ios_min_version')) {
        _requiredVersionIos = remoteConfig.getString('user_ios_min_version');
      }
      if (keys.containsKey('user_android_store_url')) {
        _updateUrlAndroid = remoteConfig.getString('user_android_store_url');
      }
      if (keys.containsKey('user_ios_store_url')) {
        _updateUrlIos = remoteConfig.getString('user_ios_store_url');
      }
    } catch (e) {
      debugPrint('⚠️ Error reading Firebase Remote Config: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetchAndActivate();
        _readFromFirebase(remoteConfig);
      } catch (_) {}

      final rows = await Supabase.instance.client.from('app_config').select('key, value');
      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
            final parsedFee = double.tryParse(val);
            if (parsedFee != null) _platformFee = parsedFee;
            break;
          case 'commission_rate':
            final parsedComm = double.tryParse(val);
            if (parsedComm != null) _commissionRate = parsedComm;
            break;
          case 'commission_is_percentage':
            _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'convenience_fee':
            final parsedFee = double.tryParse(val);
            if (parsedFee != null) _convenienceFee = parsedFee;
            break;
          case 'convenience_fee_is_free':
          case 'platform_fee_is_free':
            _isConvenienceFeeFree = val == 'true' || val == '1';
            break;
          case 'gst_rate':
            final parsedGst = double.tryParse(val);
            if (parsedGst != null) _gstRate = parsedGst;
            break;
          case 'gst_is_percentage':
            _gstIsPercentage = val == 'true' || val == '1';
            break;
          case 'gst_is_free':
            _gstIsFree = val == 'true' || val == '1';
            break;
          case 'user_app_maintenance':
            _isMaintenanceMode = val == 'true' || val == '1';
            break;
          case 'user_android_min_version':
            if (val.isNotEmpty) _requiredVersionAndroid = val;
            break;
          case 'user_ios_min_version':
            if (val.isNotEmpty) _requiredVersionIos = val;
            break;
          case 'user_android_store_url':
            if (val.isNotEmpty) _updateUrlAndroid = val;
            break;
          case 'user_ios_store_url':
            if (val.isNotEmpty) _updateUrlIos = val;
            break;
        }
      }
      debugPrint('🔥 FETCH AND ACTIVATE SUCCESS: platformFee=$_platformFee, convFee=$_convenienceFee (free: $_isConvenienceFeeFree), gstRate=$_gstRate');
    } catch (e) {
      debugPrint('❌ FETCH AND ACTIVATE FAILED: $e');
    }
  }

  void dispose() {
    _remoteConfigSubscription?.cancel();
    _maintenanceController.close();
    _configUpdateController.close();
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

  double get platformFee => _platformFee > 0 ? _platformFee : _convenienceFee;

  double get commissionRate => _commissionRate;

  bool get commissionIsPercentage => _commissionIsPercentage;

  Stream<void> get configUpdatesStream => _configUpdateController.stream;

  double get convenienceFee => platformFee;

  bool get isConvenienceFeeFree => _isConvenienceFeeFree;

  bool get isPlatformFeeFree => _isConvenienceFeeFree;

  double get gstRate => _gstRate;

  bool get gstIsPercentage => _gstIsPercentage;

  bool get gstIsFree => _gstIsFree;

  double calculateGst(double basePrice) {
    if (_gstIsFree || _gstRate <= 0) return 0.0;
    if (_gstIsPercentage) {
      return (basePrice * _gstRate) / 100.0;
    }
    return _gstRate;
  }

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