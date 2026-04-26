import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../domain/repositories/auth_repositories.dart';
import '../../../data/repositories/user_repository_impl.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

  // Future<void> loginWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   emit(AuthLoading());

  //   try {
  //     await repository.loginWithEmail(
  //       email: email,
  //       password: password,
  //     );

  //     emit(AuthSuccess());
  //   } on AuthException catch (e) {
  //     String errorMessage = e.message;

  //     // SPECIFIC VALIDATION: User not found
  //     if (e.message.toLowerCase().contains("invalid login credentials")) {
  //       errorMessage = "No account found with this email, or password incorrect.";
  //     }

  //     emit(AuthError(errorMessage));
  //   } catch (e) {
  //     emit(AuthError(e.toString()));
  //   }
  // }

  // Future<void> signUpWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   emit(AuthLoading());

  //   try {
  //     await repository.signUpWithEmail(
  //       email: email,
  //       password: password,
  //     );

  //     // Signup successful, now need OTP verification
  //     emit(AuthOtpRequired(email));
  //   } on AuthException catch (e) {
  //     String errorMessage = e.message;

  //     // SPECIFIC VALIDATION: User already exists
  //     if (e.message.toLowerCase().contains("already registered") || 
  //         e.message.toLowerCase().contains("user already exists")) {
  //       errorMessage = "This email is already in use. Try logging in instead.";
  //     }

  //     emit(AuthError(errorMessage));
  //   } catch (e) {
  //     emit(AuthError(e.toString()));
  //   }
  // }

  Future<void> signInWithPhone(String phone) async {
    debugPrint("DEBUG: [AuthCubit] signInWithPhone request for: $phone");
    emit(AuthLoading());
    try {
      await repository.signInWithPhone(phone);
      debugPrint("DEBUG: [AuthCubit] signInWithPhone success - emitting AuthOtpRequired");
      emit(AuthOtpRequired(phone));
    } on AuthException catch (e) {
      debugPrint("DEBUG: [AuthCubit] signInWithPhone AuthException: ${e.message}");
      emit(AuthError(e.message));
    } catch (e) {
      debugPrint("DEBUG: [AuthCubit] signInWithPhone unexpected error: $e");
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyPhoneOtp(String phone, String code) async {
    debugPrint("DEBUG: [AuthCubit] verifyPhoneOtp request for: $phone with code: $code");
    emit(AuthLoading());
    try {
      await repository.verifyPhoneOtp(phone: phone, token: code);
      debugPrint("DEBUG: [AuthCubit] verifyPhoneOtp success - checking profile completion");
      
      // Post-verification check: Is profile complete?
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        debugPrint("DEBUG: [AuthCubit] Logged in user: ${user.id}");
        final userData = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();
            
        if (userData == null || userData['name'] == null || (userData['name'] as String).isEmpty) {
          debugPrint("DEBUG: [AuthCubit] Profile incomplete - emitting AuthProfileIncomplete");
          emit(AuthProfileIncomplete());
        } else {
          debugPrint("DEBUG: [AuthCubit] Profile complete - emitting AuthSuccess");
          emit(AuthSuccess());
        }
      } else {
        debugPrint("DEBUG: [AuthCubit] User is null after verification");
        emit(AuthError("Authentication failed"));
      }
    } on AuthException catch (e) {
      debugPrint("DEBUG: [AuthCubit] verifyPhoneOtp AuthException: ${e.message}");
      
      String errorMessage = "Verification failed";
      if (e.message.toLowerCase().contains("expired")) {
        errorMessage = "OTP has expired. Please request a new one.";
      } else if (e.message.toLowerCase().contains("invalid")) {
        errorMessage = "Invalid OTP. Please check and try again.";
      } else {
        errorMessage = e.message;
      }
      
      emit(AuthError(errorMessage));
    } catch (e) {
      debugPrint("DEBUG: [AuthCubit] verifyPhoneOtp unexpected error: $e");
      emit(AuthError(e.toString()));
    }
  }

  // Future<void> sendPasswordResetEmail(String email) async {
  //   emit(AuthLoading());
  //   try {
  //     await repository.sendPasswordResetEmail(email);
  //     emit(AuthPasswordResetEmailSent(email));
  //   } on AuthException catch (e) {
  //     emit(AuthError(e.message));
  //   } catch (e) {
  //     emit(AuthError('Failed to send reset email: ${e.toString()}'));
  //   }
  // }

  // Future<void> verifyPasswordResetOtp(String email, String token) async {
  //   emit(AuthLoading());
  //   try {
  //     await repository.verifyPasswordResetOtp(email, token);
  //     emit(AuthPasswordResetOtpVerified());
  //   } on AuthException catch (e) {
  //     emit(AuthError(e.message));
  //   } catch (e) {
  //     emit(AuthError('Failed to verify OTP: ${e.toString()}'));
  //   }
  // }

  // Future<void> updatePassword(String newPassword) async {
  //   emit(AuthLoading());
  //   try {
  //     await repository.updatePassword(newPassword);
  //     emit(AuthPasswordUpdated());
  //   } on AuthException catch (e) {
  //     emit(AuthError(e.message));
  //   } catch (e) {
  //     emit(AuthError('Failed to update password: ${e.toString()}'));
  //   }
  // }

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
