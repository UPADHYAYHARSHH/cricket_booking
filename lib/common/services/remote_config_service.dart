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
      debugPrint('🚀 REMOTE CONFIG INIT STARTED (Firebase Remote Config)');

      // 1. Initialize Firebase Remote Config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();
      _readFromFirebase(remoteConfig);

      // Realtime listener for Firebase Remote Config
      _remoteConfigSubscription = remoteConfig.onConfigUpdated.listen((event) async {
        debugPrint('🚀 FIREBASE REMOTE CONFIG UPDATED (User App): ${event.updatedKeys}');
        await remoteConfig.activate();
        _readFromFirebase(remoteConfig);
        _maintenanceController.add(isMaintenanceMode);
        _configUpdateController.add(null);
      });

      _maintenanceController.add(isMaintenanceMode);
      _configUpdateController.add(null);

      // 2. Optional Supabase Realtime Fallback (fail-safe)
      try {
        Supabase.instance.client
            .channel('public:app_config')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'app_config',
              callback: (payload) async {
                debugPrint('🚀 SUPABASE CONFIG UPDATED: ${payload.newRecord}');
                await fetchAndActivate();
              },
            )
            .subscribe();
      } catch (e) {
        debugPrint('ℹ️ Supabase config channel skipped/unavailable: $e');
      }
    } catch (e, stack) {
      debugPrint('❌ REMOTE CONFIG INITIALIZATION FAILED: $e');
      debugPrint(stack.toString());
    }
  }

  void _readFromFirebase(FirebaseRemoteConfig remoteConfig) {
    try {
      // Platform Fee / Convenience Fee
      final pfStr = remoteConfig.getString('platform_fee');
      if (pfStr.isNotEmpty) {
        final parsed = double.tryParse(pfStr);
        if (parsed != null) _platformFee = parsed;
      }

      final convStr = remoteConfig.getString('convenience_fee');
      if (convStr.isNotEmpty) {
        final parsed = double.tryParse(convStr);
        if (parsed != null) _convenienceFee = parsed;
      }

      if (_platformFee == 0 && _convenienceFee > 0) {
        _platformFee = _convenienceFee;
      }

      // Free status
      final pfFreeStr = remoteConfig.getString('platform_fee_is_free');
      if (pfFreeStr.isNotEmpty) {
        _isConvenienceFeeFree = pfFreeStr.toLowerCase() == 'true' || pfFreeStr == '1';
      } else {
        final convFreeStr = remoteConfig.getString('convenience_fee_is_free');
        if (convFreeStr.isNotEmpty) {
          _isConvenienceFeeFree = convFreeStr.toLowerCase() == 'true' || convFreeStr == '1';
        }
      }

      // Commission Rate & Percentage
      final commStr = remoteConfig.getString('commission_rate');
      if (commStr.isNotEmpty) {
        final parsed = double.tryParse(commStr);
        if (parsed != null) _commissionRate = parsed;
      }

      final commPercStr = remoteConfig.getString('commission_is_percentage');
      if (commPercStr.isNotEmpty) {
        _commissionIsPercentage = commPercStr.toLowerCase() == 'true' || commPercStr == '1';
      }

      // GST
      final gstStr = remoteConfig.getString('gst_rate');
      if (gstStr.isNotEmpty) {
        final parsed = double.tryParse(gstStr);
        if (parsed != null) _gstRate = parsed;
      }

      final gstPercStr = remoteConfig.getString('gst_is_percentage');
      if (gstPercStr.isNotEmpty) {
        _gstIsPercentage = gstPercStr.toLowerCase() == 'true' || gstPercStr == '1';
      }

      final gstEnabledStr = remoteConfig.getString('is_gst_enabled');
      if (gstEnabledStr.isNotEmpty) {
        final isEnabled = gstEnabledStr.toLowerCase() == 'true' || gstEnabledStr == '1';
        _gstIsFree = !isEnabled;
      } else {
        final gstFreeStr = remoteConfig.getString('gst_is_free');
        if (gstFreeStr.isNotEmpty) {
          _gstIsFree = gstFreeStr.toLowerCase() == 'true' || gstFreeStr == '1';
        }
      }

      // Maintenance
      final maintStr = remoteConfig.getString('user_app_maintenance');
      if (maintStr.isNotEmpty) {
        _isMaintenanceMode = maintStr.toLowerCase() == 'true' || maintStr == '1';
      }

      // Versions & URLs
      final androidVer = remoteConfig.getString('user_android_min_version');
      if (androidVer.isNotEmpty) _requiredVersionAndroid = androidVer;

      final iosVer = remoteConfig.getString('user_ios_min_version');
      if (iosVer.isNotEmpty) _requiredVersionIos = iosVer;

      final androidUrl = remoteConfig.getString('user_android_store_url');
      if (androidUrl.isNotEmpty) _updateUrlAndroid = androidUrl;

      final iosUrl = remoteConfig.getString('user_ios_store_url');
      if (iosUrl.isNotEmpty) _updateUrlIos = iosUrl;

      debugPrint('🔥 REMOTE CONFIG LOADED FROM FIREBASE: platformFee=$_platformFee, isFree=$_isConvenienceFeeFree, commission=$_commissionRate ($_commissionIsPercentage%), gst=$_gstRate');
    } catch (e) {
      debugPrint('⚠️ Error reading Firebase Remote Config: $e');
    }
  }

  Future<void> fetchAndActivate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();
      _readFromFirebase(remoteConfig);
    } catch (e) {
      debugPrint('⚠️ Error fetching Firebase Remote Config: $e');
    }

    // Optional Supabase fallback (failsafe, never overrides non-zero remote config with empty)
    try {
      final rows = await Supabase.instance.client.from('app_config').select('key, value');
      for (final row in rows as List<dynamic>) {
        final key = row['key']?.toString();
        final val = row['value']?.toString() ?? '';
        switch (key) {
          case 'platform_fee':
            final parsedFee = double.tryParse(val);
            if (parsedFee != null && parsedFee > 0) _platformFee = parsedFee;
            break;
          case 'commission_rate':
            final parsedComm = double.tryParse(val);
            if (parsedComm != null && parsedComm > 0) _commissionRate = parsedComm;
            break;
          case 'commission_is_percentage':
            if (val.isNotEmpty) _commissionIsPercentage = val == 'true' || val == '1';
            break;
          case 'convenience_fee':
            final parsedFee = double.tryParse(val);
            if (parsedFee != null && parsedFee > 0) _convenienceFee = parsedFee;
            break;
          case 'convenience_fee_is_free':
          case 'platform_fee_is_free':
            if (val.isNotEmpty) _isConvenienceFeeFree = val == 'true' || val == '1';
            break;
          case 'gst_rate':
            final parsedGst = double.tryParse(val);
            if (parsedGst != null) _gstRate = parsedGst;
            break;
          case 'gst_is_percentage':
            if (val.isNotEmpty) _gstIsPercentage = val == 'true' || val == '1';
            break;
          case 'gst_is_free':
            if (val.isNotEmpty) _gstIsFree = val == 'true' || val == '1';
            break;
          case 'user_app_maintenance':
            if (val.isNotEmpty) _isMaintenanceMode = val == 'true' || val == '1';
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
    } catch (_) {}

    _maintenanceController.add(isMaintenanceMode);
    _configUpdateController.add(null);
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