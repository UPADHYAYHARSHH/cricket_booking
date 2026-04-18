import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repositories.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;

  AuthRepositoryImpl(this.supabase);

  // @override
  // Future<void> loginWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   try {
  //     print("Calling Supabase login...");

  //     final response = await supabase.auth.signInWithPassword(
  //       email: email,
  //       password: password,
  //     );

  //     print("Supabase response: ${response.user}");

  //     if (response.user == null) {
  //       throw const AuthException('Login failed - user null');
  //     }
  //   } on AuthException catch (e) {
  //     // 🔥 Supabase specific error
  //     print("SUPABASE AUTH ERROR:");
  //     print("Message: ${e.message}");
  //     print("StatusCode: ${e.statusCode}");
  //     rethrow;
  //   } catch (e, st) {
  //     // 🔥 Network / CORS / unknown error
  //     print("GENERAL ERROR:");
  //     print(e);
  //     print("STACK TRACE:");
  //     print(st);

  //     rethrow;
  //   }
  // }

  // @override
  // Future<void> signUpWithEmail({
  //   required String email,
  //   required String password,
  // }) async {
  //   final response = await supabase.auth.signUp(
  //     email: email,
  //     password: password,
  //   );

  //   if (response.user == null) {
  //     throw const AuthException('Signup failed');
  //   }
  // }

  @override
  Future<void> signInWithPhone(String phone) async {
    await supabase.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<void> verifyPhoneOtp({required String phone, required String token}) async {
    final response = await supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    
    if (response.user == null) {
      throw const AuthException('Invalid or expired OTP');
    }
  }

  // @override
  // Future<void> sendPasswordResetEmail(String email) async {
  //   await supabase.auth.resetPasswordForEmail(email);
  // }

  // @override
  // Future<void> verifyPasswordResetOtp(String email, String token) async {
  //   final response = await supabase.auth.verifyOTP(
  //     email: email,
  //     token: token,
  //     type: OtpType.recovery,
  //   );
  //   
  //   if (response.user == null) {
  //     throw const AuthException('Invalid or expired OTP');
  //   }
  // }

  // @override
  // Future<void> updatePassword(String newPassword) async {
  //   final response = await supabase.auth.updateUser(
  //     UserAttributes(password: newPassword),
  //   );
  //   
  //   if (response.user == null) {
  //     throw const AuthException('Failed to update password');
  //   }
  // }

  @override
  Future<void> logout() async {
    await supabase.auth.signOut();
  }
}
