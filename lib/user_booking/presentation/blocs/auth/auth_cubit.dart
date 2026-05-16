import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:turfpro/common/services/notification_service.dart';
import '../../../domain/repositories/auth_repositories.dart';
import '../../../data/repositories/user_repository_impl.dart';
import 'package:turfpro/user_booking/presentation/blocs/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  StreamSubscription<fb.User?>? _authSubscription;

  AuthCubit(this.repository) : super(AuthInitial()) {
    _authSubscription = fb.FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint("DEBUG: [AuthCubit] Firebase Auth state change. User: ${user?.uid}, Verified: ${user?.emailVerified}");
      
      if (user != null && user.emailVerified) {
        debugPrint("DEBUG: [AuthCubit] User verified - emitting AuthVerified");
        emit(AuthVerified());
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
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "Invalid email or password.";
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
      
      // Use Supabase client for database query but with Firebase UID
      try {
        final userData = await sb.Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', user.uid)
            .maybeSingle();
            
        if (userData == null) {
          debugPrint("DEBUG: [AuthCubit] No record found for ID: ${user.uid}. Redirecting to complete profile.");
          emit(AuthProfileIncomplete());
        } else if (userData['name'] == null || (userData['name'] as String).isEmpty) {
          debugPrint("DEBUG: [AuthCubit] Profile record exists but name is missing.");
          emit(AuthProfileIncomplete());
        } else {
          debugPrint("DEBUG: [AuthCubit] Profile complete");
          await NotificationService.initialize();
          emit(AuthSuccess());
        }
      } catch (e) {
        debugPrint("DEBUG: [AuthCubit] Error checking profile: $e");
        if (e.toString().contains('22P02') || e.toString().contains('uuid')) {
          emit(AuthError("Database Schema Error: The Supabase 'users' table 'id' column must be changed from 'uuid' to 'text' to support Firebase UIDs."));
        } else {
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
      emit(AuthError("Failed to complete profile: ${e.toString()}"));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthInitial());
  }
}
