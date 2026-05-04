import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro/common/services/notification_service.dart';
import 'package:turfpro/common/services/remote_config_service.dart';

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigateToLogin extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashUnderMaintenance extends SplashState {}

class SplashUpdateRequired extends SplashState {
  final String updateUrl;
  SplashUpdateRequired(this.updateUrl);
}

class SplashCubit extends Cubit<SplashState> {
  final RemoteConfigService _remoteConfigService = RemoteConfigService();

  SplashCubit() : super(SplashInitial());

  void checkStatus() async {
    // Initial delay for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. Check Maintenance Mode
    if (_remoteConfigService.isMaintenanceMode) {
      emit(SplashUnderMaintenance());
      return;
    }

    // 2. Check Force Update
    bool isUpdateRequired = await _remoteConfigService.isUpdateRequired();
    if (isUpdateRequired) {
      emit(SplashUpdateRequired(_remoteConfigService.updateUrl));
      return;
    }

    // 3. Check Auth as usual
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      NotificationService.initialize();
      emit(SplashNavigateToHome());
    } else {
      emit(SplashNavigateToLogin());
    }
  }
}
