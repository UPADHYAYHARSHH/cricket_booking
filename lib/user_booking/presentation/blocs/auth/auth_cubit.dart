import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:turfpro/common/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/repositories/auth_repositories.dart';
import '../../../data/repositories/user_repository_impl.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  StreamSubscription<fb.User?>? _authSubscription;

  AuthCubit(this.repository) : super(AuthInitial()) {
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen((user) async {
      debugPrint("DEBUG: [AuthCubit] Firebase Auth state change. User: ${user?.uid}");
      
      if (user != null) {
        debugPrint("DEBUG: [AuthCubit] User verified - emitting AuthVerified and checking profile");
        emit(AuthVerified());
        await _checkProfileAndEmit();
      } else {
        debugPrint("DEBUG: [AuthCubit] No user - emitting AuthInitial");
        emit(AuthInitial());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      await repository.loginWithEmail(
        email: email,
        password: password,
      );

      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        emit(AuthEmailOtpRequired(email)); // Reusing state for "Waiting Verification"
        return;
      }

      await _checkProfileAndEmit();
    } on fb.FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? "Authentication failed";
      if (e.code == 'user-not-found') {
        errorMessage = "User is not registered. Please sign up.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password.";
      } else if (e.code == 'invalid-credential') {
        // Fallback for Firebase versions with email enumeration protection enabled
        errorMessage = "Incorrect password or user not registered.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      await repository.signUpWithEmail(
        email: email,
        password: password,
      );

      // Signup successful, now wait for email verification
      emit(AuthEmailOtpRequired(email));
    } on fb.FirebaseAuthException catch (e) {
      String errorMessage = e.message ?? "Registration failed";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already in use. Try logging in instead.";
      }
      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await repository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetEmailSent(email));
    } on fb.FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "Failed to send reset email"));
    } catch (e) {
      emit(AuthError('Failed to send reset email: ${e.toString()}'));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await repository.updatePassword(newPassword);
      await _checkProfileAndEmit();
    } on fb.FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "Failed to update password"));
    } catch (e) {
      emit(AuthError('Failed to update password: ${e.toString()}'));
    }
  }

  Future<void> _checkProfileAndEmit() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint("DEBUG: [AuthCubit] Checking profile for Firebase user: ${user.uid}");
      
      try {
        // Fetch user data via RPC to bypass RLS issues completely
        final userData = await sb.Supabase.instance.client
            .rpc('get_user_profile', params: {'p_id': user.uid});
            
        if (userData == null) {
          debugPrint("DEBUG: [AuthCubit] No record found for ID: ${user.uid}. Redirecting to complete profile.");
          emit(AuthProfileIncomplete());
        } else {
          debugPrint("DEBUG: [AuthCubit] RPC get_user_profile returned: $userData");
          
          final name = userData['name'] as String?;
          final gender = userData['gender'] as String?;
          final dob = userData['dob'] as String?;
          
          debugPrint("DEBUG: [AuthCubit] Parsed fields - name: '$name', gender: '$gender', dob: '$dob'");
          
          if (name == null || name.trim().isEmpty ||
              gender == null || gender.trim().isEmpty ||
              dob == null || dob.trim().isEmpty) {
            debugPrint("DEBUG: [AuthCubit] Profile record exists but required fields are missing.");
            emit(AuthProfileIncomplete());
          } else {
            debugPrint("DEBUG: [AuthCubit] Profile complete");
            await NotificationService.initialize();
            emit(AuthSuccess());
          }
        }
      } catch (e) {
        debugPrint("DEBUG: [AuthCubit] Error checking profile: $e");
        if (e.toString().contains('22P02') || e.toString().contains('uuid')) {
          emit(AuthError("Database Schema Error: The Supabase 'users' table 'id' column must be changed from 'uuid' to 'text' to support Firebase UIDs."));
        } else {
          // If we fail due to network or RLS, but we have a valid firebase user,
          // we could potentially fallback, but without local cache we must show error
          emit(AuthError("Failed to fetch user profile: ${e.toString()}"));
        }
      }
    } else {
      emit(AuthError("No user signed in"));
    }
  }

  /// Manually trigger a session check (useful for Web cross-tab sync or polling)
  Future<void> checkSession() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Refresh the user data from Firebase
      final updatedUser = fb.FirebaseAuth.instance.currentUser;
      if (updatedUser != null && updatedUser.emailVerified) {
        debugPrint("DEBUG: [AuthCubit] User verified after reload.");
        emit(AuthVerified());
      } else {
        debugPrint("DEBUG: [AuthCubit] User still not verified.");
      }
    }
  }

  Future<void> completeProfile({
    required String name,
    required String gender,
    required DateTime dob,
    required UserRepository userRepository,
  }) async {
    emit(AuthLoading());
    try {
      await userRepository.upsertUser(
        name: name,
        gender: gender,
        dob: dob,
      );

      await NotificationService.initialize();
      emit(AuthSuccess());
    } catch (e) {
      debugPrint("DEBUG: [AuthCubit] completeProfile error: ${e.toString()}");
      emit(AuthError("Failed to complete profile: ${e.toString()}"));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthInitial());
  }
}
