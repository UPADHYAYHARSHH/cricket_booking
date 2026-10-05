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

  // Cancellation Policy & Coin Recovery (Loaded dynamically from app_config)
  double _cancellationTier1Hours = 24.0;
  double _cancellationTier1Percent = 100.0;
  double _cancellationTier2Hours = 12.0;
  double _cancellationTier2Percent = 75.0;
  double _cancellationTier3Hours = 3.0;
  double _cancellationTier3Percent = 50.0;
  double _cancellationTier4Percent = 25.0;
  int _coinExpiryDays = 60;
  bool _coinsExpiryEnabled = true;
  double _maxCoinRedemptionPercent = 40.0;

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
      }, onError: (error) {
        debugPrint('⚠️ FIREBASE REMOTE CONFIG STREAM ERROR (Handled): $error');
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

      // Cancellation & Coin Recovery
      final t1h = double.tryParse(remoteConfig.getString('cancellation_tier1_hours'));
      if (t1h != null) _cancellationTier1Hours = t1h;
      final t1p = double.tryParse(remoteConfig.getString('cancellation_tier1_percent'));
      if (t1p != null) _cancellationTier1Percent = t1p;

      final t2h = double.tryParse(remoteConfig.getString('cancellation_tier2_hours'));
      if (t2h != null) _cancellationTier2Hours = t2h;
      final t2p = double.tryParse(remoteConfig.getString('cancellation_tier2_percent'));
      if (t2p != null) _cancellationTier2Percent = t2p;

      final t3h = double.tryParse(remoteConfig.getString('cancellation_tier3_hours'));
      if (t3h != null) _cancellationTier3Hours = t3h;
      final t3p = double.tryParse(remoteConfig.getString('cancellation_tier3_percent'));
      if (t3p != null) _cancellationTier3Percent = t3p;

      final t4p = double.tryParse(remoteConfig.getString('cancellation_tier4_percent'));
      if (t4p != null) _cancellationTier4Percent = t4p;

      final exp = int.tryParse(remoteConfig.getString('coin_expiry_days'));
      if (exp != null) _coinExpiryDays = exp;

      final expEnabledStr = remoteConfig.getString('coins_expiry_enabled');
      if (expEnabledStr.isNotEmpty) {
        _coinsExpiryEnabled = expEnabledStr.toLowerCase() == 'true' || expEnabledStr == '1';
      }

      final maxRedeem = double.tryParse(remoteConfig.getString('max_coin_redemption_percent'));
      if (maxRedeem != null) _maxCoinRedemptionPercent = maxRedeem;

      debugPrint('🔥 REMOTE CONFIG LOADED FROM FIREBASE: platformFee=$_platformFee, isFree=$_isConvenienceFeeFree, commission=$_commissionRate ($_commissionIsPercentage%), gst=$_gstRate, cancellationTiers=[$_cancellationTier1Hours h -> $_cancellationTier1Percent%]');
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
          case 'cancellation_tier1_hours':
            final parsedT1h = double.tryParse(val);
            if (parsedT1h != null) _cancellationTier1Hours = parsedT1h;
            break;
          case 'cancellation_tier1_percent':
            final parsedT1p = double.tryParse(val);
            if (parsedT1p != null) _cancellationTier1Percent = parsedT1p;
            break;
          case 'cancellation_tier2_hours':
            final parsedT2h = double.tryParse(val);
            if (parsedT2h != null) _cancellationTier2Hours = parsedT2h;
            break;
          case 'cancellation_tier2_percent':
            final parsedT2p = double.tryParse(val);
            if (parsedT2p != null) _cancellationTier2Percent = parsedT2p;
            break;
          case 'cancellation_tier3_hours':
            final parsedT3h = double.tryParse(val);
            if (parsedT3h != null) _cancellationTier3Hours = parsedT3h;
            break;
          case 'cancellation_tier3_percent':
            final parsedT3p = double.tryParse(val);
            if (parsedT3p != null) _cancellationTier3Percent = parsedT3p;
            break;
          case 'cancellation_tier4_percent':
            final parsedT4p = double.tryParse(val);
            if (parsedT4p != null) _cancellationTier4Percent = parsedT4p;
            break;
          case 'coin_expiry_days':
            final parsedExp = int.tryParse(val);
            if (parsedExp != null) _coinExpiryDays = parsedExp;
            break;
          case 'coins_expiry_enabled':
            if (val.isNotEmpty) _coinsExpiryEnabled = val == 'true' || val == '1';
            break;
          case 'max_coin_redemption_percent':
            final parsedMaxRedeem = double.tryParse(val);
            if (parsedMaxRedeem != null) _maxCoinRedemptionPercent = parsedMaxRedeem;
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

  // Cancellation & Coin Recovery Getters
  double get cancellationTier1Hours => _cancellationTier1Hours;
  double get cancellationTier1Percent => _cancellationTier1Percent;
  double get cancellationTier2Hours => _cancellationTier2Hours;
  double get cancellationTier2Percent => _cancellationTier2Percent;
  double get cancellationTier3Hours => _cancellationTier3Hours;
  double get cancellationTier3Percent => _cancellationTier3Percent;
  double get cancellationTier4Percent => _cancellationTier4Percent;
  int get coinExpiryDays => _coinExpiryDays;
  bool get coinsExpiryEnabled => _coinsExpiryEnabled;
  double get maxCoinRedemptionPercent => _maxCoinRedemptionPercent;

  /// Dynamic live quote calculation based on the admin's configured policy
  CancellationQuote getCancellationQuote({
    required DateTime slotTime,
    required double eligibleAmount,
  }) {
    final now = DateTime.now();
    final diff = slotTime.toLocal().difference(now);
    final hoursRemaining = diff.inSeconds / 3600.0;

    double refundPercent;
    String tierName;

    if (hoursRemaining >= _cancellationTier1Hours) {
      refundPercent = _cancellationTier1Percent;
      tierName = 'More than ${_cancellationTier1Hours.toInt()}h prior';
    } else if (hoursRemaining >= _cancellationTier2Hours) {
      refundPercent = _cancellationTier2Percent;
      tierName = '${_cancellationTier2Hours.toInt()}–${_cancellationTier1Hours.toInt()}h prior';
    } else if (hoursRemaining >= _cancellationTier3Hours) {
      refundPercent = _cancellationTier3Percent;
      tierName = '${_cancellationTier3Hours.toInt()}–${_cancellationTier2Hours.toInt()}h prior';
    } else if (hoursRemaining > 0) {
      refundPercent = _cancellationTier4Percent;
      tierName = 'Less than ${_cancellationTier3Hours.toInt()}h prior';
    } else {
      refundPercent = 0.0;
      tierName = 'Slot already started';
    }

    final coinsToReceive = (eligibleAmount * (refundPercent / 100.0)).clamp(0.0, eligibleAmount);

    return CancellationQuote(
      hoursRemaining: hoursRemaining,
      tierName: tierName,
      refundPercent: refundPercent,
      eligibleAmount: eligibleAmount,
      coinsToReceive: coinsToReceive,
      coinExpiryDays: _coinExpiryDays,
      coinsExpiryEnabled: _coinsExpiryEnabled,
    );
  }

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

class CancellationQuote {
  final double hoursRemaining;
  final String tierName;
  final double refundPercent;
  final double eligibleAmount;
  final double coinsToReceive;
  final int coinExpiryDays;
  final bool coinsExpiryEnabled;

  const CancellationQuote({
    required this.hoursRemaining,
    required this.tierName,
    required this.refundPercent,
    required this.eligibleAmount,
    required this.coinsToReceive,
    required this.coinExpiryDays,
    required this.coinsExpiryEnabled,
  });
}