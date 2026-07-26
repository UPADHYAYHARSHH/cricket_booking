import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro/common/services/notification_service.dart';
import 'package:turfpro/common/services/remote_config_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigateToLogin extends SplashState {}

class SplashNavigateToHome extends SplashState {}

class SplashUnderMaintenance extends SplashState {}

class SplashUpdateRequired extends SplashState {
  final String updateUrl;
  SplashUpdateRequired(this.updateUrl);
}

class SplashNavigateToCompleteProfile extends SplashState {}

class SplashCubit extends Cubit<SplashState> {
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  StreamSubscription<User?>? _authSubscription;

  SplashCubit() : super(SplashInitial()) {
    debugPrint("DEBUG: [SplashCubit] Initialized.");
  }

  @override
  Future<void> close() {
    debugPrint("DEBUG: [SplashCubit] Closing.");
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

    // 3. Check Auth & Profile
    final user = FirebaseAuth.instance.currentUser;
    debugPrint("DEBUG: [SplashCubit] Final check: User: ${user?.uid}, Verified: ${user?.emailVerified}");
    
    if (user != null) {
      try {
        // Fetch user data via RPC to bypass RLS issues completely
        final userData = await sb.Supabase.instance.client
            .rpc('get_user_profile', params: {'p_id': user.uid});
            
        if (userData == null) {
          debugPrint("DEBUG: [SplashCubit] No record found for ID: ${user.uid}. Redirecting to complete profile.");
          emit(SplashNavigateToCompleteProfile());
        } else {
          debugPrint("DEBUG: [SplashCubit] RPC get_user_profile returned: $userData");
          
          final name = userData['name'] as String?;
          final gender = userData['gender'] as String?;
          final dob = userData['dob'] as String?;
          
          debugPrint("DEBUG: [SplashCubit] Parsed fields - name: '$name', gender: '$gender', dob: '$dob'");
          
          if (name == null || name.trim().isEmpty ||
              gender == null || gender.trim().isEmpty ||
              dob == null || dob.trim().isEmpty) {
            debugPrint("DEBUG: [SplashCubit] Profile record exists but required fields are missing.");
            emit(SplashNavigateToCompleteProfile());
          } else {
            debugPrint("DEBUG: [SplashCubit] Profile complete. Navigating to Home.");
            NotificationService.initialize();
            emit(SplashNavigateToHome());
          }
        }
      } catch (e) {
        debugPrint("DEBUG: [SplashCubit] Error checking profile: $e");
        // Fallback to complete profile if we cannot verify DB (prevent incomplete users from entering app)
        emit(SplashNavigateToCompleteProfile());
      }
    } else {
      debugPrint("DEBUG: [SplashCubit] No verified user found. Navigating to Login.");
      emit(SplashNavigateToLogin());
    }
  }
}
