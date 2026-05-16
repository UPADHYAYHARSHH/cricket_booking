import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  StreamSubscription<User?>? _authSubscription;

  SplashCubit() : super(SplashInitial()) {
    debugPrint("DEBUG: [SplashCubit] Initialized. Starting Firebase auth listener.");
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint("DEBUG: [SplashCubit] Firebase Auth User: ${user?.uid}, Verified: ${user?.emailVerified}");
      
      if (user != null && user.emailVerified) {
        debugPrint("DEBUG: [SplashCubit] User verified! Navigating to Home.");
        emit(SplashNavigateToHome());
      }
    });
  }

  @override
  Future<void> close() {
    debugPrint("DEBUG: [SplashCubit] Closing. Cancelling auth listener.");
    _authSubscription?.cancel();
    return super.close();
  }

  void checkStatus() async {
    debugPrint("DEBUG: [SplashCubit] checkStatus called.");
    
    // Initial delay for splash animation
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. Check Maintenance Mode
    if (_remoteConfigService.isMaintenanceMode) {
      debugPrint("DEBUG: [SplashCubit] Maintenance mode active.");
      emit(SplashUnderMaintenance());
      return;
    }

    // 2. Check Force Update
    bool isUpdateRequired = await _remoteConfigService.isUpdateRequired();
    if (isUpdateRequired) {
      debugPrint("DEBUG: [SplashCubit] Force update required.");
      emit(SplashUpdateRequired(_remoteConfigService.updateUrl));
      return;
    }

    // 3. Check Auth
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("DEBUG: [SplashCubit] Final check: User: ${user?.uid}, Verified: ${user?.emailVerified}");
    
    if (user != null && user.emailVerified) {
      NotificationService.initialize();
      emit(SplashNavigateToHome());
    } else {
      debugPrint("DEBUG: [SplashCubit] No verified user found. Navigating to Login.");
      emit(SplashNavigateToLogin());
    }
  }
}
