import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../domain/repositories/auth_repositories.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

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

      emit(AuthSuccess());
    } on AuthException catch (e) {
      String errorMessage = e.message;

      // SPECIFIC VALIDATION: User not found
      if (e.message.toLowerCase().contains("invalid login credentials")) {
        errorMessage = "No account found with this email, or password incorrect.";
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

      // Signup successful, now need OTP verification
      emit(AuthOtpRequired(email));
    } on AuthException catch (e) {
      String errorMessage = e.message;

      // SPECIFIC VALIDATION: User already exists
      if (e.message.toLowerCase().contains("already registered") || 
          e.message.toLowerCase().contains("user already exists")) {
        errorMessage = "This email is already in use. Try logging in instead.";
      }

      emit(AuthError(errorMessage));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp(String email, String code) async {
    emit(AuthLoading());

    // STATIC OTP CHECK: 1111
    if (code == "1111") {
      emit(AuthSuccess());
    } else {
      emit(AuthError("Invalid verification code. Please try again."));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await repository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetEmailSent(email));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Failed to send reset email: ${e.toString()}'));
    }
  }

  Future<void> verifyPasswordResetOtp(String email, String token) async {
    emit(AuthLoading());
    try {
      await repository.verifyPasswordResetOtp(email, token);
      emit(AuthPasswordResetOtpVerified());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Failed to verify OTP: ${e.toString()}'));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    emit(AuthLoading());
    try {
      await repository.updatePassword(newPassword);
      emit(AuthPasswordUpdated());
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError('Failed to update password: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthInitial());
  }
}
