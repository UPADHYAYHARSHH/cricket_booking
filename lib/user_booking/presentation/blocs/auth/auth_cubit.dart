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
      /// Supabase error handling
      if (e.message.contains("Invalid login credentials")) {
        /// AUTO SIGNUP
        try {
          await repository.signUpWithEmail(
            email: email,
            password: password,
          );
          emit(AuthSuccess());
        } catch (e) {
          print("Signup error: $e"); // 👈 ADD THIS
          emit(AuthError("Signup failed"));
        }
      } else {
        emit(AuthError(e.message));
      }
    } catch (e) {
      emit(AuthError("Something went wrong"));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthInitial());
  }
}
