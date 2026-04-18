abstract class AuthRepository {
  // Future<void> loginWithEmail({
  //   required String email,
  //   required String password,
  // });

  // Future<void> signUpWithEmail({
  //   required String email,
  //   required String password,
  // });

  Future<void> signInWithPhone(String phone);
  Future<void> verifyPhoneOtp({required String phone, required String token});

  // Future<void> sendPasswordResetEmail(String email);
  // Future<void> verifyPasswordResetOtp(String email, String token);
  // Future<void> updatePassword(String newPassword);

  Future<void> logout();
}
